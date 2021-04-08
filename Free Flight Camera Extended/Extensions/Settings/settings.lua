FFC = FFC or { }
FFC.Ext = FFC.Ext or { }
FFC.Ext.Settings = FFC.Ext.Settings or { }

--#region PathSetup
local base = ModPath
-- local base = ModPath .. "Free Flight Camera Extended/"
local ext  = base .. "Extensions/"
FFC.Ext.Paths =
{
  Saves = SavePath .. "FFC_E.txt",

  Base = base,
  Ext = ext,
  Settings = ext .. "Settings/",
  Keybinds = ext .. "Keybinds/"
}
local settingsPath = FFC.Ext.Paths.Settings
local savePath = FFC.Ext.Paths.Saves
--#endregion

Hooks:Add("LocalizationManagerPostInit", "FFC_LocalizeInit", function(LM)
  LM:load_localization_file(settingsPath .. "en.txt")
end)

FFC.Ext.Settings =
{
  Defaults =
  {
    KeepHUD = false,
    MoveSpeed = 2,
    MouseSens = 3,
    FOV = 90
  },
  SavedData = { },
  Ranges =
  {
    MoveSpeed = { 0.01, 0.02, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
    MouseSens = { 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10 },
    FOV = { },
    GameSpeed = { 0.1, 0.2, 0.4, 0.6, 0.8, 1, 1.2, 1.4, 1.6, 1.8, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 10 }
  }
}
if table.empty(FFC.Ext.Settings.Ranges.FOV) then
  for i = 1, 360 do
    table.insert(FFC.Ext.Settings.Ranges.FOV, i)
  end
end

if table.empty(FFC.Ext.Settings.SavedData) then
  FFC.Ext.Settings.SavedData = FFC.Ext.Settings.Defaults
end

dofile(settingsPath .. "settingsHelpers.lua")

function FFC.Ext.Settings:Load()
  local file = io.open(savePath, "r")

  if file then
    for k, v in pairs(json.decode(file:read("*all"))) do
      self.SavedData[k] = v
    end

    file:close()
  else
    self:Save()
  end
end

function FFC.Ext.Settings:Save()
  local file = io.open(savePath, "w+")

  file:write(json.encode(self.SavedData))
  file:close()
end

Hooks:Add("MenuManagerInitialize", "FFC_MenuInit", function(MM)
  MenuCallbackHandler.FFC_OnHUD = function(self, option)
    FFC.Ext.Settings.SavedData.KeepHUD = option:value() == "on"
    FFC.Ext.Settings:Save()
  end

  MenuCallbackHandler.FFC_OnMoveSpeed = function(self, option)
    FFC.Ext.Settings.SavedData.MoveSpeed = option:value()
    FFC.Ext.Settings:Save()
  end

  MenuCallbackHandler.FFC_OnMouseSens = function(self, option)
    FFC.Ext.Settings.SavedData.MouseSens = option:value()
    FFC.Ext.Settings:Save()
  end

  MenuCallbackHandler.FFC_OnFOV = function(self, option)
    FFC.Ext.Settings.SavedData.FOV = option:value()
    FFC.Ext.Settings:Save()
  end

  FFC.Ext.Settings:Load()
  MenuHelper:LoadFromJsonFile(FFC.Ext.Paths.Settings .. "menu.txt", FFC.Ext.Settings, FFC.Ext.Settings.SavedData)
end)