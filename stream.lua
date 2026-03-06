local arguments = {...}
local FILE_URL = arguments[1]
local START_OFFSET = (arguments[2] or 0) * 48000 / 8
if not FILE_URL then
    print("stream <URL> <seconds>")
    return
end

local DOWNLOAD_CHUNK = 128 * 1024
local PLAYBACK_CHUNK = 8 * 1024

local function fetchRange(url, startByte, endByte)
    local headers = {
        ["Range"] = string.format("bytes=%d-%d", startByte, endByte),
    }
    local resp, errMsg = http.get(url, headers, true)
    if not resp then
        return nil, errMsg or "http.get failed"
    end
    local respCode = resp.getResponseCode()
    if respCode ~= 206 then
        resp.close()
        return nil, string.format("unexpected HTTP code %d", respCode)
    end
    
    local body = resp.readAll()
    resp.close()
    if body == nil then
        return nil, "error reading response body"
    end
    return body, nil
end

local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
if not speaker then
    error("No speaker peripheral found!", 0)
end

local decoder = dfpwm.make_decoder()
local queuedChunk = nil
local downloadDone = false

local function downloader()
    local offset = START_OFFSET

    while true do
        -- If the queue is full, wait until the player signals a dequeue
        while queuedChunk ~= nil do
            os.pullEvent("chunk_dequeued")
        end

        local body, err = fetchRange(FILE_URL, offset, offset + DOWNLOAD_CHUNK - 1)
        if not body then
            error("Download failed at byte " .. offset .. ": " .. err, 0)
        end
        queuedChunk = body
        offset = offset + #body
        os.queueEvent("chunk_enqueued")

        -- A short read means we've reached the end of the stream
        if #body < DOWNLOAD_CHUNK then
            break
        end
    end

    downloadDone = true
    os.queueEvent("chunk_enqueued")  -- Wake the player if it's waiting on the final chunk
end

local function player()
    while true do
        -- Wait until a chunk is available
        while queuedChunk == nil do
            if downloadDone then return end
            os.pullEvent("chunk_enqueued")
        end

        -- Dequeue the next chunk
        local chunk = queuedChunk
        queuedChunk = nil
        os.queueEvent("chunk_dequeued")

        -- Break into sub-chunks, decode, and play
        local chunkOffset = 1
        while chunkOffset <= #chunk do
            local subEnd = math.min(chunkOffset + PLAYBACK_CHUNK - 1, #chunk)
            local subChunk = string.sub(chunk, chunkOffset, subEnd)

            local decoded = decoder(subChunk)

            while not speaker.playAudio(decoded) do
                os.pullEvent("speaker_audio_empty")
            end

            chunkOffset = subEnd + 1
        end
    end
end

parallel.waitForAll(downloader, player)
