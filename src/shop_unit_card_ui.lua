-- accept unitId as parameter
-- get unit name, traits and cost from shared unit data
-- create a unit card frame
-- set the unit card frame's size, texture, and position the unit card in the shop

local sharedUnitDataPath = '../shared/unit_data.json'
local unitsData = json.decode(io.open(sharedUnitDataPath, "r"):read("*all"))
-- local levelOneUnitsData = {}
-- for unitId, unit in pairs(unitsData) do
--   if tonumber(unit['unitLevel']) == 1 then
--     levelOneUnitsData[unitId] = unit
--   end
-- end

local function getUnitCardData(unitId)
  local unit = unitsData[unitId]
  if unit['unitLevel'] ~= 1 then
    print('ERROR: getUnitCardData called with a non-level-one unitId')
  end
  local unitName = string.sub(unit['unitName'], 1, -3) -- Strips the last two characters from the unit name, goal is to remove the level number
  local unitTraits = unit['unitTraits']
  local unitCost = unit['unitCost']
  local unitCardData = {unitName, unitTraits, unitCost}
  return unitCardData
end

-- IMPORTANT: NEED TO TEST THAT DIFFERENT PLAYERS CAN SEE DIFFERENT SHOPS
-- create unit shop card with unit icon texture, something like this:
-- local blademaster = BlzCreateFrameByType("BACKDROP", "Blademaster", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
-- BlzFrameSetSize(blademaster, 0.04, 0.04)
-- BlzFrameSetAbsPoint(blademaster, FRAMEPOINT_CENTER, 0.4, 0.3)
-- BlzFrameSetTexture(blademaster, "ReplaceableTextures\\CommandButtons\\BTNHeroBlademaster",0, true)
-- create traits badges
-- create unit name and cost card footer bars

UnitCardBackdrop = nil 
TriggerUnitCardBackdrop = nil 
UnitCardTrait1Backdrop = nil 
TriggerUnitCardTrait1Backdrop = nil 
UnitCardTrait3Backdrop = nil 
TriggerUnitCardTrait3Backdrop = nil 
UnitCardTrait2Backdrop = nil 
TriggerUnitCardTrait2Backdrop = nil 
UnitCardFooterBar = nil 
TriggerUnitCardFooterBar = nil 
UnitCardTrait1Text = nil 
TriggerUnitCardTrait1Text = nil 
UnitCardTrait3Text = nil 
TriggerUnitCardTrait3Text = nil 
UnitCardTrait2Text = nil 
TriggerUnitCardTrait2Text = nil 
UnitCardNameText = nil 
TriggerUnitCardNameText = nil 
UnitCardCostText = nil 
TriggerUnitCardCostText = nil 
REFORGEDUIMAKER = {}
REFORGEDUIMAKER.Initialize = function()

UnitCardBackdrop = BlzCreateFrameByType("BACKDROP", "BACKDROP", BlzGetFrameByName("ConsoleUIBackdrop", 0), "", 1)
BlzFrameSetAbsPoint(UnitCardBackdrop, FRAMEPOINT_TOPLEFT, 0.0716900, 0.326220)
BlzFrameSetAbsPoint(UnitCardBackdrop, FRAMEPOINT_BOTTOMRIGHT, 0.183360, 0.214700)
BlzFrameSetTexture(UnitCardBackdrop, "CustomFrame.png", 0, true)

local function positionFrameRelativeToParent(f, p, tlX, tlY, brX, brY)
  BlzFrameSetPoint(f, FRAMEPOINT_TOPLEFT, p, FRAMEPOINT_TOPLEFT, tlX, tlY)
  BlzFrameSetPoint(f, FRAMEPOINT_BOTTOMRIGHT, p, FRAMEPOINT_BOTTOMRIGHT, brX, brY)
end

local function bcf00(name, parent) return BlzCreateFrame(name, parent, 0, 0) end
local function bcfTraitText(name, parent, text)
  local f = BlzCreateFrameByType("TEXT", "name", parent, "", 0)
  BlzFrameSetPoint(f, FRAMEPOINT_TOPLEFT, parent, FRAMEPOINT_TOPLEFT, 0.0022300, -0.0060500)
  BlzFrameSetPoint(f, FRAMEPOINT_BOTTOMRIGHT, parent, FRAMEPOINT_BOTTOMRIGHT, 0.0011200, 0.0017600)
  BlzFrameSetText(f, text) -- "|cffFFCC00TestTrait3|r")
  BlzFrameSetEnable(f, false)
  BlzFrameSetScale(f, 1.00)
  BlzFrameSetTextAlignment(f, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
  return f
end

local function getTraitWidgetFrames(traits)
  local widgetBackdrops = {}
  local widgetTexts = {}
  local widgetBackdrop_tlX = 0.0025800
  local widgetBackdrop_brX = -0.055490
  local widgetBackdrop_tlYInitial = -0.0073400
  local widgetBackdrop_brYInitial = 0.080760
  local widgetBackdrop_YDelta = -0.025

  for i = 1, #traits do
    widgetBackdrops[i] = bcf00("CheckListBox", UnitCardBackdrop)
    positionFrameRelativeToParent(widgetBackdrops[i], UnitCardBackdrop, widgetBackdrop_tlX, widgetBackdrop_tlYInitial + widgetBackdrop_YDelta * (i - 1), widgetBackdrop_brX, widgetBackdrop_brYInitial + widgetBackdrop_YDelta * (i - 1))
  end
  
  for i = 1, #traits do
    widgetTexts[i] = bcfTraitText("name", widgetBackdrops[i], "|cffFFCC00" .. traits[i] .. "|r")
  end
end
-- UnitCardTrait1Backdrop = FRAMEPOINT_TOPLEFT, 0.0025800, -0.057120) FRAMEPOINT_BOTTOMRIGHT, -0.055490, 0.030980)
-- UnitCardTrait2Backdrop = FRAMEPOINT_TOPLEFT, 0.0025800, -0.032990) FRAMEPOINT_BOTTOMRIGHT, -0.055490, 0.055110)
-- UnitCardTrait3Backdrop = FRAMEPOINT_TOPLEFT, 0.0027000, -0.0073400) FRAMEPOINT_BOTTOMRIGHT, -0.055370, 0.080760)

