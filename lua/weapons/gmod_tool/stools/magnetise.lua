local gsItem = "magnet"
local gsLimn = gsItem.."s"
local gsTool = gsItem.."ise"
local vrMaxm = CreateConVar("sbox_max"..gsLimn, 10,
  FCVAR_NONE, "Maximum magnets created on the server", 0, 50)
local gtDisc = {
  ["phys_magnet"] = true,
  ["prop_ragdoll"] = true
}

TOOL.ClientConVar = {
  [ "strength" ] = 25000,
  [ "key"      ] = 153,
  [ "maxitems" ] = 10,
  [ "nopull"   ] = 0,
  [ "allowrot" ] = 0,
  [ "starton"  ] = 0,
  [ "toggle"   ] = 1,
  [ "frozen"   ] = 0,
  [ "material" ] = "",
  [ "model"    ] = ""
}

local gtConvar = TOOL:BuildConVarList()

cleanup.Register(gsLimn)

if(CLIENT) then

  TOOL.Information = {
    { name = "info" , stage = 0, icon = "gui/info"},
    { name = "left" , stage = 0, icon = "gui/lmb.png"},
    { name = "right", stage = 0, icon = "gui/rmb.png"},
    { name = "reload"}
  }

  language.Add("tool."..gsTool..".category", "Construction")
  language.Add("tool."..gsTool..".name", "Magnetise")
  language.Add("tool."..gsTool..".desc", "Magnetises props, of course!")
  language.Add("tool."..gsTool..".0", "Creates magnets or turns props into magnets")
  language.Add("tool."..gsTool..".left", "Turn the prop into a magnet")
  language.Add("tool."..gsTool..".right", "Spawn a magnet from cache")
  language.Add("tool."..gsTool..".reload", "Removes the magnet")
  language.Add("tool."..gsTool..".maxitems_con", "Maximum items:")
  language.Add("tool."..gsTool..".maxitems", "Maximum items the magnet can hold at the same time")
  language.Add("tool."..gsTool..".strength_con", "Strength:")
  language.Add("tool."..gsTool..".strength", "Strength of the magnet. The power to hold stuff")
  language.Add("tool."..gsTool..".starton_con", "Start on spawn")
  language.Add("tool."..gsTool..".starton", "Enables the magnet after being spawned")
  language.Add("tool."..gsTool..".toggle_con", "Toggle attraction")
  language.Add("tool."..gsTool..".toggle", "Pressing the key toggles the magnet or you have to hold the key to keep it enabled")
  language.Add("tool."..gsTool..".nopull_con", "Disable pull")
  language.Add("tool."..gsTool..".nopull", "Disallows the magnet to pull objects towards it")
  language.Add("tool."..gsTool..".allowrot_con", "Allow rotation")
  language.Add("tool."..gsTool..".allowrot", "Allows rotation of the objects attached")
  language.Add("tool."..gsTool..".frozen_con", "Freeze on start")
  language.Add("tool."..gsTool..".frozen", "Freezes the magnet on start")
  language.Add("tool."..gsTool..".key_con", "Key button:")
  language.Add("tool."..gsTool..".key", "Click to update the key enumerator for the magnet")
  language.Add("cleanup.magnet", "Magnets")
  language.Add("reload."..gsTool,"Undone magnet")
  language.Add("undone."..gsTool,"Undone magnet")
  language.Add("sboxlimit.magnet","You have hit the magnets limit!")
end

TOOL.Category   = language and language.GetPhrase("tool."..gsTool..".category")
TOOL.Name       = language and language.GetPhrase("tool."..gsTool..".name")
TOOL.Command    = nil
TOOL.ConfigName = nil

function TOOL:NotifyUser(sMsg, sNot, iSiz)
  local user = self:GetOwner()
  local fmsg = "GAMEMODE:AddNotify('%s', NOTIFY_%s, %d);"
  user:SendLua(fmsg:format(sMsg, sNot, iSiz))
end

function TOOL:GetKey()
  return math.floor(math.max(self:GetClientNumber("key", 0), 0))
end

function TOOL:GetMaxItems()
  return math.Clamp(math.floor(self:GetClientNumber("maxitems", 0)), 0, 100)
end

function TOOL:GetStrength()
  return math.Clamp(self:GetClientNumber("strength", 0), 0, 50000)
end

function TOOL:GetNoPull()
  return math.Clamp(math.ceil(self:GetClientNumber("nopull", 0)), 0, 1)
end

function TOOL:GetRotAllow()
  return math.Clamp(math.ceil(self:GetClientNumber("allowrot", 0)), 0, 1)
end

function TOOL:GetStartOn()
  return math.Clamp(math.ceil(self:GetClientNumber("starton", 0)), 0, 1)
end

function TOOL:GetToggleOn()
  return math.Clamp(math.ceil(self:GetClientNumber("toggle", 0)), 0, 1)
end

function TOOL:GetFrozen()
  return (self:GetClientNumber("frozen", 0) ~= 0)
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return true end
  if(not tr) then return false end

  local trEnt, user = tr.Entity, self:GetOwner()

  if(not user:CheckLimit(gsLimn)) then
    self:NotifyUser("Limit reached!", "ERROR", 7); return false end

  if(not (trEnt and trEnt:IsValid())) then
    self:NotifyUser("Trace invalid!", "ERROR", 7); return false end

  if(trEnt:IsPlayer()) then
    self:NotifyUser("Trace player!", "ERROR", 7); return false end

  -- If there's no physics object then we PROBABLY can't make it a magnet
  local trPhy = trEnt:GetPhysicsObject(); if(not (trPhy and trPhy:IsValid())) then
    self:NotifyUser("Physics invalid!", "ERROR", 7); return false end

  local trCls = trEnt:GetClass(); if(gtDisc[trCls]) then
    self:NotifyUser("Class disabled "..trCls.."!", "ERROR", 7); return false end

