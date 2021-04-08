local GUI = class(FFC.Ext)

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