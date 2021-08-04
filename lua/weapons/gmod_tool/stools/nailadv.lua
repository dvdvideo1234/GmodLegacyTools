local gsTool = TOOL.Mode

if(CLIENT) then

  TOOL.Information = {
    { name = "info" , stage = 0, icon = "gui/info"},
    { name = "left" , stage = 0, icon = "gui/lmb.png"},
    { name = "right", stage = 0, icon = "gui/rmb.png"},
    { name = "reload"}
  }

  language.Add("tool."..gsTool..".category", "Constraints")
  language.Add("tool."..gsTool..".name", "Nail Adv")
  language.Add("tool."..gsTool..".desc", "Welds two things together using a nail")
  language.Add("tool."..gsTool..".left", "Nails two thing togrther")
  language.Add("tool."..gsTool..".right", "Nails multiple things togrther")
  language.Add("tool."..gsTool..".reload", "Removes nail constraints from the trace entity")
  language.Add("tool."..gsTool..".0", "Click on a thin prop or a ragdoll that has something close behind it")
  language.Add("tool."..gsTool..".forcelimit_con", "Force limit:")
  language.Add("tool."..gsTool..".forcelimit", "The amount of force it takes for the constraint to break. Set 0 to never break")
  language.Add("tool."..gsTool..".nocollide_con", "No-Collide")
  language.Add("tool."..gsTool..".nocollide", "No-Collide the constrained props")
  language.Add("tool."..gsTool..".remonbreak_con", "Remove nailed on break")
  language.Add("tool."..gsTool..".remonbreak", "Enable this to remove the nailed entity when the constraint breaks")
  language.Add("tool."..gsTool..".pikelength_con", "Nail length:")
  language.Add("tool."..gsTool..".pikelength", "Controls how long the nail is. Longer nails can constraint further things")
  language.Add("tool."..gsTool..".pikecount_con", "Nail count:")
  language.Add("tool."..gsTool..".pikecount", "Controls the limit of how many props are constraint via nail")
end

TOOL.ClientConVar = {
  ["forcelimit"] = 0,
  ["nocollide" ] = 0,
  ["remonbreak"] = 0,
  ["pikecount" ] = 1,
  ["pikeiters" ] = 100,
  ["pikelength"] = 16
}

local gtConvar = TOOL:BuildConVarList()

TOOL.Category   = language and language.GetPhrase("tool."..gsTool..".category")
TOOL.Name       = language and language.GetPhrase("tool."..gsTool..".name")
TOOL.Command    = nil
TOOL.ConfigName = nil

function TOOL:NotifyUser(sMsg, sNot, iSiz)
  local user = self:GetOwner()
  local fmsg = "GAMEMODE:AddNotify('%s', NOTIFY_%s, %d);"
  user:SendLua(fmsg:format(sMsg, sNot, iSiz))
end

function TOOL:GetForceLimit()
  return math.Clamp(self:GetClientNumber("forcelimit", 0), 0, 50000)
end

function TOOL:GetNoCollide()
  return (math.floor(self:GetClientNumber("nocollide", 0)) ~= 0)
end

function TOOL:GetRemOnBreak()
  return (math.floor(self:GetClientNumber("remonbreak", 0)) ~= 0)
end

function TOOL:GetPikeLength()
  return math.Clamp(self:GetClientNumber("pikelength", 0), 0, 1000)
end

function TOOL:GetPikeCount()
  return math.Clamp(math.floor(self:GetClientNumber("pikecount", 0)), 0, 50)
end

function TOOL:GetPikeIters()
  return math.Clamp(math.floor(self:GetClientNumber("pikeiters", 0)), 0, 500)
end

local function MakeNail(Ent1, Ent2, Bone1, Bone2, Pos, Ang, ForLi, NoCo, ReEn)

  local cWeld = constraint.Weld(Ent1, Ent2, Bone1, Bone2, ForLi, NoCo, ReEn)

  cWeld.Type  = "Nail"
  cWeld.Pos   = Pos
  cWeld.Ang   = Ang
  cWeld.ForLi = ForLi
  cWeld.NoCo  = NoCo
  cWeld.ReEn  = ReEn

  local eNail = ents.Create("gmod_nail")

  eNail:SetPos(Ent1:LocalToWorld(Pos))
  eNail:SetAngles(Ang)
  eNail:SetParentPhysNum(Bone1)
  eNail:SetParent(Ent1)
  eNail:Spawn()
  eNail:Activate()

  cWeld:DeleteOnRemove(eNail)
  Ent1:DeleteOnRemove(eNail)
  Ent1:DeleteOnRemove(cWeld)
  Ent2:DeleteOnRemove(eNail)
  Ent2:DeleteOnRemove(cWeld)

  return cWeld, eNail
