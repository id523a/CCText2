local arguments = {...}
local FILE_URL = arguments[1]
if not FILE_URL then
    print("stream <URL>")
    return
end

local PLAYBACK_CHUNK = 8 * 1024
local DOWNLOAD_CHUNK = 32 * PLAYBACK_CHUNK
local MIN_DOWNLOAD = 24 * PLAYBACK_CHUNK

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

    return resp, nil
end

local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
if not speaker then
    error("No speaker peripheral found!", 0)
end

local fileLength = nil
local playbackCursor = 0
local downloadCursor = 0
local chunkQueue = {}

local decoder = nil
local shouldResetDecoder = true

local function downloader()
    local offset = 0

    while true do
        -- Wait until there is something to download
        while (downloadCursor - playbackCursor > MIN_DOWNLOAD) or (fileLength ~= nil and downloadCursor >= fileLength) do
            os.pullEvent("wake_downloader")
        end

        -- Download a DOWNLOAD_CHUNK
        local rangeEnd = downloadCursor + DOWNLOAD_CHUNK - 1
        if fileLength ~= nil then
            rangeEnd = math.min(rangeEnd, fileLength - 1)
        end

        local resp, err = fetchRange(FILE_URL, downloadCursor, rangeEnd)
        if not resp then
            error("Download failed at byte " .. downloadCursor .. ": " .. err, 0)
        end

        if fileLength == nil then
            -- Try to get file length out of response headers
            local headers = resp.getResponseHeaders()
            local contentRange = headers["Content-Range"]
            if contentRange then
                local total = string.match(contentRange, "/%s*(%d+)$")
                if total ~= nil then
                    fileLength = tonumber(total)
                end
            end
        end

        local body = resp.readAll()
        resp.close()
        if not body then
            error("Download failed at byte " .. downloadCursor .. ": error reading response body", 0)
        end

        -- Break into PLAYBACK_CHUNKs
        local splitStart = 1
        while splitStart <= #body do
            local splitEnd = math.min(splitStart + PLAYBACK_CHUNK - 1, #body)
            local subChunk = string.sub(body, splitStart, splitEnd)
            table.insert(chunkQueue, subChunk)
            downloadCursor = downloadCursor + splitEnd + 1 - splitStart
            splitStart = splitEnd + 1
        end
        os.queueEvent("wake_player")
    end
end

local function player()
    while true do
        -- Wait until there is something to play
        while #chunkQueue == 0 do
            os.pullEvent("wake_player")
        end

        -- Dequeue the next chunk
        local chunk = table.remove(chunkQueue, 1)
        playbackCursor = playbackCursor + #chunk;
        os.queueEvent("wake_downloader")

        -- Decode and play
        if shouldResetDecoder then
            decoder = dfpwm.make_decoder()
            shouldResetDecoder = false
        end
        local decoded = decoder(chunk)
        while not speaker.playAudio(decoded) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

local function bytesToTime(byteOffset)
    -- Convert DFPWM byte offsets to minutes and seconds.
    local bytesPerSecond = 6000 -- DFPWM is 48 kilobits per second
    local totalSeconds = math.floor(byteOffset / bytesPerSecond)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

local function drawUI(termWidth, termHeight)
    local termWidth, termHeight = term.getSize()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.clearLine()
    term.write(bytesToTime(playbackCursor))
    if fileLength ~= nil then
        term.write(" / ")
        term.write(bytesToTime(fileLength))
        local playbackPos = math.floor(0.5 + termWidth * playbackCursor / fileLength)
        local downloadPos = math.floor(0.5 + termWidth * downloadCursor / fileLength)
        term.setCursorPos(1, 2)
        term.setBackgroundColor(colors.gray)
        term.clearLine()
        term.setBackgroundColor(colors.lightBlue)
        term.write(string.rep(" ", playbackPos))
        term.setBackgroundColor(colors.blue)
        term.write(string.rep(" ", downloadPos - playbackPos))
    end
end

local function userInterface()
    local termWidth, termHeight = term.getSize()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    drawUI()
    while true do
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        if event == "wake_downloader" or event == "wake_player" then
            drawUI()
        elseif event == "mouse_click" then
            local button = eventData[2]
            local mouseX = eventData[3]
            local mouseY = eventData[4]
            if fileLength ~= nil and button == 1 and mouseY == 2 then
                local seekPoint = (mouseX - 1) * fileLength / termWidth
                playbackCursor = seekPoint
                downloadCursor = seekPoint
                chunkQueue = {}
                shouldResetDecoder = true
                os.queueEvent("wake_downloader")
            end
            drawUI()
        end
    end
end

parallel.waitForAll(downloader, player, userInterface)
