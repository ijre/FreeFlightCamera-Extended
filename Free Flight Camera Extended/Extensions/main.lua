local Ext = FFC.Ext or { }
local Paths = Ext.Paths

if RequiredScript == "lib/managers/statisticsmanager" then
  local origStopSesh = StatisticsManager.stop_session
  function StatisticsManager:stop_session(data)
    FFC:set_game_speed(1.0)
    origStopSesh(self, data)
  end

  return
end

dofile(Paths.Ext .. "GUI.lua")
dofile(Paths.Keybinds .. "main.lua")

Hooks:PostHook(GameSetup, "update", "FFCExtsUpdateModifiers", function()
  local time = TimerManager:main():time()
  Ext.GUI:UpdateModifiers(time)
  Ext.Binds:CheckHeld(time)
end)

FFC.Ext = Ext