end

duplicator.RegisterConstraint("Nail", MakeNail, "Ent1", "Ent2", "Bone1", "Bone2", "Pos", "Ang", "ForLi", "NoCo", "ReEn")

cleanup.Register(gsTool.."s")

function TOOL:Validate(tr)
  if(not tr) then return false end
  if(not tr.Entity) then return false end
  if(not tr.Entity:IsValid()) then return false end
  if(tr.Entity:IsPlayer()) then return false end
  if(not util.IsValidPhysicsObject(tr.Entity, tr.PhysicsBone)) then return false end
  return true
end

function TOOL:Constraint(tTr, bOne)
  local user       = self:GetOwner()
  local uaimvec    = user:GetAimVector()
  local forcelimit = self:GetForceLimit()
  local pikeiters  = self:GetPikeIters()
  local pikelength = self:GetPikeLength()
  local nocollide  = self:GetNoCollide()
  local remonbreak = self:GetRemOnBreak()
  local pikecount  = self:GetPikeCount()
  if(bOne) then pikecount = 1 end

  local trData, trNail = {}, {}

  trData.start  = Vector(tTr.HitPos)
  trData.endpos = Vector(uaimvec)
  trData.endpos:Mul(pikelength)
  trData.endpos:Add(trData.start)
  trData.filter = {user, tTr.Entity, Size = 2}
  trData.mask   = MASK_SOLID
  trData.collisiongroup = COLLISION_GROUP_NONE
  trData.output = trNail

  util.TraceLine(trData)

  if(trNail and trNail.Hit and pikelength > 0 and pikeiters > 0) then
    undo.Create("Nail")

    while(trNail and trNail.Hit and pikelength > 0 and pikeiters > 0) do

      if(not trNail) then break end
      if(not trNail.Hit) then break end

      if(trNail.HitWorld) then trNail.Entity = game.GetWorld() end

      if(trNail.Entity and
         trNail.Entity ~= tTr.Entity and not trNail.Entity:IsPlayer() and
         util.IsValidPhysicsObject(trNail.Entity, trNail.PhysicsBone)) then
        -- Add the entity to the filter
        trData.filter.Size = trData.filter.Size + 1
        trData.filter[trData.filter.Size] = trNail.Entity

        local vOrg = Vector(uaimvec); vOrg:Mul(-1); vOrg:Add(trData.start)
        local vDir = uaimvec:Angle(); vOrg:Set(tTr.Entity:WorldToLocal(vOrg))

        local cWeld, eNail = MakeNail(tTr.Entity, trNail.Entity,
                                      tTr.PhysicsBone, trNail.PhysicsBone,
                                      vOrg, vDir, forcelimit, nocollide, remonbreak)

        if(cWeld and cWeld:IsValid()) then
          undo.AddEntity(cWeld)
          undo.AddEntity(eNail)
          undo.SetPlayer(user)

          user:AddCleanup(gsTool.."s", cWeld)
          user:AddCleanup(gsTool.."s", eNail)
        end

        if(pikecount > 0) then
          pikecount = (pikecount - 1)
          if(pikecount <= 0) then break end
        end
      end

      trData.start:Set(trNail.HitPos)
      pikelength = (trData.endpos - trData.start):Length()
      pikeiters = (pikeiters - 1) -- Prevent infinite loops
      util.TraceLine(trData) -- Ready to trace the next entity
    end

    if(trData.filter.Size > 3) then
      self:NotifyUser("Nail created "..(trData.filter.Size - 2).."!", "GENERIC", 7)
    else
      self:NotifyUser("Nail created !", "GENERIC", 7)
    end
  else
    return false
  end

  undo.Finish()
  return true
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return true end
  if(not self:Validate(tr)) then return false end
  return self:Constraint(tr, true)
end

function TOOL:RightClick(tr)
  if(CLIENT) then return true end
  if(not self:Validate(tr)) then return false end
  return self:Constraint(tr, false)
end

function TOOL:Reload(tr)
  if(CLIENT) then return true end
  if(not self:Validate(tr)) then return false end
  constraint.RemoveConstraints(tr.Entity, "Nail")
  return true
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

  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".forcelimit_con"), gsTool.."_forcelimit", 0, 50000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".forcelimit"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_forcelimit"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".pikelength_con"), gsTool.."_pikelength", 0, 1000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".pikelength"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_pikelength"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".pikecount_con"), gsTool.."_pikecount", 0, 50, 0)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".pikecount"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_pikecount"])
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".nocollide_con"), gsTool.."_nocollide")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".nocollide"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".remonbreak_con"), gsTool.."_remonbreak")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".remonbreak"))
end
