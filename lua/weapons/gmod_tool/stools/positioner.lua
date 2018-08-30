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
    local sAng = tostring(GetConVar("positioner_x"):GetFloat() or "0")..","..
                 tostring(GetConVar("positioner_y"):GetFloat() or "0")..","..
                 tostring(GetConVar("positioner_z"):GetFloat() or "0")
    SetClipboardText(sAng)
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

function TOOL:LeftClick( Trace )
  if(CLIENT) then return true end
  local trEnt = Trace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  local phEnt = trEnt:GetPhysicsObjectNum(Trace.PhysicsBone)
  local freeze = self:GetFreeze()
  if(phEnt) then
    phEnt:Sleep()
    if(freeze) then phEnt:EnableMotion(not freeze) end
    phEnt:SetPos(Vector(self:GetClientNumber("x"),
                        self:GetClientNumber("y"),
                        self:GetClientNumber("z")))
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
    local wPos, oPly = phEnt:GetPos(), self:GetOwner()
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
  local cYel = Color(255, 255, 0)
  local xyEnd = Vector(self:GetClientNumber("x"),
                       self:GetClientNumber("y"),
                       self:GetClientNumber("z")):ToScreen()
  if(trEnt and trEnt:IsValid()) then
    local xyPos = trEnt:GetPos():ToScreen()
    surface.DrawCircle(xyPos.x, xyPos.y, 10, 0,255, 0)
    surface.SetDrawColor(cYel) 
    surface.DrawLine(xyPos.x, xyPos.y, xyEnd.x, xyEnd.y)
  end; surface.DrawCircle(xyEnd.x, xyEnd.y, 10, cYel)
end

function TOOL.BuildCPanel( CPanel )
  CPanel:SetName(language.GetPhrase("tool.positioner.name"))
  CPanel:Help   (language.GetPhrase("tool.positioner.desc"))
  CPanel:Button("COPY", "positioner_cpy"):SetToolTip("Copy angle values")
  CPanel:Button("RESET","positioner_rst"):SetToolTip("Reset angle convars")
  CPanel:NumSlider("X", "positioner_x", -100000, 100000, 7):SetToolTip("Adjusts X axis position")
  CPanel:NumSlider("Y", "positioner_y", -100000, 100000, 7):SetToolTip("Adjusts Y axis position")
  CPanel:NumSlider("Z", "positioner_z", -100000, 100000, 7):SetToolTip("Adjusts Z axis position")
  CPanel:CheckBox("Freeze after change", "positioner_freeze")
end
