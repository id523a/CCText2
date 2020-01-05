if (peripheral.getType("top") ~= "tape_drive") then
  print("Master (top) tape drive not present")
  return
end
if (peripheral.getType("left") ~= "tape_drive") then
  print("Destination (left) tape drive not present")
  return
end
local masterTape = peripheral.wrap("top")
local destTape = peripheral.wrap("left")
if (not masterTape.isReady()) then
  print("Master tape not inserted")
  return
end
if (not destTape.isReady()) then
  print("Destination tape not inserted")
  return
end
if not (destTape.getLabel() == nil
  or destTape.getLabel() == "") then
  print("Destination tape is labelled, likely not blank")
  return
end
local size = masterTape.getSize()
if (size > destTape.getSize()) then
  print("Destination is too small")
  return
end
masterTape.seek(-size)
destTape.seek(-destTape.getSize())
local chunkSize = 4096 * 15
local chunks = size / chunkSize
for i = 1,chunks,1 do
  for j = 1,chunkSize,1 do
    destTape.write(masterTape.read())
  end
  print(math.floor(100 * i / chunks), "%; ", i * chunkSize, " bytes")
  os.sleep(0.1)
end
destTape.setLabel(masterTape.getLabel())
masterTape.seek(-size)
destTape.seek(-destTape.getSize())
print("Done")
