-- Axis Centre tool - by Wenli

local gsTool = "axiscentre"

TOOL.ClientConVar = {
  [ "forcelimit"  ] = 0,
  [ "torquelimit" ] = 0,
  [ "friction"    ] = 0,
  [ "nocollide"   ] = 0,
  [ "moveprop"    ] = 0,
  [ "rotsecond"   ] = 0,
  [ "pikecount"   ] = 0,
  [ "pikeiters"   ] = 100,
  [ "pikelength"  ] = 0
}

local gtConvar = TOOL:BuildConVarList()

if(CLIENT) then

  TOOL.Information = {
    { name = "info.0" , stage = 0, icon = "gui/info"},
    { name = "info.1" , stage = 1, icon = "gui/info"},
    { name = "left" , stage = 0, icon = "gui/lmb.png"},
    { name = "right", stage = 0, icon = "gui/rmb.png"},
    { name = "reload"}
  }

  language.Add("tool."..gsTool..".category", "Constraints")
  language.Add("tool."..gsTool..".name","Axis Center Adv")
  language.Add("tool."..gsTool..".desc", "Axis props by center of mass or pikes them as kebab")
  language.Add("tool."..gsTool..".info.0", "Select first prop")
  language.Add("tool."..gsTool..".info.1", "Select second prop")
  language.Add("tool."..gsTool..".left", "Create axis center between two props")
  language.Add("tool."..gsTool..".right", "Pike props behind with multiple axis")
  language.Add("tool."..gsTool..".reload", "Removes axis constraints from trace entity")
  language.Add("tool."..gsTool..".forcelimit_con", "Force limit:")
  language.Add("tool."..gsTool..".forcelimit", "The amount of force it takes for the constraint to break. Set 0 to never break")
  language.Add("tool."..gsTool..".torquelimit_con", "Torque limit:")
  language.Add("tool."..gsTool..".torquelimit", "The amount of torque it takes for the constraint to break. Set 0 to never break")
  language.Add("tool."..gsTool..".friction_con", "Rotation friction:")
  language.Add("tool."..gsTool..".friction", "Adjusts the rotation friction of the axis created")
  language.Add("tool."..gsTool..".pikelength_con", "Pike length:")
  language.Add("tool."..gsTool..".pikelength", "Adjust the trace piked props when creating axes")
  language.Add("tool."..gsTool..".pikecount_con", "Pike count:")
  language.Add("tool."..gsTool..".pikecount", "Adjust the amount of piked props when creating axes")
  language.Add("tool."..gsTool..".nocollide_con", "No-Collide" )
  language.Add("tool."..gsTool..".nocollide", "No-Collide the constrained props" )
  language.Add("tool."..gsTool..".rotsecond_con", "Second prop rotation" )
  language.Add("tool."..gsTool..".rotsecond", "Rotation direction by second prop" )
  language.Add("tool."..gsTool..".moveprop_con", "Move first prop")
  language.Add("tool."..gsTool..".moveprop", "Move first prop remember to nocollide")
  language.Add("reload."..gsTool,"Undone Advanced Axis Center")
  language.Add("undone."..gsTool,"Undone Advanced Axis Center")
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

function TOOL:GetRotatate()
  return (self:GetClientNumber("rotsecond", 0) ~= 0)
end

function TOOL:GetMoveprop()
  return (self:GetClientNumber("moveprop", 0) ~= 0)
end

function TOOL:GetNoCollide()
  return math.floor(self:GetClientNumber("nocollide", 0))
end

function TOOL:GetFriction()
  return math.Clamp(self:GetClientNumber("friction", 0), 0, 50000)
end

function TOOL:GetForceLimit()
  return math.Clamp(self:GetClientNumber("forcelimit", 0), 0, 50000)
end

function TOOL:GetTorqueLimit()
  return math.Clamp(self:GetClientNumber("torquelimit", 0), 0, 50000)
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

