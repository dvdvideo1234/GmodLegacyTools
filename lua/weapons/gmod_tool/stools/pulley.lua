local gsTool = "pulley"

TOOL.ClientConVar = {
  [ "width"      ] = 3,
  [ "forcelimit" ] = 0,
  [ "rigid"      ] = 0,
  [ "material"   ] = "cable/cable"
}

local gtConvar = TOOL:BuildConVarList()

if(CLIENT) then

  TOOL.Information = {
    { name = "info" , stage = 0, icon = "gui/info"},
    { name = "left" , stage = 0, icon = "gui/lmb.png"},
    { name = "right", stage = 0, icon = "gui/rmb.png"},
    { name = "reload"}
  }

  language.Add("tool."..gsTool..".category", "Constraints")
  language.Add("tool."..gsTool..".name","Pulley Adv")
  language.Add("tool."..gsTool..".desc", "Creates a pulley between two props across two anchor points")
  language.Add("tool."..gsTool..".0", "Select first physics prop")
  language.Add("tool."..gsTool..".1", "Select prop or world to create first anchor point")
  language.Add("tool."..gsTool..".2", "Select prop or world to create second anchor point")
  language.Add("tool."..gsTool..".3", "Select second physics prop")
  language.Add("tool."..gsTool..".left", "Create pulley between two props")
  language.Add("tool."..gsTool..".right", "What does this have to do? Seriously")
  language.Add("tool."..gsTool..".reload", "Removes pulley constraints from the trace entity")
  language.Add("tool."..gsTool..".forcelimit_con", "Force limit:")
  language.Add("tool."..gsTool..".forcelimit", "The amount of force it takes for the constraint to break. Set 0 to never break")
  language.Add("tool."..gsTool..".width_con", "Width:")
  language.Add("tool."..gsTool..".width", "Define how wide visually is the rope of the constraint")
  language.Add("tool."..gsTool..".rigid_con", "Rigid:")
  language.Add("tool."..gsTool..".rigid", "Configures the constraint as rigid bein able to push stuff")
  language.Add("tool."..gsTool..".material_con", "Material:")
  language.Add("tool."..gsTool..".material", "Use this to switch around the rope material for the constraint")
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

function TOOL:GetWidth()
  return math.Clamp(math.max(self:GetClientNumber("width", 0), 0), 0, 10)
end

function TOOL:GetForceLimit()
  return math.Clamp(self:GetClientNumber("forcelimit", 0), 0, 50000)
end

function TOOL:GetRigid()
  return (self:GetClientNumber("rigid", 0) ~= 0)
end

function TOOL:GetMaterial()
  return self:GetClientInfo("material", "")
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return true end
  if(not self:Validate(tr)) then return false end

  local user = self:GetOwner()
  local iNum = self:NumObjects()
  local trPhy = tr.Entity:GetPhysicsObjectNum(tr.PhysicsBone)
  self:SetObject(iNum + 1, tr.Entity, tr.HitPos, trPhy, tr.PhysicsBone, tr.HitNormal)

  if(iNum > 2) then
    local width      = self:GetWidth()
    local rigid      = self:GetRigid()
    local material   = self:GetMaterial()
    local forcelimit = self:GetForceLimit()

    -- Get information we're about to use
    local Ent1 = self:GetEnt(1)
    local Ent4 = self:GetEnt(4)
    local Bone1 = self:GetBone(1)
    local Bone4 = self:GetBone(4)
    local LPos1 = self:GetLocalPos(1)
    local LPos4 = self:GetLocalPos(4)
    local WPos2 = self:GetPos(2)
    local WPos3 = self:GetPos(3)

    local ePull = constraint.Pulley(Ent1, Ent4, Bone1, Bone4,
        LPos1, LPos4, WPos2, WPos3, forcelimit, rigid, width, material)

    undo.Create("Pulley")
    undo.AddEntity(ePull)
    undo.SetPlayer(user)
    undo.Finish()

    user:AddCleanup("ropeconstraints", ePull)

    self:ClearObjects()
    self:NotifyUser("Pulley created!", "GENERIC", 7)
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
  return constraint.RemoveConstraints(tr.Entity, "Pulley")
end

function TOOL:Holster(tr)
  self:ClearObjects()
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
  pItem = CPanel:NumSlider(language.GetPhrase("tool."..gsTool..".width_con"), gsTool.."_width", 0, 10, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".width"))
          pItem:SetDefaultValue(gtConvar[gsTool.."_width"])
  pItem = CPanel:CheckBox (language.GetPhrase("tool."..gsTool..".rigid_con"), gsTool.."_rigid")
          pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".rigid"))
  pItem = vgui.Create("RopeMaterial", CPanel)
          pItem:SetConVar(gsTool.."_material")
          CPanel:AddPanel(pItem)
end
