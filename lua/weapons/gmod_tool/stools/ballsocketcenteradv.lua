local gsTool = TOOL.Mode

TOOL.ClientConVar = {
  [ "forcelimit"  ] = 0,
  [ "torquelimit" ] = 0,
  [ "nocollide"   ] = 0,
  [ "moveprop"    ] = 0,
  [ "simplemode"  ] = 0,
  [ "freemove"    ] = 0,
  [ "rotateonly"  ] = 0,
  [ "xrotfric"    ] = 0,
  [ "yrotfric"    ] = 0,
  [ "zrotfric"    ] = 0,
  [ "xrotmin"     ] = -180,
  [ "yrotmin"     ] = -180,
  [ "zrotmin"     ] = -180,
  [ "xrotmax"     ] =  180,
  [ "yrotmax"     ] =  180,
  [ "zrotmax"     ] =  180
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
  language.Add("tool."..gsTool..".reload", "Removes axis constraints from the trace entity")
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
  language.Add("tool."..gsTool..".xrotmin_con", "X Rotation min:")
  language.Add("tool."..gsTool..".xrotmin", "Rotation minimum of advanced ballsocket in X axis")
  language.Add("tool."..gsTool..".xrotmax_con", "X Rotation max:")
  language.Add("tool."..gsTool..".xrotmax", "Rotation maximum of advanced ballsocket in X axis")
  language.Add("tool."..gsTool..".yrotmin_con", "Y Rotation min:")
  language.Add("tool."..gsTool..".yrotmin", "Rotation minimum of advanced ballsocket in Y axis")
  language.Add("tool."..gsTool..".yrotmax_con", "Y Rotation max:")
  language.Add("tool."..gsTool..".yrotmax", "Rotation maximum of advanced ballsocket in Y axis")
  language.Add("tool."..gsTool..".zrotmin_con", "Z Rotation min:")
  language.Add("tool."..gsTool..".zrotmin", "Rotation minimum of advanced ballsocket in Z axis")
  language.Add("tool."..gsTool..".zrotmax_con", "Z Rotation max:")
  language.Add("tool."..gsTool..".zrotmax", "Rotation maximum of advanced ballsocket in Z axis")
  language.Add("tool."..gsTool..".xrotfric_con", "X Friction:")
  language.Add("tool."..gsTool..".xrotfric", "Rotation friction of advanced ballsocket in X axis")
  language.Add("tool."..gsTool..".yrotfric_con", "Y Friction:")
  language.Add("tool."..gsTool..".yrotfric", "Rotation friction of advanced ballsocket in Y axis")
  language.Add("tool."..gsTool..".zrotfric_con", "Z Friction:")
  language.Add("tool."..gsTool..".zrotfric", "Rotation friction of advanced ballsocket in Z axis")
  language.Add("reload."..gsTool,"Undone Advanced Ballsocket Center")
  language.Add("undone."..gsTool,"Undone Advanced Ballsocket Center")
end

TOOL.Category   = language and language.GetPhrase("tool."..gsTool..".category")
TOOL.Name       = language and language.GetPhrase("tool."..gsTool..".name")
TOOL.Command    = nil
TOOL.ConfigName = nil

function TOOL:Validate(tr)
  if(not tr) then return false end
  if(not tr.Entity) then return false end
  if(tr.Entity:IsPlayer()) then return false end
  if(not util.IsValidPhysicsObject(tr.Entity, tr.PhysicsBone)) then return false end
  return true
end

function TOOL:NotifyUser(sMsg, sNot, iSiz)
  local user = self:GetOwner()
  local fmsg = "GAMEMODE:AddNotify('%s', NOTIFY_%s, %d);"
  user:SendLua(fmsg:format(sMsg, sNot, iSiz))
end

function TOOL:GetRotationFriction()
  return math.Clamp(self:GetClientNumber("xrotfric", 0), 0, 100),
         math.Clamp(self:GetClientNumber("yrotfric", 0), 0, 100),
         math.Clamp(self:GetClientNumber("zrotfric", 0), 0, 100)
end

function TOOL:GetRotationMax()
  return math.Clamp(self:GetClientNumber("xrotmax", 0), -180, 180),
         math.Clamp(self:GetClientNumber("yrotmax", 0), -180, 180),
         math.Clamp(self:GetClientNumber("zrotmax", 0), -180, 180)
end

function TOOL:GetRotationMin()
  return math.Clamp(self:GetClientNumber("xrotmin", 0), -180, 180),
         math.Clamp(self:GetClientNumber("yrotmin", 0), -180, 180),
         math.Clamp(self:GetClientNumber("zrotmin", 0), -180, 180)
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
  if(CLIENT) then return true end
  if(not self:Validate(tr)) then return false end

  local iNum = self:NumObjects()
  local oPhy = tr.Entity:GetPhysicsObjectNum(tr.PhysicsBone)
  self:SetObject(iNum + 1, tr.Entity, tr.HitPos, oPhy, tr.PhysicsBone, tr.HitNormal)

  -- Can't select world as first object
  if(iNum == 0) then
    if(tr.Entity:IsWorld()) then
      self:ClearObjects()
      self:NotifyUser("Hit prop first!", "ERROR", 7)
      return false
    end
  end

  if(iNum > 0) then
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
      self:NotifyUser("Using same prop!", "ERROR", 7)
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
        local xrotmin , yrotmin , zrotmin  = self:GetRotationMin()
        local xrotmax , yrotmax , zrotmax  = self:GetRotationMax()
        local xrotfric, yrotfric, zrotfric = self:GetRotationFriction()

        local socket = constraint.AdvBallsocket(Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, forcelimit, torquelimit,
          xrotmin, yrotmin, zrotmin, xrotmax, yrotmax, zrotmax, xrotfric, yrotfric, zrotfric, freemove, nocollide)

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

  if(not self:Validate(tr)) then return false end

  self:SetStage(0)
  constraint.RemoveConstraints(tr.Entity, "Ballsocket")
  constraint.RemoveConstraints(tr.Entity, "AdvBallsocket")
  return true
end

function TOOL:Holster(tr)
  self:ClearObjects()
end

function TOOL:RightClick(tr)
  if(CLIENT) then return true end
  if(not self:Validate(tr)) then return false end
  if(self:NumObjects() > 0) then return false end

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

    self:NotifyUser("Shaft created "..math.Round(dist, 2).."!", "GENERIC", 7)

    return true
  end

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

  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".forcelimit_con"), gsTool.."_forcelimit", 0, 50000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".forcelimit"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_forcelimit"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".torquelimit_con"), gsTool.."_torquelimit", 0, 50000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".torquelimit"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_torquelimit"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".xrotmin_con"), gsTool.."_xrotmin", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".xrotmin"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_xrotmin"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".xrotmax_con"), gsTool.."_xrotmax", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".xrotmax"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_xrotmax"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".yrotmin_con"), gsTool.."_yrotmin", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".yrotmin"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_yrotmin"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".yrotmax_con"), gsTool.."_yrotmax", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".yrotmax"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_yrotmax"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".zrotmin_con"), gsTool.."_zrotmin", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".zrotmin"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_zrotmin"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".zrotmax_con"), gsTool.."_zrotmax", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".zrotmax"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_zrotmax"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".xrotfric_con"), gsTool.."_xrotfric", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".xrotfric"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_xrotfric"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".yrotfric_con"), gsTool.."_yrotfric", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".yrotfric"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_yrotfric"])
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".zrotfric_con"), gsTool.."_zrotfric", -180, 180, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".zrotfric"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_zrotfric"])
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
