-- Ball Socket Center tool - by Wenli

local gsTool = "ballsocketcenter"

TOOL.ClientConVar = {
  [ "forcelimit"  ] = 0,
  [ "torquelimit" ] = 0,
  [ "nocollide"   ] = 0,
  [ "moveprop"    ] = 0,
  [ "simplemode"  ] = 0,
  [ "freemove"    ] = 0,
  [ "rotateonly"  ] = 0,
  [ "cxrotfric"   ] = 0,
  [ "cyrotfric"   ] = 0,
  [ "czrotfric"   ] = 0,
  [ "cxrotmin"    ] = -180,
  [ "cyrotmin"    ] = -180,
  [ "czrotmin"    ] = -180,
  [ "cxrotmax"    ] =  180,
  [ "cyrotmax"    ] =  180,
  [ "czrotmax"    ] =  180
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
  language.Add("tool."..gsTool..".name","Ball Socket Center Adv")
  language.Add("tool."..gsTool..".desc", "Ball socket props by center of mass")
  language.Add("tool."..gsTool..".info.0", "Select first prop")
  language.Add("tool."..gsTool..".info.1", "Select second prop")
  language.Add("tool."..gsTool..".left", "Create ball socket between two props")
  language.Add("tool."..gsTool..".right", "Create three ball sockets for shaft support")
  language.Add("tool."..gsTool..".reload", "Removes axis constraints from trace entity")
  language.Add("tool."..gsTool..".torquelimit_con", "Torque Limit:")
  language.Add("tool."..gsTool..".torquelimit", "The amount of torque it takes for the constraint to break. Set 0 to never break")
  language.Add("tool."..gsTool..".forcelimit_con", "Force Limit:")
  language.Add("tool."..gsTool..".forcelimit", "The amount of force it takes for the constraint to break. Set 0 to never break")
  language.Add("tool."..gsTool..".nocollide_con", "No-Collide")
  language.Add("tool."..gsTool..".nocollide", "No-Collide the constrained props")
  language.Add("tool."..gsTool..".freemove_con", "Free movement")
  language.Add("tool."..gsTool..".freemove", "Limits the rotation only. Allow props to move freely")
  language.Add("tool."..gsTool..".moveprop_con", "Move first prop")
  language.Add("tool."..gsTool..".moveprop", "Move first prop remember to nocollide")
  language.Add("tool."..gsTool..".simplemode_con", "Ignore angle limists")
  language.Add("tool."..gsTool..".simplemode", "Create a simple ballsocket with no angle limits")
  language.Add("tool."..gsTool..".rotateonly_con", "Rotation constraint")
  language.Add("tool."..gsTool..".rotateonly_dsc", "Note: The Rotation Constraint creates 3 separate X/Y/Z ball sockets to match rotation between the two constrained entities. Selecting this option overrides all other settings besides nocollide and force limit.")
  language.Add("tool."..gsTool..".rotateonly", "Creates 3 separate X/Y/Z ballsockets to match rotation between the two constrained entities")
  language.Add("tool."..gsTool..".cxrotmin_con", "X Rotation min:")
  language.Add("tool."..gsTool..".cxrotmin", "Rotation minimum of advanced ballsocket in X axis")
  language.Add("tool."..gsTool..".cxrotmax_con", "X Rotation max:")
  language.Add("tool."..gsTool..".cxrotmax", "Rotation maximum of advanced ballsocket in X axis")
  language.Add("tool."..gsTool..".cyrotmin_con", "Y Rotation min:")
  language.Add("tool."..gsTool..".cyrotmin", "Rotation minimum of advanced ballsocket in Y axis")
  language.Add("tool."..gsTool..".cyrotmax_con", "Y Rotation max:")
  language.Add("tool."..gsTool..".cyrotmax", "Rotation maximum of advanced ballsocket in Y axis")
  language.Add("tool."..gsTool..".czrotmin_con", "Z Rotation min:")
  language.Add("tool."..gsTool..".czrotmin", "Rotation minimum of advanced ballsocket in Z axis")
  language.Add("tool."..gsTool..".czrotmax_con", "Z Rotation max:")
  language.Add("tool."..gsTool..".czrotmax", "Rotation maximum of advanced ballsocket in Z axis")
  language.Add("tool."..gsTool..".cxrotfric_con", "X Friction:")
  language.Add("tool."..gsTool..".cxrotfric", "Rotation friction of advanced ballsocket in X axis")
  language.Add("tool."..gsTool..".cyrotfric_con", "Y Friction:")
  language.Add("tool."..gsTool..".cyrotfric", "Rotation friction of advanced ballsocket in Y axis")
  language.Add("tool."..gsTool..".czrotfric_con", "Z Friction:")
  language.Add("tool."..gsTool..".czrotfric", "Rotation friction of advanced ballsocket in Z axis")
  language.Add("reload."..gsTool,"Undone Advanced Ballsocket Center")
  language.Add("undone."..gsTool,"Undone Advanced Ballsocket Center")
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

function TOOL:GetRotationFriction()
  return math.Clamp(self:GetClientNumber("cxrotfric", 0), 0, 100),
         math.Clamp(self:GetClientNumber("cyrotfric", 0), 0, 100),
         math.Clamp(self:GetClientNumber("czrotfric", 0), 0, 100)
end

function TOOL:GetRotationMax()
  return math.Clamp(self:GetClientNumber("cxrotmax", 0), -180, 180),
         math.Clamp(self:GetClientNumber("cyrotmax", 0), -180, 180),
         math.Clamp(self:GetClientNumber("czrotmax", 0), -180, 180)
end

function TOOL:GetRotationMin()
  return math.Clamp(self:GetClientNumber("cxrotmin", 0), -180, 180),
         math.Clamp(self:GetClientNumber("cyrotmin", 0), -180, 180),
         math.Clamp(self:GetClientNumber("czrotmin", 0), -180, 180)
end

function TOOL:GetNoCollide()
  return math.floor(self:GetClientNumber("nocollide", 0))
end

function TOOL:GetFreeMove()
  return math.floor(self:GetClientNumber("freemove", 0))
end

function TOOL:GetRotateOnly()
  return (self:GetClientNumber("rotateonly", 0) ~= 0)
end

function TOOL:GetMoveProp()
  return (self:GetClientNumber("moveprop", 0) ~= 0)
end

function TOOL:GetSimpleMode()
  return (self:GetClientNumber("simplemode", 0) ~= 0)
end

function TOOL:GetForceLimit()
  return math.Clamp(self:GetClientNumber("forcelimit", 0), 0, 50000)
end

function TOOL:GetTorqueLimit()
  return math.Clamp(self:GetClientNumber("torquelimit", 0), 0, 50000)
end

function TOOL:LeftClick(tr)
  if(tr.Entity:IsPlayer()) then return false end
  if(SERVER and not util.IsValidPhysicsObject(tr.Entity, tr.PhysicsBone)) then return false end

  local iNum = self:NumObjects()
  local oPhy = tr.Entity:GetPhysicsObjectNum(tr.PhysicsBone)
  self:SetObject(iNum + 1, tr.Entity, tr.HitPos, oPhy, tr.PhysicsBone, tr.HitNormal)

  -- Can't select world as first object
  if(iNum == 0) then
    if tr.Entity:IsWorld() then
      self:ClearObjects()
      return false
    end
  end

  if(iNum > 0) then
    if(CLIENT) then
      self:ClearObjects()
      return true
    end

    local user        = self:GetOwner()
    local freemove    = self:GetFreeMove()
    local moveprop    = self:GetMoveProp()
    local nocollide   = self:GetNoCollide()
    local simplemode  = self:GetSimpleMode()
    local rotateonly  = self:GetRotateOnly()
    local forcelimit  = self:GetForceLimit()
    local torquelimit = self:GetTorqueLimit()

    local Ent1,  Ent2  = self:GetEnt(1), self:GetEnt(2)
    local WPos1, WPos2 = self:GetPos(1), self:GetPos(2)
    local Bone1, Bone2 = self:GetBone(1), self:GetBone(2)
    local Phys1, Phys2 = self:GetPhys(1), self:GetPhys(2)
    local LPos1, LPos2 = Phys1:GetMassCenter(), Phys2:GetMassCenter()

    if(Ent1 == Ent2) then
      self:ClearObjects()
      self:NotifyUser("Selected the same prop!", "ERROR", 7)
      return true
    end

    if(moveprop and not Ent1:IsWorld() and not Ent2:IsWorld()) then
      -- Move the object so that centers of mass overlap
      local D1 = Ent1:LocalToWorld(LPos1); D1:Sub(Ent1:GetPos())
      local D2 = Ent2:LocalToWorld(LPos2); D2:Sub(Ent2:GetPos())
      local TR = Ent2:GetPos(); TR:Add(D2); TR:Sub(D1)

      Phys1:SetPos(TR)
      Phys1:EnableMotion(false)

      -- Wake up the physics object so that the entity updates its position
      Phys1:Wake()
    end

    if(rotateonly) then
      undo.Create("Rotation Constraint")

      local BS1 = constraint.AdvBallsocket(Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0,
        torquelimit,    0, -180, -180,   0, 180, 180, 50,  0,  0, 1, nocollide)
      local BS2 = constraint.AdvBallsocket(Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0,
        torquelimit, -180,    0, -180, 180,   0, 180,  0, 50,  0, 1, nocollide)
      local BS3 = constraint.AdvBallsocket(Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0,
        torquelimit, -180, -180,    0, 180, 180,   0,  0,  0, 50, 1, nocollide)

      undo.AddEntity(BS1); user:AddCleanup("constraints", BS1)
      undo.AddEntity(BS2); user:AddCleanup("constraints", BS2)
      undo.AddEntity(BS3); user:AddCleanup("constraints", BS3)

      undo.SetPlayer(user); undo.Finish()

      self:NotifyUser("Rotation constraint created!", "GENERIC", 7)
    else
      undo.Create("Ballsocket Center")

      if(simplemode) then
        local socket = constraint.Ballsocket(Ent2, Ent1, Bone2, Bone1, LPos1, forcelimit, torquelimit, nocollide)
        undo.AddEntity(socket)
        user:AddCleanup("constraints", socket)
      else
        local cxrotmin , cyrotmin , czrotmin  = self:GetRotationMin()
        local cxrotmax , cyrotmax , czrotmax  = self:GetRotationMax()
        local cxrotfric, cyrotfric, czrotfric = self:GetRotationFriction()

        local socket = constraint.AdvBallsocket(Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, forcelimit, torquelimit,
          cxrotmin, cyrotmin, czrotmin, cxrotmax, cyrotmax, czrotmax, cxrotfric, cyrotfric, czrotfric, freemove, nocollide)

        undo.AddEntity(socket)
        user:AddCleanup("constraints", socket)
      end

      undo.SetPlayer(user); undo.Finish()

      self:NotifyUser("Ballsocket center created!", "GENERIC", 7)
    end

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

  if(not tr.Entity:IsValid() or
         tr.Entity:IsPlayer()) then return false end

  self:SetStage(0)
  constraint.RemoveConstraints(tr.Entity, "Ballsocket")
  constraint.RemoveConstraints(tr.Entity, "AdvBallsocket")
  return true
end

function TOOL:Holster(tr)
  self:ClearObjects()
end

function TOOL:RightClick(tr)
  if(tr.Entity:IsPlayer()) then return false end
  if(SERVER and not util.IsValidPhysicsObject(tr.Entity, tr.PhysicsBone)) then return false end

  local phy = tr.Entity:GetPhysicsObject()
  local cen = tr.Entity:LocalToWorld(phy:GetMassCenter())
  local min = tr.Entity:LocalToWorld(tr.Entity:OBBMins())
  local max = tr.Entity:LocalToWorld(tr.Entity:OBBMaxs())

  local dmin = Vector(min); dmin:Sub(cen)
  local dmax = Vector(max); dmax:Sub(cen)
  local dist = (math.abs(dmin:Dot(tr.HitNormal)) +
                math.abs(dmax:Dot(tr.HitNormal))) / 2

  if(dist <= 0) then
    self:NotifyUser("Shaft length invalid!", "ERROR", 7)
    return false
  end

  min:Set(tr.HitNormal); min:Mul( dist); min:Add(cen)
  max:Set(tr.HitNormal); max:Mul(-dist); max:Add(cen)

  local data = util.TraceLine({
    start  = min, endpos = max,
    filter = tr.Entity, mask  = MASK_SOLID,
    collisiongroup = COLLISION_GROUP_NONE,
    ignoreworld = true
  })

  if(data and data.Hit and data.Entity and data.Entity:IsValid()) then

    local user         = self:GetOwner()
    local nocollide    = self:GetNoCollide()
    local forcelimit   = self:GetForceLimit()
    local torquelimit  = self:GetTorqueLimit()
    local Ent1, Ent2   = tr.Entity, data.Entity
    local Bone2, Bone1 = tr.PhysicsBone, data.PhysicsBone
    local LP1 = Ent1:WorldToLocal(max)
    local LP2 = Ent1:WorldToLocal(cen)
    local LP3 = Ent1:WorldToLocal(min)

    undo.Create("Shaft Constraint")

    local BS1 = constraint.Ballsocket(Ent2, Ent1, Bone2, Bone1, LP1, forcelimit, torquelimit, nocollide)
    local BS2 = constraint.Ballsocket(Ent2, Ent1, Bone2, Bone1, LP2, forcelimit, torquelimit, nocollide)
    local BS3 = constraint.Ballsocket(Ent2, Ent1, Bone2, Bone1, LP3, forcelimit, torquelimit, nocollide)

    undo.AddEntity(BS1); user:AddCleanup("constraints", BS1)
    undo.AddEntity(BS2); user:AddCleanup("constraints", BS2)
    undo.AddEntity(BS3); user:AddCleanup("constraints", BS3)

    undo.SetPlayer(user); undo.Finish()

    self:NotifyUser("Constraint shaft ["..math.Round(dist, 2).."]!", "GENERIC", 7)
  end

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
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".torquelimit_con"), gsTool.."_torquelimit", 0, 50000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".torquelimit"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_torquelimit"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".cxrotmin_con"), gsTool.."_cxrotmin", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".cxrotmin"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_cxrotmin"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".cxrotmax_con"), gsTool.."_cxrotmax", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".cxrotmax"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_cxrotmax"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".cyrotmin_con"), gsTool.."_cyrotmin", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".cyrotmin"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_cyrotmin"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".cyrotmax_con"), gsTool.."_cyrotmax", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".cyrotmax"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_cyrotmax"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".czrotmin_con"), gsTool.."_czrotmin", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".czrotmin"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_czrotmin"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".czrotmax_con"), gsTool.."_czrotmax", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".czrotmax"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_czrotmax"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".cxrotfric_con"), gsTool.."_cxrotfric", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".cxrotfric"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_cxrotfric"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".cyrotfric_con"), gsTool.."_cyrotfric", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".cyrotfric"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_cyrotfric"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".czrotfric_con"), gsTool.."_czrotfric", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".czrotfric"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_czrotfric"])
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".nocollide_con"), gsTool.."_nocollide")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".nocollide"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".freemove_con"), gsTool.."_freemove")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".freemove"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".moveprop_con"), gsTool.."_moveprop")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".moveprop"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".simplemode_con"), gsTool.."_simplemode")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".simplemode"))
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".rotateonly_con"), gsTool.."_rotateonly")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".rotateonly"))

  CPanel:Help(language.GetPhrase("tool."..gsTool..".rotateonly_dsc"))
end
