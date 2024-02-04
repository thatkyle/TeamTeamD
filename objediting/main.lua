package.path = package.path .. ";C:\\Users\\Kyle\\workspace\\wc3\\wc3maps\\TeamTeamD\\objediting\\?.lua"
local json = require("dkjson")

dofile('getUnitBaseIdsList.lua')
dofile('resizeUnits.lua')
dofile('getUnitIconPaths.lua')

local function readCSVtoTable(filename)
  local file = io.open(filename, "r")
  local data = {}
  local headers = {}

  local line = file:read()
  for header in line:gmatch("[^,]+") do
      table.insert(headers, header)
  end

  for line in file:lines() do
      local row = {}
      local i = 1
      for value in line:gmatch("[^,]+") do
          row[headers[i]] = value
          print(headers[i], value)
          i = i + 1
      end
      table.insert(data, row)
  end

  file:close()
  return data
end

local unitData = readCSVtoTable('TeamTeamDUnitData - Sheet3.csv')

local function getColumnValueAsNumber(row, columnName)
  return tonumber(row[columnName])
end

local function writeTableToFile(table, indent, file)
  indent = indent or ""
  for key, value in pairs(table) do
      if type(value) == "table" then
          file:write(indent .. tostring(key) .. ":")
          writeTableToFile(value, indent .. "  ", file)
      else
          file:write(indent .. tostring(key) .. ": " .. tostring(value))
      end
  end
end

local sharedUnitDataTable = {}
for i, row in ipairs(unitData) do
  for j = 1, 3 do
    local unitId = string.format("u%03d", ((i - 1) * 3) + j)
    local unitBaseId = row['BaseID']
    local unit = UnitDefinition:new(unitId, unitBaseId)
    local unitName = string.format("%s %d", row['New Unit'], j)
    unit:setName(unitName)
    local maxBaseHp = getColumnValueAsNumber(row, string.format("HP%d", j))
    unit:setHitPointsMaximumBase(maxBaseHp)
    local attackDamageBase = getColumnValueAsNumber(row, string.format("AD%d", j))
    unit:setAttack1DamageBase(attackDamageBase)
    local attackRange = getColumnValueAsNumber(row, 'Range')
    unit:setAttack1Range(attackRange)
    if tonumber(attackRange) > 100 then
      unit:setAttack1ProjectileSpeed(1200)
      unit:setAttack1ProjectileHomingEnabled(true)
    end
    local attackSpeed = getColumnValueAsNumber(row, 'AS')
    unit:setAttack1CooldownTime(attackSpeed)
    unit:setArmorType('normal')
    local armorBase = getColumnValueAsNumber(row, 'AR')
    unit:setDefenseBase(armorBase)
    unit:setManaRegeneration(0)
    local maxMana = getColumnValueAsNumber(row, 'Skill Mana')
    unit:setManaMaximum(maxMana)
    local startingMana = getColumnValueAsNumber(row, 'Starting Mana')
    unit:setManaInitialAmount(startingMana)
    unit:setMinimumAttackRange(0)
    local sizeScalingValue = SizeScalingValueTable[unitBaseId]
    if sizeScalingValue == nil then
      sizeScalingValue = 1.0
    end
    if unitBaseId == 'orai' then
      sizeScalingValue = 1.0
    end
    if unitBaseId == 'nwgs' then
      sizeScalingValue = 0.5
    end
    local unitBoardScalingValue = 1 / 1.8
    sizeScalingValue = sizeScalingValue * unitBoardScalingValue
    if j == 2 then
      sizeScalingValue = sizeScalingValue * (1.2)
    end
    if j == 3 then
      sizeScalingValue = sizeScalingValue * (1.4)
    end
    unit:setScalingValue(sizeScalingValue)
    unit:setSelectionScale(sizeScalingValue)
    unit:setCollisionSize(32.0 * sizeScalingValue)
    unit:setSpeedBase(522)

    local unitCost = row['Cost']
    local trait3 = row['New Trait 3']
    local unitTraits = { row ['New Trait 1'], row['New Trait 2'] }
    if trait3 ~= 'None' then
      table.insert(unitTraits, trait3)
    end
    local sharedUnitData = {
      unitLevel = j,
      unitId = unitId,
      unitBaseId = unitBaseId,
      unitName = unitName,
      unitCost = unitCost,
      unitTraits = unitTraits
    }
    sharedUnitDataTable[unitId] = sharedUnitData
  end
end


local sharedUnitDataPath = "C:\\Users\\Kyle\\workspace\\wc3\\wc3maps\\TeamTeamD\\shared\\unit_data.json"
local sharedUnitDataFile = io.open(sharedUnitDataPath, "w")
if sharedUnitDataFile then
  sharedUnitDataFile:write(json.encode(sharedUnitDataTable, {indent = true}))
  sharedUnitDataFile:close()
end