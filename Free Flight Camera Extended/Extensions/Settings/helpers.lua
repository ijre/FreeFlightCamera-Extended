local Helpers = FFC.Ext.Settings.Helpers or class(FFC.Ext.Settings)

function Helpers:TranslateValue(range, value, onlyRetIndex)
  local ret = nil
  local size = table.size(range)

  for i = 1, size do
    if range[i] == value then
      ret = i
      break
    end
  end

  if not ret then
    table.insert(range, value, value)
    ret = value
  end

  if not onlyRetIndex then
    return range, ret
  else
    return ret
  end
end

FFC.Ext.Settings.Helpers = Helpers