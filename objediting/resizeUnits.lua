function parseUnitFile(filePath)
  local units = {}
  local currentUnitId = nil

  for line in io.lines(filePath) do
      -- Check for unit ID
      local id = line:match("%[(.-)%]")
      if id then
          currentUnitId = id
          units[currentUnitId] = {}
      elseif currentUnitId then
          -- Parse shadowW and shadowH
          local key, value = line:match("^(%w+)=(%d+)$")
          if key == "shadowW" or key == "shadowH" then
              units[currentUnitId][key] = tonumber(value)
          end
      end
  end

  return units
end

SizeScalingValueTable = {}
local units = parseUnitFile("unitskin.txt")
for id, unit in pairs(units) do
    if unit.shadowW ~= nil or unit.shadowH ~= nil then
        local sizeScalingValue = (120 * 120) / (tonumber(unit.shadowW) * tonumber(unit.shadowH))
        SizeScalingValueTable[id] = sizeScalingValue
    end
end
