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

function TOOL:LeftClick(stTrace)
  if(CLIENT) then return true end
  local trEnt = stTrace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  trEnt:SetAngles(Angle(self:GetClientNumber("p"),
                        self:GetClientNumber("y"),
                        self:GetClientNumber("r")))
  return true
end

function TOOL:RightClick(stTrace)
  if(CLIENT) then return true end
  local trEnt = stTrace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  local aAng = trEnt:GetAngles()
  self:GetOwner():ConCommand("rotator_p "..aAng.p);
  self:GetOwner():ConCommand("rotator_y "..aAng.y);
  self:GetOwner():ConCommand("rotator_r "..aAng.r);
  return true
end

function TOOL:Reload(stTrace)
  if(CLIENT) then return true end
  local trEnt = stTrace.Entity
  if(not (trEnt and trEnt:IsValid()) or (trEnt:IsPlayer())) then return end
  trEnt:SetAngles(Angle(0,0,0))
  return true
end

function TOOL:DrawHUD()
  local uiPly, uiLen = LocalPlayer(), 10
  local ustTr = uiPly:GetEyeTrace()
  local trEnt = ustTr.Entity
  local uaAng, uwPos
  if(trEnt and trEnt:IsValid()) then
    uwPos = trEnt:GetPos()
    uaAng = trEnt:GetAngles()
    if(input.IsKeyDown(KEY_LSHIFT)) then
      uaAng:Set(Angle(self:GetClientNumber("p"),
                      self:GetClientNumber("y"),
                      self:GetClientNumber("r"))) end
  else uwPos, uaAng = ustTr.HitPos, Angle() end
  local xyP  = uwPos:ToScreen()
  local xyX  = (uwPos + uiLen * uaAng:Forward()):ToScreen()
  local xyY  = (uwPos - uiLen * uaAng:Right()  ):ToScreen()
  local xyZ  = (uwPos + uiLen * uaAng:Up()     ):ToScreen()
  local xyx  = 0.5 * 0.68 * math.sqrt((xyX.x - xyP.x)^2 + (xyX.y - xyP.y)^2)
  local xyz  = 0.5 * 0.68 * math.sqrt((xyZ.x - xyP.x)^2 + (xyZ.y - xyP.y)^2)
  local xyr  = (xyx > xyz) and xyx or xyz
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
  CPanel:NumSlider("Pitch", "rotator_p", -360, 360, 7):SetToolTip("Adjusts orientation pitch")
  CPanel:NumSlider("Yaw"  , "rotator_y", -360, 360, 7):SetToolTip("Adjusts orientation yaw")
  CPanel:NumSlider("Roll" , "rotator_r", -360, 360, 7):SetToolTip("Adjusts orientation roll")
end
