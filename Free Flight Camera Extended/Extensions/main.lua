local Ext = FFC.Ext or { }
local Paths = Ext.Paths

dofile(Paths.Ext .. "GUI.lua")
dofile(Paths.Keybinds .. "main.lua")

Hooks:PostHook(GameSetup, "update", "FFCExtsUpdateModifiers", function()
  local time = TimerManager:main():time()
  Ext.GUI:UpdateModifiers(time)
  Ext.Binds:CheckHeld(time)
end)

FFC.Ext = Ext