UnitCardFooterBar = BlzCreateFrame("QuestButtonPushedBackdropTemplate", UnitCardBackdrop, 0, 0)
BlzFrameSetPoint(UnitCardFooterBar, FRAMEPOINT_TOPLEFT, UnitCardBackdrop, FRAMEPOINT_TOPLEFT, 0.0000, -0.084250)
BlzFrameSetPoint(UnitCardFooterBar, FRAMEPOINT_BOTTOMRIGHT, UnitCardBackdrop, FRAMEPOINT_BOTTOMRIGHT, 0.0000, -0.00061000)

UnitCardNameText = BlzCreateFrameByType("TEXT", "name", UnitCardFooterBar, "", 0)
positionFrameRelativeToParent(UnitCardNameText, UnitCardFooterBar, 0.0022300, -0.0068100, -0.033500, -0.00012000)

BlzFrameSetText(UnitCardNameText, "|cffFFCC00Unit Name|r")
BlzFrameSetEnable(UnitCardNameText, false)
BlzFrameSetScale(UnitCardNameText, 1.57)
BlzFrameSetTextAlignment(UnitCardNameText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)

UnitCardCostText = BlzCreateFrameByType("TEXT", "name", UnitCardFooterBar, "", 0)
BlzFrameSetPoint(UnitCardCostText, FRAMEPOINT_TOPLEFT, UnitCardFooterBar, FRAMEPOINT_TOPLEFT, 0.090750, -0.0074000)
BlzFrameSetPoint(UnitCardCostText, FRAMEPOINT_BOTTOMRIGHT, UnitCardFooterBar, FRAMEPOINT_BOTTOMRIGHT, 0.0047600, -0.0040600)
BlzFrameSetText(UnitCardCostText, "|cffFFCC003g|r")
BlzFrameSetEnable(UnitCardCostText, false)
BlzFrameSetScale(UnitCardCostText, 1.57)
BlzFrameSetTextAlignment(UnitCardCostText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
end