print(key)

  local key      = self:GetKey()
  local maxitems = self:GetMaxItems()
  local strength = self:GetStrength()
  local nopull   = self:GetNoPull()
  local allowrot = self:GetRotAllow()
  local starton  = self:GetStartOn()
  local toggle   = self:GetToggleOn()
  local asleep   = trPhy:IsAsleep()
  local frozen   = self:GetFrozen()

  local eMag = construct.Magnet(
        user,
        trEnt:GetPos(),
        trEnt:GetAngles(),
        trEnt:GetModel(),
        trEnt:GetMaterial(),
        key, maxitems, strength,
        nopull, allowrot, starton,
        toggle, nil, nil, frozen)

  if (eMag and eMag:IsValid())  then

    if(asleep) then
      eMag:GetPhysicsObject():Sleep() end

    DoPropSpawnedEffect(eMag)

    undo.Create("Magnet")
      undo.AddEntity(eMag)
      undo.SetPlayer(user)
    undo.Finish()

    trEnt:Remove()
    eMag:SetCreator(user)
    user:AddCount(gsLimn, eMag)
    user:AddCleanup(gsLimn, eMag)

    return true
  end
  return false
end

function TOOL:RightClick(tr)
  if(CLIENT) then return true end
  if(not tr) then return false end

  if(tr.HitWorld) then
    local trEnt, user = tr.Entity, self:GetOwner()
    local trNrm, trPos = tr.HitNormal, tr.HitPos
    local ang = trNrm:Angle(); ang.pitch = ang.pitch + 90
    local mod = self:GetClientInfo("model", "")
    local mat = self:GetClientInfo("material", "")

    if(mod == "") then
      self:NotifyUser("Model empty!", "ERROR", 7); return false end

    if(not user:CheckLimit(gsLimn)) then
      self:NotifyUser("Limit reached!", "ERROR", 7); return false end

    local key      = self:GetKey()
    local maxitems = self:GetMaxItems()
    local strength = self:GetStrength()
    local nopull   = self:GetNoPull()
    local allowrot = self:GetRotAllow()
    local starton  = self:GetStartOn()
    local toggle   = self:GetToggleOn()
    local frozen   = self:GetFrozen()

    local eMag = construct.Magnet(
          user, trPos, ang, mod, mat,
          key, maxitems, strength,
          nopull, allowrot, starton,
          toggle, nil, nil, frozen)

    if (eMag and eMag:IsValid()) then
      local pos = Vector(trNrm); pos:Mul(-eMag:OBBMins().z); pos:Add(trPos)
      local ang = trNrm:Angle(); ang.pitch = ang.pitch + 90

      DoPropSpawnedEffect(eMag)

      undo.Create("Magnet")
        undo.AddEntity(eMag)
        undo.SetPlayer(user)
      undo.Finish()

      eMag:SetPos(pos)
      eMag:SetAngles(ang)
      eMag:SetCreator(user)
      user:AddCount(gsLimn, eMag)
      user:AddCleanup(gsLimn, eMag)

      return true
    end
    return false
  else
    local user = self:GetOwner()
    user:ConCommand(gsTool.."_model "..tr.Entity:GetModel().."\n")
    user:ConCommand(gsTool.."_material "..tr.Entity:GetMaterial().."\n")
    self:NotifyUser("Settings cached!", "UNDO", 7); return true
  end
end

function TOOL:Reload(tr)
  if(CLIENT) then return true end
  if(not tr) then return false end
  if(tr.HitWorld) then return false end

  if(tr.Entity:GetClass() == "phys_magnet" and
     self:GetOwner() == tr.Entity:GetCreator())
  then tr.Entity:Remove(); return true end
  return false
end

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(CPanel) local pItem
  CPanel:ClearControls(); CPanel:DockPadding(5, 0, 5, 10)

  pItem = CPanel:SetName(language.GetPhrase("tool."..gsTool..".name"))
  pItem = CPanel:Help   (language.GetPhrase("tool."..gsTool..".desc"))

  pItem = vgui.Create("ControlPresets", CPanel)
  pItem:SetPreset(gsTool)
  pItem:AddOption("Default", gtConvar)
  for key, val in pairs(table.GetKeys(gtConvar)) do
    pItem:AddConVar(val) end
  CPanel:AddItem(pItem)

  pItem = vgui.Create("CtrlNumPad", CPanel)
  pItem:SetLabel1(language.GetPhrase("tool."..gsTool..".key_con"))
  pItem:SetConVar1(gsTool.."_key")
  pItem.NumPad1:SetTooltip(language.GetPhrase("tool."..gsTool..".key"))
  CPanel:AddPanel(pItem)

  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".maxitems_con"), gsTool.."_maxitems", 0, 100, 0)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".maxitems"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_maxitems"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".strength_con"), gsTool.."_strength", 0, 50000, 0)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".strength"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_strength"])
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".nopull_con"), gsTool.."_nopull")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".nopull"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".allowrot_con"), gsTool.."_allowrot")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".allowrot"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".starton_con"), gsTool.."_starton")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".starton"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".toggle_con"), gsTool.."_toggle")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".toggle"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".frozen_con"), gsTool.."_frozen")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".frozen"))
end
