os.loadAPI("password")

local sessionTimeout = 30

password.hook()
password.prompt(sessionTimeout)
password.promptOnTerminate()

local chromNames = {
  [0] = "Species",
  [1] = "Speed",
  [2] = "Lifespan",
  [3] = "Fertility",
  [4] = "Temperature Tolerance",
  [5] = "Nocturnal",
  [7] = "Humidity Tolerance",
  [8] = "Tolerant Flyer",
  [9] = "Cave Dwelling",
  [10] = "Flowers",
  [11] = "Pollination",
  [12] = "Territory",
  [13] = "Effect",
}

local alleleNames = {
  ["forestry.boolFalse"] = "False",
  ["forestry.boolTrue"] = "True",
  ["forestry.fertilityLow"] = "1 drone",
  ["forestry.fertilityNormal"] = "2 drones",
  ["forestry.fertilityHigh"] = "3 drones",
  ["forestry.fertilityMaximum"] = "4 drones",
  ["forestry.lifespanLong"] = "Long",
  ["forestry.lifespanLonger"] = "Longer",
  ["forestry.lifespanLongest"] = "Longest",
  ["forestry.lifespanNormal"] = "Normal",
  ["forestry.lifespanShort"] = "Short",
  ["forestry.lifespanShortened"] = "Shortened",
  ["forestry.lifespanShorter"] = "Shorter",
  ["forestry.lifespanShortest"] = "Shortest",
  ["forestry.toleranceBoth1"] = "Both 1",
  ["forestry.toleranceBoth2"] = "Both 2",
  ["forestry.toleranceBoth3"] = "Both 3",
  ["forestry.toleranceDown1"] = "Down 1",
  ["forestry.toleranceDown2"] = "Down 2",
  ["forestry.toleranceNone"] = "None",
  ["forestry.toleranceUp1"] = "Up 1",
}

function getDefault(tbl, v)
  if (tbl[v] ~= nil) then
    return tbl[v]
  else
    return v
  end
end

function mapFilterArray(items, func)
  local i = 1
  local result = {}
  for k, v in ipairs(items) do
    local newVal = func(k, v)
    if (newVal ~= nil) then
      result[i] = newVal
      i = i + 1
    end
  end
  return result
end

function filterGenes(k, v)
  local iid = v.getValue1()
  if (iid.getId() ~= 4750) then
    return nil
  end
  local tags = iid.getTagCompound().value
  if (tags.species.value ~= "rootBees") then
    return nil
  end
  return {
    id = iid,
    chromosome = tags.chromosome.value,
    allele = tags.allele.value,
    quantity = v.getValue2()
  }
end

function sortByKey(items, keySelector)
  return table.sort(items,
    function(a, b) 
      return keySelector(a) < keySelector(b)
    end)
end

function menu(items, options)
  if (options == nil) then
    options = {}
  end
  local prompt = options.prompt
  if (prompt == nil) then
    prompt = ""
  end
  local allowCancel = options.allowCancel
  if (allowCancel == nil) then
    allowCancel = false
  end
  local labelFunc = options.labelFunc
  if (labelFunc == nil) then
    labelFunc = tostring
  end
  local fastSelect = options.fastSelect
  if (fastSelect == nil) then
    fastSelect = false
  end
  
  local itemCount = #items
  local saveBGColor = term.getBackgroundColor()
  local saveFGColor = term.getTextColor()
  local width, height = term.getSize()
  local displayItems = height - 4
  local scroll = 0
  local selectedIndex = 0
  if (not allowCancel) then
    selectedIndex = 1
  end
  local maxScroll = itemCount - displayItems
  if (maxScroll < 0) then maxScroll = 0 end
  local scrollMag = math.floor(height / 3)
  if (scrollMag <= 0) then scrollMag = 1 end
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1,1)
  term.setBackgroundColor(colors.gray)
  term.setTextColor(colors.white)
  term.clearLine()
  term.write(prompt)
  local runLoop = true
  while runLoop do
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.yellow)
    
    term.setCursorPos(1,2)
    term.clearLine()
    if (scroll > 0) then
      term.write(" -^-")
    end
    
    term.setCursorPos(1,height-1)
    term.clearLine()
    if (scroll < maxScroll) then
      term.write(" -v-")
    end
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    for i=1,displayItems do
      if (i + scroll == selectedIndex) then
        term.setBackgroundColor(colors.gray)
      elseif (i + scroll == selectedIndex + 1) then
        term.setBackgroundColor(colors.black)
      end
      term.setCursorPos(2, i + 2)
      term.clearLine()
      if (i + scroll <= itemCount) then
        term.write(labelFunc(items[i + scroll]))
      end
    end
    term.setCursorPos(1, height)
    term.setBackgroundColor(colors.black)
    term.clearLine()
    if (selectedIndex > 0) then
      term.setTextColor(colors.lime)
      term.clearLine()
      term.write(" [Select] ")
      term.setTextColor(colors.white)
      term.write(labelFunc(items[selectedIndex]))
    end
    if (allowCancel) then
      term.setCursorPos(width - 9, height)
      term.setTextColor(colors.red)
      term.write(" [Cancel] ")
    end
    local ev, arg1, arg2, arg3 = os.pullEvent()
    if (ev == "mouse_click") then
      if (arg3 <= 2) then
        scroll = scroll - scrollMag
      elseif (arg3 < height - 1) then
        local newIndex = arg3 + scroll - 2
        if (newIndex <= itemCount) then
          selectedIndex = newIndex
          if (fastSelect) then
            runLoop = false
          end
        end
      elseif (arg3 == height - 1) then
        scroll = scroll + scrollMag
      elseif (arg3 == height) then
        if (arg2 >= width - 9 and allowCancel) then
          selectedIndex = 0
          runLoop = false
        elseif (selectedIndex > 0) then
          runLoop = false
        end
      end
    elseif (ev == "mouse_scroll") then
      scroll = scroll + 4 * arg1
    elseif (ev == "key") then
      local scrollToSelected = false
      if (arg1 == keys.up) then
        if (selectedIndex == 0) then
          selectedIndex = 1
        elseif (selectedIndex > 1) then
          selectedIndex = selectedIndex - 1
        end
        scrollToSelected = true
      elseif (arg1 == keys.down) then
        if (selectedIndex < itemCount) then
          selectedIndex = selectedIndex + 1
        end
        scrollToSelected = true
      elseif (arg1 == keys.enter and selectedIndex > 0) then
        runLoop = false
      elseif (arg1 == keys.grave and allowCancel) then
        selectedIndex = 0
        runLoop = false
      end
      if (scrollToSelected and selectedIndex > 0) then
        local selMinScroll = selectedIndex - displayItems
        if (scroll < selMinScroll) then
          scroll = selMinScroll
        end
        if (scroll > selectedIndex - 1) then
          scroll = selectedIndex - 1
        end
      end
    end
    if (scroll < 0) then scroll = 0 end
    if (scroll > maxScroll) then scroll = maxScroll end
  end
  term.setBackgroundColor(saveBGColor)
  term.setTextColor(saveFGColor)
  term.setCursorPos(1,1)
  term.clear()
  return selectedIndex
