local byte_A = string.byte("A")
local byte_Z = string.byte("Z")
local byte_a = string.byte("a")
local byte_z = string.byte("z")
local byte_0 = string.byte("0")
local byte_9 = string.byte("9")
local byte_62 = string.byte("+")
local byte_63 = string.byte("/")

function base64_decode(str, byteCallback)
  local stringLength = string.len(str)
  local bits = 0
  local bitCount = 0
  -- For each byte in string
  for i = 1,stringLength do
    local strByte = string.byte(str, i)
    local b64Digit = -1
    -- Determine its digit value in base64
    if (strByte == byte_62) then
      b64Digit = 62
    elseif (strByte == byte_63) then
      b64Digit = 63
    elseif (strByte >= byte_A and strByte <= byte_Z) then
      b64Digit = strByte - byte_A
    elseif (strByte >= byte_a and strByte <= byte_z) then
      b64Digit = strByte - byte_a + 26
    elseif (strByte >= byte_0 and strByte <= byte_9) then
      b64Digit = strByte - byte_0 + 52
    end
    -- If it's a valid digit, shift it onto the output
    if (b64Digit >= 0) then
      bits = bit32.lshift(bits, 6)
      bits = bit32.bor(bits, b64Digit)
      bitCount = bitCount + 6
      -- If there are enough bits for a byte, shift it out
      if (bitCount >= 8) then
        bitCount = bitCount - 8
        local byteVal = bit32.rshift(bits, bitCount)
        bits = bit32.band(bits, bit32.lshift(1, bitCount) - 1)
        byteCallback(byteVal)
      end
    end
  end
end

local args = {...}
local filename = args[1]
if (filename == nil or filename == "") then
  print("writetape (<side>) <file>")
  return
end
local selectSide = nil
if (#args >= 2) then
  selectSide = args[1]
  filename = args[2]
end
if (selectSide == nil) then
  local periphList = peripheral.getNames()
  local tapeList = {}
  for k,v in pairs(periphList) do
    if (peripheral.getType(v) == "tape_drive") then
      table.insert(tapeList, v)
    end
  end
  if (#tapeList == 0) then
    error("No tape-drive attached")
  end
  if (#tapeList == 1) then
    selectSide = tapeList[1]
  else
    print(table.concat(tapeList, ","))
    print("Select side:")
    selectSide = read()
  end
end

if (peripheral.getType(selectSide) ~= "tape_drive") then
  error("Invalid side")
end
local tape = peripheral.wrap(selectSide)
if (not tape.isReady()) then
  error("No tape inserted")
end

local file = nil
local fileIsHTTP = false
if (string.find(filename, "://")) then
  fileIsHTTP = true
  print("Requesting...")
  file = http.get(filename)
else
  file = fs.open(filename, "r")
end
if (not file) then
  error("Unable to open " .. filename)
end

if (fileIsHTTP) then
  local responseCode = file.getResponseCode()
  if (responseCode >= 400 and responseCode <= 600) then
    file.close()
    error("HTTP error: " .. responseCode)
  end
end

local ctr = 0
local byteCount = 0
base64_decode(file.readAll(), function(byteVal)
  tape.write(byteVal)
  ctr = ctr + 1
  if (ctr >= 65536) then
    byteCount = byteCount + 65536
    ctr = 0
    sleep(0.1)
    print("Written ", byteCount, " bytes")
  end
end)
file.close()
