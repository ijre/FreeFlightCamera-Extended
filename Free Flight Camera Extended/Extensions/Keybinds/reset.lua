-- subtract by 1 for OnGameSpeedKeybind call, as it increments the index by one
FFC._modifiers[4]._index = FFC.Ext.Settings.Helpers:TranslateValue(FFC.Ext.Settings.Ranges.GameSpeed, 1, nil, true) - 1
FFC.Ext.Binds:OnGameSpeedKeybind(true)