end

function waitRedstone(side, value)
  while (rs.getInput(side) ~= value) do
    os.pullEvent("redstone")
  end
end

local outPipe = peripheral.wrap(
  "LogisticsPipes:Request_0")
local dupPipe = peripheral.wrap(
  "LogisticsPipes:Request_1")
if (outPipe == nil) then
  print("Output pipe not connected")
  return
end
if (dupPipe == nil) then
  print("Duplicator pipe not connected")
  return
end
local lp = dupPipe.getLP()
local blankSampleID = lp.getItemIdentifierBuilder()
blankSampleID.setItemID(4749)
blankSampleID = blankSampleID.build()

while true do
  password.prompt(sessionTimeout)
  local geneSamples = mapFilterArray(dupPipe.getAvailableItems(), filterGenes)
  local chromChoice = {-1}
  local chromChoiceI = 2
  local chromChoiceKeys = {}
  for k, v in ipairs(geneSamples) do
    local chromTemp = v.chromosome
    if (chromChoiceKeys[chromTemp] == nil) then
      chromChoiceKeys[chromTemp] = true
      chromChoice[chromChoiceI] = chromTemp
      chromChoiceI = chromChoiceI + 1
    end
  end
  table.sort(chromChoice)
  chromChoice[chromChoiceI] = -2
  local chromoIdx = menu(chromChoice, {
    prompt = "Chromosome",
    allowCancel = true,
    fastSelect = true,
    labelFunc = function(v)
      if (v == -1) then return "(Refresh)" end
      if (v == -2) then return "(Logout)" end
      return getDefault(chromNames, v)
    end
  })
  if (chromoIdx == 0) then
    break
  end
  password.prompt(sessionTimeout)
  local chromo = chromChoice[chromoIdx]
  if (chromo == -2) then
    password.logout()
  elseif (chromo ~= -1) then
    local geneSamplesFilt =
      mapFilterArray(geneSamples, function(k, v)
        if (v.chromosome == chromo) then return v
        else return nil end
      end)
    sortByKey(geneSamplesFilt, function(v)
      return getDefault(alleleNames, v.allele)
    end)
    local geneSampleIdx = menu(geneSamplesFilt, {
      prompt = "Request Sample (" ..
        getDefault(chromNames, chromo) ..
        ")",
      allowCancel = true,
      labelFunc = function(v)
        return getDefault(alleleNames, v.allele)
      end
    })
    if (geneSampleIdx > 0) then
      term.setTextColor(colors.white)
      local selSample = geneSamplesFilt[geneSampleIdx]
      local quantity = dupPipe.getItemAmount(selSample.id)
      term.setCursorPos(1,1)
      if (quantity == 0) then
        term.setTextColor(colors.red)
        print("Error: Sample unavailable!")
      elseif (quantity >= 2) then
        term.write("Fetching sample")
        local status = outPipe.makeRequest(selSample.id, 1)
        if (status ~= "DONE") then
          term.setTextColor(colors.red)
          print("Error: Sample unavailable!")
        else
          term.setTextColor(colors.lime)
          print("Done")
        end
      else
        rs.setOutput("bottom", false)
        if (rs.getInput("back") == true) then
          print("Waiting for copying to finish")
        end
        waitRedstone("back", false)
        print("Requesting blank sample")
        local status = dupPipe.makeRequest(blankSampleID, 1)
        if (status == "DONE") then
          print("Requesting template")
          status = dupPipe.makeRequest(selSample.id, 1)
          if (status == "DONE") then
            print("Waiting for copying to start")
            waitRedstone("back", true)
            
            rs.setOutput("bottom", true)
            
            print("Waiting for copying to finish")
            waitRedstone("back", false)
            
            print("Waiting for sample to be available")
            while true do
              status = outPipe.makeRequest(selSample.id, 1)
              if (status == "DONE") then break end
              os.sleep(0.3)
            end
            
            rs.setOutput("bottom", false)
            term.setTextColor(colors.lime)
            print("Done")
          else
            term.setTextColor(colors.red)
            print("Error: Sample unavailable!")
          end
        else
          term.setTextColor(colors.red)
          print("No blank sample!")
        end
      end
      os.sleep(1.5)
    end
  end
end
password.prompt(sessionTimeout)