function TOOL:LeftClick(tr)
  if(tr.Entity:IsPlayer()) then return false end
  if(SERVER and not util.IsValidPhysicsObject(tr.Entity, tr.PhysicsBone)) then return false end

  local iNum = self:NumObjects()
  local Phys = tr.Entity:GetPhysicsObjectNum(tr.PhysicsBone)
  self:SetObject(iNum + 1, tr.Entity, tr.HitPos, Phys, tr.PhysicsBone, tr.HitNormal)

  if(iNum > 0)then
    if(CLIENT) then
      self:ClearObjects()
      return true
    end

    local user      = self:GetOwner()
    local friction    = self:GetFriction()
    local moveprop    = self:GetMoveprop()
    local rotsecond   = self:GetRotatate()
    local nocollide   = self:GetNoCollide()
    local forcelimit  = self:GetForceLimit()
    local torquelimit = self:GetTorqueLimit()

    local Ent1,  Ent2  = self:GetEnt(1)     , self:GetEnt(2)
    local WPos1, WPos2 = self:GetPos(1)     , self:GetPos(2)
    local Phys1, Phys2 = self:GetPhys(1)    , self:GetPhys(2)
    local Bone1, Bone2 = self:GetBone(1)    , self:GetBone(2)
    local Norm1, Norm2 = self:GetNormal(1)  , self:GetNormal(2)
    local LPos1, LPos2 = self:GetLocalPos(1), self:GetLocalPos(2)

    if Ent1 == Ent2 then
      self:ClearObjects()
      self:NotifyUser("Selected the same prop!", "ERROR", 7)
      return true
    end

    if(moveprop and not Ent1:IsWorld()) then
      -- Move the object so that the hitpos on our object is at the second hitpos
      local Pos = WPos2 + Phys1:GetPos() - WPos1

      Phys1:SetPos(Pos)
      Phys1:EnableMotion(false)

      -- Wake up the physics object so that the entity updates its position
      Phys1:Wake()
    end

    LPos1 = Phys1:GetMassCenter()

    if(rotsecond) then
      LPos2 = Phys2:WorldToLocal(Phys1:LocalToWorld(LPos1) + Norm1)
    else
      LPos2 = Phys2:WorldToLocal(Phys1:LocalToWorld(LPos1) + Norm2)
    end

    local axis = constraint.Axis(Ent1, Ent2, Bone1, Bone2,
      LPos1, LPos2, forcelimit, torquelimit, friction, nocollide)

    undo.Create("Axis Centre")
      undo.AddEntity(axis)
      undo.SetPlayer(user)
    undo.Finish()

    user:AddCleanup("constraints", axis)
    self:NotifyUser("Axis Center created!", "GENERIC", 7)

    Phys1:EnableMotion(false)

    self:ClearObjects()
  else
    self:SetStage(iNum + 1)
  end

  return true
end

function TOOL:Reload(tr)
  if(CLIENT) then return true end

  if(tr.HitWorld) then
    self:NotifyUser("Stage cleared!", "CLEANUP", 7)
    self:ClearObjects(); return true
  end

  if( not tr.Entity:IsValid() or
          tr.Entity:IsPlayer()) then return false end

  self:SetStage(0)
  return constraint.RemoveConstraints(tr.Entity, "Axis")
end

function TOOL:Holster(tr)
  self:ClearObjects()
end

