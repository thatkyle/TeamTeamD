DefaultMenus01 = nil 
TriggerDefaultMenus01 = nil 
InvisButton04T = {} 
TriggerInvisButton04T = {} 
BackdropVeryBlack08 = nil 
TriggerBackdropVeryBlack08 = nil 
Text07 = nil 
TriggerText07 = nil 
InvisButton09 = nil 
TriggerInvisButton09 = nil 
REFORGEDUIMAKER = {}
REFORGEDUIMAKER.InvisButton04T00Func = function() 
BlzFrameSetEnable(InvisButton04T[0], false) 
BlzFrameSetEnable(InvisButton04T[0], true) 
end 
 
REFORGEDUIMAKER.InvisButton04T01Func = function() 
BlzFrameSetEnable(InvisButton04T[1], false) 
BlzFrameSetEnable(InvisButton04T[1], true) 
end 
 
REFORGEDUIMAKER.InvisButton04T02Func = function() 
BlzFrameSetEnable(InvisButton04T[2], false) 
BlzFrameSetEnable(InvisButton04T[2], true) 
end 
 
REFORGEDUIMAKER.InvisButton04T03Func = function() 
BlzFrameSetEnable(InvisButton04T[3], false) 
BlzFrameSetEnable(InvisButton04T[3], true) 
end 
 
REFORGEDUIMAKER.InvisButton04T04Func = function() 
BlzFrameSetEnable(InvisButton04T[4], false) 
BlzFrameSetEnable(InvisButton04T[4], true) 
end 
 
REFORGEDUIMAKER.InvisButton09Func = function() 
BlzFrameSetEnable(InvisButton09, false) 
BlzFrameSetEnable(InvisButton09, true) 
end 
 
REFORGEDUIMAKER.Initialize = function()
BlzFrameSetVisible(BlzGetOriginFrame(ORIGIN_FRAME_HERO_BAR,0), false)
BlzFrameSetVisible(BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP,0), false)
BlzFrameSetVisible(BlzGetOriginFrame(ORIGIN_FRAME_PORTRAIT, 0), false)


DefaultMenus01 = BlzCreateFrame("EscMenuBackdrop", BlzGetFrameByName("ConsoleUIBackdrop", 0), 0, 0)
BlzFrameSetAbsPoint(DefaultMenus01, FRAMEPOINT_TOPLEFT, 0.000220000, 0.152230)
BlzFrameSetAbsPoint(DefaultMenus01, FRAMEPOINT_BOTTOMRIGHT, 0.802020, 0.000560000)

InvisButton04T[0] = BlzCreateFrame("IconButtonTemplate", DefaultMenus01, 0, 0)
BlzFrameSetAbsPoint(InvisButton04T[0], FRAMEPOINT_TOPLEFT, 0.190620, 0.126770)
BlzFrameSetAbsPoint(InvisButton04T[0], FRAMEPOINT_BOTTOMRIGHT, 0.290620, 0.0267700)
TriggerInvisButton04T[0] = CreateTrigger() 
BlzTriggerRegisterFrameEvent(TriggerInvisButton04T[0], InvisButton04T[0], FRAMEEVENT_CONTROL_CLICK) 
TriggerAddAction(TriggerInvisButton04T[0], REFORGEDUIMAKER.InvisButton04T00Func) 

InvisButton04T[1] = BlzCreateFrame("IconButtonTemplate", DefaultMenus01, 0, 0)
BlzFrameSetAbsPoint(InvisButton04T[1], FRAMEPOINT_TOPLEFT, 0.300620, 0.126770)
BlzFrameSetAbsPoint(InvisButton04T[1], FRAMEPOINT_BOTTOMRIGHT, 0.400620, 0.0267700)
TriggerInvisButton04T[1] = CreateTrigger() 
BlzTriggerRegisterFrameEvent(TriggerInvisButton04T[1], InvisButton04T[1], FRAMEEVENT_CONTROL_CLICK) 
TriggerAddAction(TriggerInvisButton04T[1], REFORGEDUIMAKER.InvisButton04T01Func) 

