-- dofile('hide_ui.lua')
-- dofile('shop_ui.lua')
-- REFORGEDUIMAKER.Initialize()
-- print('Hello warcraft-vscode !')

-- CreateUnit(Player(0), FourCC('H101'), 0, 0, 293.630)
-- local unit = CreateUnit(Player(0), FourCC('hpea'), 2000, -2000, 293.630)

for i = 0, 200 do
  local unitId = string.format("u%03d", i)
  CreateUnit(Player(0), FourCC(unitId), 2000, -2000, 293.630)
end

-- local blademaster = BlzCreateFrameByType("BACKDROP", "Blademaster", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
-- BlzFrameSetSize(blademaster, 0.04, 0.04)
-- BlzFrameSetAbsPoint(blademaster, FRAMEPOINT_CENTER, 0.4, 0.3)
-- BlzFrameSetTexture(blademaster, "ReplaceableTextures\\CommandButtons\\BTNHeroBlademaster",0, true)