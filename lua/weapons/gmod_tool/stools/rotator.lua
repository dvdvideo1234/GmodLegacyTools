TOOL.Category   = "Construction"
TOOL.Name       = "#Rotator"
TOOL.Command    = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
  ["p"] = "0",
  ["y"] = "0",
  ["r"] = "0"
}

if ( CLIENT ) then
  concommand.Add("rotator_cpy", function(oPly,oCom,oArgs)
    local sAng = tostring(GetConVar("rotator_p"):GetFloat() or "0")..","..
                 tostring(GetConVar("rotator_y"):GetFloat() or "0")..","..
                 tostring(GetConVar("rotator_r"):GetFloat() or "0")
    SetClipboardText(sAng)
  end)
  concommand.Add("rotator_rst", function(oPly,oCom,oArgs)
    oPly:ConCommand("rotator_p 0\n")
    oPly:ConCommand("rotator_y 0\n")
    oPly:ConCommand("rotator_r 0\n")
  end)
  language.Add("tool.rotator.name", "Rotator Tool" )
  language.Add("tool.rotator.desc", "Sets or gets the rotation of a prop." )
  language.Add("tool.rotator.0"   , "Left click: Set rotation. Right click: Get Rotation. Reload: make it zero" )
end

function TOOL:GetAngle()
  return Angle(self:GetClientNumber("p"),
               self:GetClientNumber("y"),
               self:GetClientNumber("r"))
end

function TOOL:LeftClick(stTrace)
  if(CLIENT) then return true end
  local trEnt = stTrace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  trEnt:SetAngles(self:GetAngle())
  return true
end

function TOOL:RightClick(stTrace)
  if(CLIENT) then return true end
  local trEnt = stTrace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  local aAng, oPly = trEnt:GetAngles(), self:GetOwner()
  oPly:ConCommand("rotator_p "..aAng.p);
  oPly:ConCommand("rotator_y "..aAng.y);
  oPly:ConCommand("rotator_r "..aAng.r);
  return true
end

function TOOL:Reload(stTrace)
  if(CLIENT) then return true end
  local trEnt = stTrace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  trEnt:SetAngles(Angle())
  return true
end

function TOOL:GetDist(vD, vO)
  return 0.5 * 0.68 * math.sqrt((vD.x - vO.x)^2 + (vD.y - vO.y)^2)
end

function TOOL:DrawHUD()
  local uiPly, uiLen = LocalPlayer(), 10
  local ustTr = uiPly:GetEyeTrace()
  local trEnt, uaAng, uwPos = ustTr.Entity
  if(trEnt and trEnt:IsValid()) then
    uwPos, uaAng = trEnt:GetPos(), trEnt:GetAngles()
    if(input.IsKeyDown(KEY_LSHIFT)) then uaAng:Set(self:GetAngle()) end
  else uwPos, uaAng = ustTr.HitPos, Angle() end
  local xyP  = uwPos:ToScreen()
  local xyX  = (uwPos + uiLen * uaAng:Forward()):ToScreen()
  local xyY  = (uwPos - uiLen * uaAng:Right()  ):ToScreen()
  local xyZ  = (uwPos + uiLen * uaAng:Up()     ):ToScreen()
  local xyr  = math.max(self:GetDist(xyX, xyP),
                        self:GetDist(xyY, xyP),
                        self:GetDist(xyZ, xyP))
  surface.DrawCircle(xyP.x, xyP.y, xyr, 255, 255, 0)
  surface.SetDrawColor(255,0,0)
  surface.DrawLine(xyP.x, xyP.y, xyX.x, xyX.y)
  surface.SetDrawColor(0,255,0)
  surface.DrawLine(xyP.x, xyP.y, xyY.x, xyY.y)
  surface.SetDrawColor(0,0,255)
  surface.DrawLine(xyP.x, xyP.y, xyZ.x, xyZ.y)
end

function TOOL.BuildCPanel( CPanel )
  CPanel:SetName(language.GetPhrase("tool.rotator.name"))
  CPanel:Help   (language.GetPhrase("tool.rotator.desc"))
  CPanel:Button("COPY" , "rotator_cpy"):SetToolTip("Copy angle values")
  CPanel:Button("RESET", "rotator_rst"):SetToolTip("Reset angle convars")
  CPanel:NumSlider("Pitch", "rotator_p", -360, 360, 7):SetToolTip("Change pitch orientation")
  CPanel:NumSlider("Yaw"  , "rotator_y", -360, 360, 7):SetToolTip("Change yaw orientation")
  CPanel:NumSlider("Roll" , "rotator_r", -360, 360, 7):SetToolTip("Change roll orientation`")
end