InvisButton04T[2] = BlzCreateFrame("IconButtonTemplate", DefaultMenus01, 0, 0)
BlzFrameSetAbsPoint(InvisButton04T[2], FRAMEPOINT_TOPLEFT, 0.410620, 0.126770)
BlzFrameSetAbsPoint(InvisButton04T[2], FRAMEPOINT_BOTTOMRIGHT, 0.510620, 0.0267700)
TriggerInvisButton04T[2] = CreateTrigger() 
BlzTriggerRegisterFrameEvent(TriggerInvisButton04T[2], InvisButton04T[2], FRAMEEVENT_CONTROL_CLICK) 
TriggerAddAction(TriggerInvisButton04T[2], REFORGEDUIMAKER.InvisButton04T02Func) 

InvisButton04T[3] = BlzCreateFrame("IconButtonTemplate", DefaultMenus01, 0, 0)
BlzFrameSetAbsPoint(InvisButton04T[3], FRAMEPOINT_TOPLEFT, 0.520620, 0.126770)
BlzFrameSetAbsPoint(InvisButton04T[3], FRAMEPOINT_BOTTOMRIGHT, 0.620620, 0.0267700)
TriggerInvisButton04T[3] = CreateTrigger() 
BlzTriggerRegisterFrameEvent(TriggerInvisButton04T[3], InvisButton04T[3], FRAMEEVENT_CONTROL_CLICK) 
TriggerAddAction(TriggerInvisButton04T[3], REFORGEDUIMAKER.InvisButton04T03Func) 

InvisButton04T[4] = BlzCreateFrame("IconButtonTemplate", DefaultMenus01, 0, 0)
BlzFrameSetAbsPoint(InvisButton04T[4], FRAMEPOINT_TOPLEFT, 0.630620, 0.126770)
BlzFrameSetAbsPoint(InvisButton04T[4], FRAMEPOINT_BOTTOMRIGHT, 0.730620, 0.0267700)
TriggerInvisButton04T[4] = CreateTrigger() 
BlzTriggerRegisterFrameEvent(TriggerInvisButton04T[4], InvisButton04T[4], FRAMEEVENT_CONTROL_CLICK) 
TriggerAddAction(TriggerInvisButton04T[4], REFORGEDUIMAKER.InvisButton04T04Func) 

BackdropVeryBlack08 = BlzCreateFrame("QuestButtonDisabledBackdropTemplate", DefaultMenus01, 0, 0)
BlzFrameSetAbsPoint(BackdropVeryBlack08, FRAMEPOINT_TOPLEFT, 0.0783900, 0.126770)
BlzFrameSetAbsPoint(BackdropVeryBlack08, FRAMEPOINT_BOTTOMRIGHT, 0.178390, 0.0267700)

Text07 = BlzCreateFrameByType("TEXT", "name", BackdropVeryBlack08, "", 0)
BlzFrameSetPoint(Text07, FRAMEPOINT_TOPLEFT, BackdropVeryBlack08, FRAMEPOINT_TOPLEFT, 0.023350, -0.035450)
BlzFrameSetPoint(Text07, FRAMEPOINT_BOTTOMRIGHT, BackdropVeryBlack08, FRAMEPOINT_BOTTOMRIGHT, 0.018270, 0.016590)
BlzFrameSetText(Text07, "|cffFFCC00Reroll|r")
BlzFrameSetEnable(Text07, false)
BlzFrameSetScale(Text07, 2.43)
BlzFrameSetTextAlignment(Text07, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)

InvisButton09 = BlzCreateFrame("IconButtonTemplate", BackdropVeryBlack08, 0, 0)
BlzFrameSetAbsPoint(InvisButton09, FRAMEPOINT_TOPLEFT, 0.0783900, 0.126770)
BlzFrameSetAbsPoint(InvisButton09, FRAMEPOINT_BOTTOMRIGHT, 0.178390, 0.0267700)
TriggerInvisButton09 = CreateTrigger() 
BlzTriggerRegisterFrameEvent(TriggerInvisButton09, InvisButton09, FRAMEEVENT_CONTROL_CLICK) 
TriggerAddAction(TriggerInvisButton09, REFORGEDUIMAKER.InvisButton09Func) 
end
