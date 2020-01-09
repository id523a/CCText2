if not term.isColor() then
  print("Advanced Computer is required.")
end
if (lightColor == nil) then
  lightColor = { 15,14,11 }
end
local colorSym = {
  colors.red,
  colors.lime,
  colors.blue
}
term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(12,2)
term.setTextColor(colors.yellow)
term.write("Light Control")
term.setTextColor(colors.white)
term.setCursorPos(1,3)
term.write("R [")
term.setCursorPos(1,4)
term.write("G [")
term.setCursorPos(1,5)
term.write("B [")
term.setCursorPos(34,3)
term.write("]")
term.setCursorPos(34,4)
term.write("]")
term.setCursorPos(34,5)
term.write("]")
while true do
  for i=1,3 do
    term.setCursorPos(4,i+2)
    term.setBackgroundColor(colorSym[i])
    term.write(string.rep(" ",2*lightColor[i]))
    term.setBackgroundColor(colors.black)
    term.write(string.rep(" ",2*(15-lightColor[i])))
  end
  term.setCursorPos(1,6)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  rs.setAnalogOutput("left",lightColor[1])
  rs.setAnalogOutput("back",lightColor[2])
  rs.setAnalogOutput("right",lightColor[3])
  ev, arg1, arg2, arg3 = os.pullEvent()
  if (ev == "mouse_click" or ev == "mouse_drag") then
    if (arg3 >= 2 and arg3 <= 5) then
      local newVal = math.floor((arg2 - 3) / 2)
      if (newVal > 15) then newVal = 15 end
      if (newVal < 0) then newVal = 0 end
      lightColor[arg3 - 2] = newVal
    end
  end
end