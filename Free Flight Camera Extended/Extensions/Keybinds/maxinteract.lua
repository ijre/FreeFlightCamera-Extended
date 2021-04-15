local state = managers.player:get_current_state()
local path = FFC.Ext.Paths and FFC.Ext.Paths.Keybinds

if state and state:_interacting() then
  dofile(path .. "max.lua")
  FFC.Ext.Binds.MaxUntilInteractEnd = true
end