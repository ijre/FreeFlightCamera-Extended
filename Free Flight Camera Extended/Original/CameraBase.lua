core:import("CoreFreeFlightAction")
core:import("CoreFreeFlightModifier")
FFC = FFC or { }
local FF_ON, FF_OFF, FF_ON_NOCON = 0, 1, 2
local MOVEMENT_SPEED_BASE = 1000
local FAR_RANGE_MAX = 250000
local TURN_SPEED_BASE = 1
local PITCH_LIMIT_MIN = -80
local PITCH_LIMIT_MAX = 80
local TEXT_FADE_TIME = 0.3
local TEXT_ON_SCREEN_TIME = 2
local DESELECTED = Color.white
local SELECTED = Color(0, 0.4, 1)

function FFC:init()
  self._state = FF_OFF
  self._camera_object = World:create_camera()
  self._camera_object:set_far_range(FAR_RANGE_MAX)
  self._camera_speed = 2
  self._turn_speed = 2
  self._fov = 110
  self._vp = managers.viewport:new_vp(0, 0, 1, 1, "FFC", 10)
  self._vp:set_camera(self._camera_object)
  self._camera_pos = self._camera_object:position()
  self._camera_rot = self._camera_object:rotation()
  self._con = managers.controller:create_controller("freeflight", nil, true, 10)
  self._trigger_ids = { }
  self:_setup_modifiers()
  self:_setup_actions()
  self:setup_gui()
  self._con:add_trigger("freeflight_action_toggle", callback(self, self, "action_toggle"))
  self._con:add_trigger("freeflight_action_execute", callback(self, self, "action_execute"))
  self._con:add_trigger("freeflight_quick_action_execute", callback(self, self, "quick_action_execute"))
  self._con:add_trigger("freeflight_modifier_toggle", callback(self, self, "next_modifier_toggle"))
  self._con:add_trigger("freeflight_modifier_up", callback(self, self, "curr_modifier_up"))
  self._con:add_trigger("freeflight_modifier_down", callback(self, self, "curr_modifier_down"))
end

function FFC:setup_gui()
  local gui_scene = Overlay:gui()
  self._workspace = gui_scene:create_screen_workspace()
  self._workspace:set_timer(TimerManager:main())
  self._panel = self._workspace:panel()
  local TEXT_HEIGHT_OFFSET = 28
  local config =
  {
    x = 2,
    y = 2,
    font = tweak_data.menu.pd2_medium_font,
    color = DESELECTED,
  }
  local function anim_fade_out_func(o)
    CoreEvent.over(TEXT_FADE_TIME, function(t)
      o:set_alpha(1 - t)
    end)
  end
  local function anim_fade_in_func(o)
    CoreEvent.over(TEXT_FADE_TIME, function(t)
      o:set_alpha(t)
    end)
  end
  local text_script = { fade_out = anim_fade_out_func, fade_in = anim_fade_in_func }
  self._action_gui = { }
  self._action_vis_time = nil
  for i, a in ipairs(self._actions) do
    local panel = self._panel:panel(
    {
      x = 45,
      y = 25,
      layer = 1000000,
    })
    local text = panel:text(config)

    panel:rect(
    {
      color = Color.black,
      alpha = 0.4
    })
    panel:set_script(text_script)
    text:set_text(a:name())
    local _,_,w,h = text:text_rect()
    panel:set_size(w + 2, h + 2)
    panel:set_y(panel:y() + i * TEXT_HEIGHT_OFFSET)
    if i == self._action_index then
      text:set_color(SELECTED)
    end
    table.insert(self._action_gui, panel)
  end
  self._modifier_gui = { }
  self._modifier_vis_time = nil
  for i, m in ipairs(self._modifiers) do
    local panel = self._panel:panel(
    {
      x = 45,
      y = 25,
      layer = 1000000,
    })
    local text = panel:text(config)

    panel:rect(
    {
      color = Color.black,
      alpha = 0.4
    })
    panel:set_script(text_script)
    text:set_text(m:name_value())
    panel:set_y(text:y() + i * TEXT_HEIGHT_OFFSET)
    local _,_,w,h = text:text_rect()
    panel:set_size(w + 2, h + 2)
    panel:set_world_right(self._panel:world_right() - 45)
    if i == self._modifier_index then
      text:set_color(SELECTED)
    end
    table.insert(self._modifier_gui, panel)
  end
  self._workspace:hide()
end

