local Helpers = FFC.Ext.Settings.Helpers or class(FFC.Ext.Settings)

function Helpers:SnipDecimals(val, all)
  -- you could probably call this a hack but i think it's efficient >:^)
  local valStr = all and string.format("%0.f", val) or string.format("%.2f", val)

  return tonumber(valStr)
end

function Helpers:TranslateValue(range, value, customRangeIndex, onlyRetIndex)
  local ret = nil
  local size = table.size(range)

  for i = 1, size do
    if range[i] == value then
      ret = i
      break
    end
  end

  if not ret and customRangeIndex then
    local indexVal = size

    if value < range[1] then
      indexVal = 1
    elseif value > range[size] then
      indexVal = size
    else
      for i = 1, size do
        if value > range[i] and value < range[i + 1] then
          indexVal = i + 1
          break
        end
      end
    end

    table.insert(FFC.Ext.Settings.Ranges.CustomRanges[customRangeIndex], indexVal, value)
    table.insert(range, value)

    ret = size + 1
  elseif not ret and not customRangeIndex then
    error(string.format("[Free Flight Camera Extended] ERROR: customRangeIndex was nil but value \"%s\" wasn't found!", value), 2)
  end

  if not onlyRetIndex then
    return range, ret
  else
    return ret
  end
end

function Helpers:CheckCustomValues(modifier, inc)
  local size = table.size(modifier._values)
  local customRange = FFC.Ext.Settings.Ranges.CustomRanges[FFC._modifier_index]

  local index = modifier._index
  local nextIndex = inc and index + 1 or index - 1
  local customValIndex = table.get_key(customRange, modifier._values[size])

  if index == size then
    index = inc and customValIndex or customValIndex - 1
  elseif not inc and index == customValIndex then
    index = size
  elseif nextIndex == customValIndex then
    index = inc and size or customValIndex
  elseif (inc and index == size - 1) or (not inc and index == 1) then
    -- nothing
  else
    index = nextIndex
  end

  return index
end

FFC.Ext.Settings.Helpers = Helpers