function TOOL:GetPikeAxis(tr, norm)
  local tPike = {
    Filt = 0, Limi = false,
    Size = 0, Iter = 0,
    Span = 0, Norm = Vector()
  }

  local pikecount  = self:GetPikeCount()
  local pikelength = self:GetPikeLength()
  if(pikelength <= 0) then return tPike end

  tPike.Limi = (pikecount > 0)
  tPike.Span = pikelength
  tPike.Iter = self:GetPikeIters()

  if(norm) then
    tPike.Norm:Set(norm)
    tPike.Norm:Normalize()
  else
    tPike.Norm:Set(tr.HitNormal)
    tPike.Norm:Mul(-1)
    tPike.Norm:Normalize()
  end

  tResult = {}

  local tTrace = {
    start  = Vector(), endpos = Vector(),
    filter = {}, mask  = MASK_SOLID,
    collisiongroup = COLLISION_GROUP_NONE,
    ignoreworld = true, output = tResult
  }
  -- Put the trace entity in the ilter list
  tPike.Filt = tPike.Filt + 1
  tTrace.filter[tPike.Filt] = tr.Entity
  -- Initialize ray trace data
  tTrace.start:Set(tr.HitPos)
  tTrace.endpos:Set(tPike.Norm)
  tTrace.endpos:Mul(tPike.Span)
  tTrace.endpos:Add(tTrace.start)

  util.TraceLine(tTrace)

  while(tResult.Hit and tPike.Span > 0 and tPike.Iter > 0) do
    tPike.Iter = tPike.Iter - 1 -- Prevent infinite loops
    tPike.Span = tPike.Span - (tResult.Fraction * tPike.Span)

    if(tResult.Entity and
       tResult.Entity ~= tr.Entity and
       tResult.Entity:IsValid() and not
       tResult.Entity:IsPlayer() and
       util.IsValidPhysicsObject(tResult.Entity, tResult.PhysicsBone))
    then
      -- Apply the filter to make sure we dont hit already processed
      tPike.Filt = tPike.Filt + 1
      tTrace.filter[tPike.Filt] = tResult.Entity
      -- Copy the trace data to the kebab table
      tPike.Size = tPike.Size + 1
      tPike[tPike.Size] = {}
      tPike[tPike.Size].Ent = tResult.Entity
      tPike[tPike.Size].Pos = Vector()
      tPike[tPike.Size].Pos:Set(tResult.HitPos)
      tPike[tPike.Size].Bone = tResult.PhysicsBone
      tPike[tPike.Size].Norm = Vector()
      tPike[tPike.Size].Norm:Set(tResult.HitNormal)

      if(tPike.Limi) then
        pikecount = pikecount - 1
        if(pikecount <= 0) then break end
      end
    end

    tTrace.start:Set(tResult.HitPos)
    tTrace.endpos:Set(tPike.Norm)
    tTrace.endpos:Mul(tPike.Span)
    tTrace.endpos:Add(tTrace.start)

    util.TraceLine(tTrace)
  end

  return tPike
end

function TOOL:RightClick(tr)
  if(tr.Entity:IsPlayer()) then return false end
  if(SERVER and not util.IsValidPhysicsObject(tr.Entity, tr.PhysicsBone)) then return false end
  if(self:NumObjects() > 0) then return false end

  local user, norm = self:GetOwner()

  if(user:KeyDown(IN_SPEED)) then
    norm = user:GetAimVector()
  end

  local tPike = self:GetPikeAxis(tr, norm)

  if(not tPike) then return false end
  if(not tPike.Size) then return false end
  if(not (tPike.Size > 0)) then return false end

  local forcelimit  = self:GetForceLimit()
  local torquelimit = self:GetTorqueLimit()
  local nocollide   = self:GetNoCollide()
  local friction    = self:GetFriction()

  local Ent1  = tr.Entity
  local WPos1 = tr.HitPos
  local Norm1 = tr.HitNormal
  local Bone1 = tr.PhysicsBone
  local Phys1 = Ent1:GetPhysicsObject()
  local LPos1 = Ent1:WorldToLocal(WPos1)

  undo.Create("Axis Pike")

  for iD = 1, tPike.Size do
    local Ent2  = tPike[iD].Ent
    local WPos2 = tPike[iD].Pos
    local Norm2 = tPike[iD].Norm
    local Bone2 = tPike[iD].Bone
    local Phys2 = Ent2:GetPhysicsObject()
    local LPos2 = Ent2:WorldToLocal(WPos2)

    local axis = constraint.Axis(Ent1, Ent2, Bone1, Bone2,
      LPos1, LPos2, forcelimit, torquelimit, friction, nocollide)

    undo.AddEntity(axis)
    undo.SetPlayer(user)
    user:AddCleanup("constraints", axis)
  end

  undo.Finish()
  self:NotifyUser("Axis Pike created ["..tPike.Size.."]!", "GENERIC", 7)

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
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".torquelimit_con"), gsTool.."_torquelimit", 0, 50000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".torquelimit"))
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".friction_con"), gsTool.."_friction", 0, 10000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".friction"))
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".pikelength_con"), gsTool.."_pikelength", 0, 1000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".pikelength"))
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".pikecount_con"), gsTool.."_pikecount", 0, 50, 0)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".pikecount"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".nocollide_con"), gsTool.."_nocollide")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".nocollide"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".moveprop_con"), gsTool.."_moveprop")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".moveprop"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".rotsecond_con"), gsTool.."_rotsecond")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".rotsecond"))
end