function FFC:_setup_modifiers()
  local FFM = CoreFreeFlightModifier.FreeFlightModifier
  local ranges = self.Ext.Settings.Ranges
  local saveData = self.Ext.Settings.SavedData

  local moveRange, moveNum = self.Ext.Settings.Helpers:TranslateValue(ranges.MoveSpeed, saveData.MoveSpeed)
  local sensRange, sensNum = self.Ext.Settings.Helpers:TranslateValue(ranges.MouseSens, saveData.MouseSens)
  local speedRange, speedNum = self.Ext.Settings.Helpers:TranslateValue(ranges.GameSpeed, 1)
  local fovRange, fovNum = self.Ext.Settings.Helpers:TranslateValue(ranges.FOV, saveData.FOV)

  local ms = FFM:new("Move Speed", moveRange, moveNum)
  local ts = FFM:new("Mouse Sens", sensRange, sensNum)
  local gt = FFM:new("Game Speed", speedRange, speedNum, callback(self, self, "set_game_speed"))
  local fov = FFM:new("FOV", fovRange, fovNum, callback(self, self, "set_fov"))

  self._modifiers = {ms,ts,gt,fov}
  self._modifier_index = 1
  self._fov = fov
  self._move_speed = ms
  self._turn_speed = ts
end

function FFC:_setup_actions()
  local FFA = CoreFreeFlightAction.FreeFlightAction
  local FFAT = CoreFreeFlightAction.FreeFlightActionToggle

  local ps = FFAT:new("Pause", "Unpause", callback(self, self, "pause_game"), callback(self, self, "unpause_game"))
  local dp = FFA:new("Drop Player", callback(self, self, "drop_player"))
  local yc = FFA:new(self.Ext.Binds:GetYieldText(), callback(self, self, "yield_control"))
  local ef = FFA:new("Close", callback(self, self, "disable"))

  self._actions = {ps,dp,yc,ef}
  self._action_index = 1
end

function FFC:drop_player()
  local rot_new = Rotation(self._camera_rot:yaw(), 0, 0)
  game_state_machine:current_state():freeflight_drop_player(self._camera_pos, rot_new)
end

function FFC:yield_control()
  assert(self._state == FF_ON)
  self._state = FF_ON_NOCON
  self._con:disable()
end

function FFC:set_fov(value)
  self._camera_object:set_fov(value)
end

function FFC:set_game_speed(value)
  TimerManager:pausable():set_multiplier(value)
  TimerManager:game_animation():set_multiplier(value)
end

function FFC:set_camera_speed(value)
  self._camera_speed = value
end

function FFC:pause_game()
  Application:set_pause(true)
end

function FFC:quick_action_execute()
  self:draw_actions()
  self:current_action():do_action()
end

function FFC:next_modifier_toggle()
  if self:modifiers_are_visible() then
    self._modifier_gui[self._modifier_index]:child(0):set_color(DESELECTED)
    self._modifier_index = self._modifier_index % #self._modifiers + 1
    self._modifier_gui[self._modifier_index]:child(0):set_color(SELECTED)
  end
  self:draw_modifiers()
end

function FFC:curr_modifier_up()
  self:current_modifier():step_up()
  self._modifier_gui[self._modifier_index]:child(0):set_text(self:current_modifier():name_value())
  local _,_,w,h = self._modifier_gui[self._modifier_index]:child(0):text_rect()
  self._modifier_gui[self._modifier_index]:set_size(w + 2, h + 2)
  self._modifier_gui[self._modifier_index]:set_world_right(self._panel:world_right() - 45)

  self:draw_modifiers()
end

function FFC:curr_modifier_down()
  self:current_modifier():step_down()
  self._modifier_gui[self._modifier_index]:child(0):set_text(self:current_modifier():name_value())
  local _,_,w,h = self._modifier_gui[self._modifier_index]:child(0):text_rect()
  self._modifier_gui[self._modifier_index]:set_size(w + 2,h + 2)
  self._modifier_gui[self._modifier_index]:set_world_right(self._panel:world_right() - 45)

  self:draw_modifiers()
end

function FFC:modifiers_are_visible()
  local t = TimerManager:main():time()
  return self._modifier_vis_time and t + TEXT_FADE_TIME < self._modifier_vis_time
end

function FFC:unpause_game()
  Application:set_pause(false)
end

function FFC:draw_actions()
  if not self:actions_are_visible() then
    for i, panel in ipairs(self._action_gui) do
      local text = panel:child(0)
      text:stop()
      panel:animate(panel:script().fade_in)
    end
  end
  for i, _ in ipairs(self._actions) do
    self._action_gui[i]:child(0):set_text(self._actions[i]:name())
    local _,_,w,h = self._action_gui[i]:child(0):text_rect()
    self._action_gui[i]:set_size(w + 2,h + 2)
  end
  self._action_vis_time = TimerManager:main():time() + TEXT_ON_SCREEN_TIME
end

function FFC:draw_modifiers()
  if not self:modifiers_are_visible() then
    for _, panel in ipairs(self._modifier_gui) do
      local text = panel:child(0)
      text:stop()
      panel:animate(panel:script().fade_in)
    end
  end
  self._modifier_vis_time = TimerManager:main():time() + TEXT_ON_SCREEN_TIME
end

function FFC:actions_are_visible()
  local t = TimerManager:main():time()
  return self._action_vis_time and t + TEXT_FADE_TIME < self._action_vis_time
