local Binds = class(FFC.Ext)

Binds =
{
  PreviouslyHeld = "",
  LastTime = 0
}

function Binds:GetYieldText()
  local key = self.Toggle:Key() or ""

  return string.format("Yield Control (%s Exit)", string.gsub(key, "^%l", string.upper))
end

function Binds:OnGameSpeedKeybind(inc)
  FFC.Ext.GUI:ShowModifiers()

  local prevIndex = FFC._modifier_index
  FFC._modifier_index = 4

  if inc then
    FFC:curr_modifier_up()
    self.PreviouslyHeld = self.Inc
  else
    FFC:curr_modifier_down()
    self.PreviouslyHeld = self.Dec
  end

  FFC._modifier_index = prevIndex

  self.LastTime = TimerManager:main():time()
end

function Binds:ReloadBinds(key, keyInd)
  -- BLT's get_keybind() func checks every single keybind in every single mod
    -- thus this is more efficient

  if not key then
    self.Toggle = BLT.Keybinds:get_keybind("FFC_Toggle")
    self.Inc = BLT.Keybinds:get_keybind("FFC_IncreaseSpeed")
    self.Dec = BLT.Keybinds:get_keybind("FFC_DecreaseSpeed")
  elseif keyInd == 0 then
    self.Toggle = key
  elseif keyInd == 1 then
    self.Inc = key
  else
    self.Dec = key
  end
end
Binds:ReloadBinds()

local origSetKey = BLTKeybind._SetKey
function BLTKeybind:_SetKey(id, key)
  origSetKey(self, id, key)

  if self:Id() == "FFC_Toggle" then
    Binds:ReloadBinds(self, 0)
    FFC._actions[3]._name = Binds:GetYieldText()
  elseif self:Id() == "FFC_IncreaseSpeed" then
    Binds:ReloadBinds(self, 1)
  elseif self:Id() == "FFC_DecreaseSpeed" then
    Binds:ReloadBinds(self, 2)
  end
end

local path = ModPath

function Binds:CheckHeld(time)
  if self.LastTime + 0.13 > time then
    return end

  local incHeld = self.Inc and Input:keyboard():down(Idstring(self.Inc:Key() or ""))
  local decHeld = self.Dec and Input:keyboard():down(Idstring(self.Dec:Key() or ""))

  local b = (not (incHeld and decHeld) and (incHeld and self.Inc or decHeld and self.Dec)) or nil

  if b == nil or self.PreviouslyHeld ~= b then
    goto ret end

  dofile(path .. b:File())

  self.LastTime = time

  ::ret::
  self.PreviouslyHeld = b
end

FFC.Ext.Binds = Binds