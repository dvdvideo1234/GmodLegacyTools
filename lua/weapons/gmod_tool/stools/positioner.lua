local clYell = Color(255, 255, 0)
local clGree = Color(0  , 255, 0)
local gnSize = 100000

TOOL.Category   = "Construction"
TOOL.Name       = "#Positioner"
TOOL.Command    = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
  ["x"]  = "0",
  ["y"]  = "0",
  ["z"]  = "0",
  ["freeze"] = "0"
}
if ( CLIENT ) then
  concommand.Add("positioner_cpy", function(oPly,oCom,oArgs)
    local sPos = tostring(GetConVar("positioner_x"):GetFloat() or "0")..","..
                 tostring(GetConVar("positioner_y"):GetFloat() or "0")..","..
                 tostring(GetConVar("positioner_z"):GetFloat() or "0")
    SetClipboardText(sPos)
  end)
  concommand.Add("positioner_rst", function(oPly,oCom,oArgs)
    oPly:ConCommand("positioner_x 0\n")
    oPly:ConCommand("positioner_y 0\n")
    oPly:ConCommand("positioner_z 0\n")
  end)
  language.Add("tool.positioner.name", "Positioner Tool" )
  language.Add("tool.positioner.desc", "Sets or gets the position of a prop." )
  language.Add("tool.positioner.0"   , "Left click: Set position. Right click: Get position. Reload: set yours." )
end

function TOOL:GetFreeze()
  return (tonumber(self:GetClientNumber("freeze") or 0) ~= 0)
end

function TOOL:GetVector()
  return Vector(self:GetClientNumber("x"),
                self:GetClientNumber("y"),
                self:GetClientNumber("z"))
end

function TOOL:GetView(oPly, vV, nR)
  return (200 * nR) / (vV - oPly:GetPos()):Length()
end

function TOOL:LeftClick( Trace )
  if(CLIENT) then return true end
  local trEnt = Trace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  local phEnt = trEnt:GetPhysicsObjectNum(Trace.PhysicsBone)
  local freeze = self:GetFreeze()
  if(phEnt) then
    phEnt:Sleep()
    if(freeze) then phEnt:EnableMotion(not freeze) end
    phEnt:SetPos(self:GetVector())
    phEnt:Wake()
  end
  return true
end

function TOOL:RightClick( Trace )
  if(CLIENT) then return true end
  local trEnt = Trace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  local phEnt = trEnt:GetPhysicsObjectNum(Trace.PhysicsBone)
  if(phEnt) then
    local oPly = self:GetOwner()
    local bKey = oPly:KeyDown(IN_SPEED)
    local wPos = (bKey and Trace.HitPos or phEnt:GetPos())
    oPly:ConCommand("positioner_x "..wPos.x);
    oPly:ConCommand("positioner_y "..wPos.y);
    oPly:ConCommand("positioner_z "..wPos.z);
  end
  return true
end

function TOOL:Reload( Trace )
  if(CLIENT) then return true end
  local trEnt = Trace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  local phEnt = trEnt:GetPhysicsObjectNum(Trace.PhysicsBone)
  local freeze = self:GetFreeze()
  if(phEnt) then
    phEnt:Sleep()
    if(freeze) then trEnt:EnableMotion(not freeze) end
    phEnt:SetPos(self:GetOwner():GetPos())
    phEnt:Wake()
  end
  return true
end

function TOOL:DrawHUD()
  local uiPly = LocalPlayer()
  local trEnt = uiPly:GetEyeTrace().Entity
  local uvCli = self:GetVector()
  local xyEnd = uvCli:ToScreen()
  if(trEnt and trEnt:IsValid()) then
    local uvPos = trEnt:GetPos()
    local xyPos = uvPos:ToScreen()
    surface.DrawCircle(xyPos.x, xyPos.y, self:GetView(uiPly, uvPos, 10), clGree)
    surface.SetDrawColor(clYell)
    if(xyEnd.visible) then surface.DrawLine(xyPos.x, xyPos.y, xyEnd.x, xyEnd.y) end
  end; surface.DrawCircle(xyEnd.x, xyEnd.y, self:GetView(uiPly, uvCli, 10), clYell)
end

function TOOL.BuildCPanel( CPanel )
  CPanel:SetName(language.GetPhrase("tool.positioner.name"))
  CPanel:Help   (language.GetPhrase("tool.positioner.desc"))
  CPanel:Button("COPY", "positioner_cpy"):SetToolTip("Copy position values")
  CPanel:Button("RESET","positioner_rst"):SetToolTip("Reset position convars")
  CPanel:NumSlider("X", "positioner_x", -gnSize, gnSize, 7):SetToolTip("Change X axis position")
  CPanel:NumSlider("Y", "positioner_y", -gnSize, gnSize, 7):SetToolTip("Change Y axis position")
  CPanel:NumSlider("Z", "positioner_z", -gnSize, gnSize, 7):SetToolTip("Change Z axis position")
  CPanel:CheckBox("Freeze after change", "positioner_freeze")
end