end

function FFC:action_toggle()
  if self:actions_are_visible() then
    self._action_gui[self._action_index]:child(0):set_color(DESELECTED)
    self._action_index = self._action_index % #self._actions + 1
    self._action_gui[self._action_index]:child(0):set_color(SELECTED)
  end
  self:draw_actions()
end

function FFC:action_execute()
  self:draw_actions()
  self:current_action():do_action()
end

function FFC:show_key_pressed()
  if self._state == FF_ON then
    self:disable()
  elseif self._state == FF_OFF then
    self:enable()
  elseif self._state == FF_ON_NOCON then
    self._state = FF_ON
    self._con:enable()
  end
end

function FFC:current_action()
  return self._actions[self._action_index]
end

function FFC:enable()
  local active_vp = managers.viewport:first_active_viewport()
  if active_vp then
    self._start_cam = active_vp:camera()
    if self._start_cam then
      local pos = self._start_cam:position() - (alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3())
      self:set_camera(pos, self._start_cam:rotation())
    end
  end
  self._state = FF_ON
  self._vp:set_active(true)
  self:set_fov(self._fov:value())
  self._con:enable()
  self._workspace:show()
  self:draw_actions()
  self:draw_modifiers()
  if managers.hud and not self.Ext.Settings.SavedData.KeepHUD then
    managers.hud:set_disabled()
  end
end

function FFC:disable()
  for _, id in pairs(self._trigger_ids) do
    Input:mouse():remove_trigger(id)
  end
  Application:set_pause(false)
  self._state = FF_OFF
  self._con:disable()
  self._workspace:hide()
  self._vp:set_active(false)
  if type(managers.enemy) == "table" then
    managers.enemy:set_gfx_lod_enabled(true)
  end
  if managers.hud then
    managers.hud:set_enabled()
  end
end

function FFC:set_camera(pos, rot)
  if pos then
    self._camera_object:set_position((alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3()) + pos)
    self._camera_pos = pos
  end
  if rot then
    self._camera_object:set_rotation(rot)
    self._camera_rot = rot
  end
end

function FFC:current_modifier()
  return self._modifiers[self._modifier_index]
end

function FFC:paused_update(t, dt)
  self:update(t, dt)
end

function FFC:update_gui(t, dt)
  if self._action_vis_time and t > self._action_vis_time then
    for _, panel in ipairs(self._action_gui) do
      local text = panel:child(0)
      text:stop()
      panel:animate(panel:script().fade_out)
    end
    self._action_vis_time = nil
  end
  if self._modifier_vis_time and t > self._modifier_vis_time then
    for _, panel in ipairs(self._modifier_gui) do
      local text = panel:child(0)
      text:stop()
      panel:animate(panel:script().fade_out)
    end
    self._modifier_vis_time = nil
  end
end

function FFC:update_camera(t, dt)
  local axis_move = self._con:get_input_axis("freeflight_axis_move")
  local axis_look = self._con:get_input_axis("freeflight_axis_look")
  local btn_move_up = self._con:get_input_float("freeflight_move_up")
  local btn_move_down = self._con:get_input_float("freeflight_move_down")
  local move_dir = self._camera_rot:x() * axis_move.x + self._camera_rot:y() * axis_move.y
  move_dir = move_dir + btn_move_up * Vector3(0, 0, 1) + btn_move_down * Vector3(0, 0, -1)
  local move_delta = move_dir * self._move_speed:value() * MOVEMENT_SPEED_BASE * dt
  local pos_new = self._camera_pos + move_delta
  local yaw_new = self._camera_rot:yaw() + axis_look.x * -1 * self._turn_speed:value() * TURN_SPEED_BASE
---@diagnostic disable-next-line: undefined-field
  local pitch_new = math.clamp(self._camera_rot:pitch() + axis_look.y * self._turn_speed:value() * TURN_SPEED_BASE, PITCH_LIMIT_MIN, PITCH_LIMIT_MAX)
  local rot_new = Rotation(yaw_new, pitch_new, 0)
  if not CoreApp.arg_supplied("-vpslave") then
    self:set_camera(pos_new, rot_new)
  end
end

function FFC:update(t, dt)
  local main_t = TimerManager:main():time()
  local main_dt = TimerManager:main():delta_time()
  if self:enabled()  then
    self:update_gui(main_t, main_dt)
    self:update_camera(main_t, main_dt)
  end
end

function FFC:enabled()
  return self._state ~= FF_OFF
end

Hooks:PostHook(GameSetup, "paused_update", "paused_update_for_camera", function(self, t, dt)
  FFC:update(t, dt)
end)

Hooks:PostHook(GameSetup, "update", "update_for_camera", function(self, t, dt)
  FFC:update(t, dt)
end)

Hooks:PostHook(GameSetup, "init_managers", "init_managers_for_camera", function(self, t, dt)
  FFC:init()
end)