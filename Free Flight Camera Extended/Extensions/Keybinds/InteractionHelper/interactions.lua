local origInterrupt = PlayerStandard._interupt_action_interact
function PlayerStandard:_interupt_action_interact(time, input, complete)
  origInterrupt(self, time, input, complete)

  if FFC and FFC.Ext.Binds.MaxUntilInteractEnd then
    dofile(FFC.Ext.Paths.Keybinds .. "reset.lua")
    FFC.Ext.Binds.MaxUntilInteractEnd = false
  end
end