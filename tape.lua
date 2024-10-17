local baseSpeed = 32768

function printHelp()
  print("tape label (<side>) <label>")
  print("tape play (<side>)")
  print("tape rewind (<side>)")
  print("tape setspeed (<side>) <value>")
  print("tape silence (<side>)")
  print("tape stop (<side>)")
end

function getTapeSide()
  local periphList = peripheral.getNames()
  local tapeList = {}
  for k,v in pairs(periphList) do
    if (peripheral.getType(v) == "tape_drive") then
      table.insert(tapeList, v)
    end
  end
  if (#tapeList == 0) then
    print("No tape-drive attached")
    return nil
  end
  if (#tapeList == 1) then
    return tapeList[1]
  else
    print(table.concat(tapeList, ","))
    print("Select side:")
    return read()
  end
end

local args = {...}
if (#args < 1) then
  printHelp()
  return
end
local cmd = table.remove(args, 1)
local selectSide = nil
local expectedArgs = {
  ["label"] = 1,
  ["play"] = 0,
  ["rewind"] = 0,
  ["setspeed"] = 1,
  ["silence"] = 0,
  ["stop"] = 0
}
expectedArgs = expectedArgs[cmd]
if (expectedArgs == nil) then
  print("Invalid command")
  return
end
if (#args < expectedArgs) then
  print("Too few arguments")
  return
end
if (#args > expectedArgs) then
  selectSide = table.remove(args, 1)
else
  selectSide = getTapeSide()
end
if (peripheral.getType(selectSide) ~= "tape_drive") then
  print("Invalid side")
  return
end
local tape = peripheral.wrap(selectSide)
if (not tape.isReady()) then
  print("No tape inserted")
  return
end
if (cmd == "label") then
  tape.setLabel(args[1])
elseif (cmd == "play") then
  tape.seek(-tape.getSize())
  local speed = (tape.read() / 255) + 1
  tape.setSpeed(speed)
  tape.play()
elseif (cmd == "rewind" or cmd == "stop") then
  tape.stop()
  tape.seek(-tape.getSize())
elseif (cmd == "setspeed") then
  local newSpeed = tonumber(args[1])
  if (newSpeed == nil) then
    print("Speed must be a number.")
    return
  elseif (newSpeed >= baseSpeed and newSpeed <= 2 * baseSpeed) then
    newSpeed = newSpeed / baseSpeed
  elseif (newSpeed < 1.0 or newSpeed > 2.0) then
    print("Speed must be between 1 and 2 (multiplier)")
    print("or a supported sample rate.")
    return
  end
  tape.stop()
  tape.seek(-tape.getSize())
  tape.write(math.floor((newSpeed - 1) * 255 + 0.5))
elseif (cmd == "silence") then
  local remainder = tape.seek(tape.getSize())
  tape.seek(-remainder)
  local ctr = 0
  for i = 1,remainder do
    tape.write(85)
    ctr = ctr + 1
    if (ctr >= 65536) then
      ctr = 0
      sleep(0.1)
      print("Written ", i, " bytes")
    end
  end
end