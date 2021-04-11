local GUI = class(FFC.Ext)

function GUI:ShowModifiers()
  if not FFC:enabled() then
    FFC._workspace:show()
    FFC._action_vis_time = 0
  end

  FFC:draw_modifiers()
end

function GUI:UpdateModifiers(time)
  if not FFC:enabled() then
    if FFC._modifier_vis_time then
      FFC:update_gui(time, TimerManager:main():delta_time())
    else
      FFC._workspace:hide()
    end
  end
end

FFC.Ext.GUI = GUI