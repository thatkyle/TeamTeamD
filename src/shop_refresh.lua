package.path = package.path .. ";C:\\Users\\Kyle\\workspace\\wc3\\wc3maps\\TeamTeamD\\objediting\\?.lua"
local json = require("dkjson")

math.randomseed(os.time())

local function updateUnitCostPoolSize(number_of_players)
  return {
    22, -- 1-cost units
    20, -- 2-cost units
    17, -- 3-cost units
    10, -- 4-cost units
    9   -- 5-cost units
  }
end

local unitCostPoolSizes = updateUnitCostPoolSize()

local unitShopChancesByLevel = {		       -- playerLevel
  --   1-cost%, 2-cost%, 3-cost%, 4-cost%, 5-cost%
  {1,    0,    0,    0,    0},    -- 1
  {1,    0,    0,    0,    0},    -- 2
  {0.75, 0.25, 0,    0,    0},    -- 3
  {0.55, 0.30, 0.15, 0,    0},    -- 4
  {0.45, 0.33, 0.20, 0.02, 0},    -- 5
  {0.30, 0.40, 0.25, 0.05, 0},    -- 6
  {0.19, 0.35, 0.35, 0.10, 0.01}, -- 7
  {0.18, 0.25, 0.36, 0.18, 0.03}, -- 8
  {0.10, 0.20, 0.25, 0.35, 0.10}, -- 9
  {0.05, 0.10, 0.20, 0.40, 0.25}, -- 10
  {0.01, 0.02, 0.12, 0.50, 0.35}  -- 11
};

local accumulatedUnitShopChancesByLevel = {}

for i, levelChances in ipairs(unitShopChancesByLevel) do
  local accumulatedChances = {}
  local accumulatedChance = 0
  for j, chance in ipairs(levelChances) do
    accumulatedChance = accumulatedChance + chance * 100
    table.insert(accumulatedChances, accumulatedChance)
  end
  table.insert(accumulatedUnitShopChancesByLevel, accumulatedChances)
end

-- TODO: In games with fewer players, the unit cost odds become skewed because
-- more units of the same cost are available in the pool. In the common case of
-- you holding 6 1-cost units of the same type, and looking for the last 3 at level 4,
-- the chances of finding them in a 2 player game are ~40%, vs ~65% in an 8 player game
-- The simplest solution is to give players unit duplicators depending on the number of
-- players, more duplicators for fewer players

local sharedUnitDataPath = "C:\\Users\\Kyle\\workspace\\wc3\\wc3maps\\TeamTeamD\\shared\\unit_data.json"
local unitsData = json.decode(io.open(sharedUnitDataPath, "r"):read("*all"))
local levelOneUnitsData = {}
for unitId, unit in pairs(unitsData) do
  if tonumber(unit['unitLevel']) == 1 then
    levelOneUnitsData[unitId] = unit
  end
end

local function initializeUnitPoolByCost()
  -- construct a pool of unitIds for each cost
  -- all 1-cost unitIds will be in unitPoolByCost[1], 2-cost unitIds in unitPoolByCost[2] etc.
  -- unitIds will be removed from the pool when they are bought
  local unitPoolByCost = { {}, {}, {}, {}, {} }
  for unitId, unit in pairs(levelOneUnitsData) do
    local unitCost = tonumber(unit['unitCost'])
    local unitPoolQuantity = unitCostPoolSizes[tonumber(unitCost)]
    for i = 1, unitPoolQuantity do
      table.insert(unitPoolByCost[unitCost], unitId)
    end
  end
  return unitPoolByCost
end

local unitPoolByCost = initializeUnitPoolByCost()

-- for i, costPool in ipairs(unitPool) do
--   print("Cost pool " .. i)
--   for j, unitId in ipairs(costPool) do
--     print(j .. ' ' .. unitId)
--   end
-- end

local function getUnitFromPool(playerLever, unitPool)
  local unitShopCostChances = accumulatedUnitShopChancesByLevel[playerLever]
  local probabilityRoll = math.random(1, 100)
  local rolledUnitCost = 0
  for index, cumulativeProbability in ipairs(unitShopCostChances) do
    if probabilityRoll <= cumulativeProbability then
      rolledUnitCost = index
      break
    end
  end
  if rolledUnitCost == 0 then
    rolledUnitCost = #unitShopCostChances
  end
  local costPool = unitPool[rolledUnitCost]
  local index = math.random(1, #costPool)
  local unitId = table.remove(costPool, index)
  return unitId
end

-- print('cost pool sizes before')
-- for i, costPool in ipairs(unitPoolByCost) do
--   print(i .. ' ' .. #costPool)
-- end

-- for i = 1, 100 do
--   getUnitFromPool(7, unitPoolByCost)
-- end

-- print('cost pool sizes after')
-- for i, costPool in ipairs(unitPoolByCost) do
--   print(i .. ' ' .. #costPool)
-- end