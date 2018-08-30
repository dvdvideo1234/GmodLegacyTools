
TOOL.Category   = "Entities"
TOOL.Name       = "STOOL Turret"
TOOL.Command    = nil
TOOL.ConfigName = ""

--The tool table on the swep that created this object
local Tools = SWEP.Tool


--Begin Config: Admins edit this line

--StoolTurretBlacklist = {}

StoolTurretBlacklist = {}

--End config


cleanup.Register( "Stool Turrets" )

if ( CLIENT ) then
    language.Add( "Tool.stool_turret.name", "Stool Turret" )
    language.Add( "Tool.stool_turret.desc", "Spawns TOOL turret. With the selected tools current settings" )
    language.Add( "Tool.stool_turret.0", "Primary: Create stool turret, Secondary: Update" )
  

  language.Add( "sboxlimit.stool_turret", "You've hit stool turret limit!" )
  language.Add( "Undone.Stool Turret", "Undone Stool Turret" )
  
end

TOOL.ClientConVar[ "model" ] = "models/weapons/w_physics.mdl"
TOOL.ClientConVar[ "mode" ] = "ignite"


TOOL.ClientConVar[ "delay" ] = "0"
TOOL.ClientConVar[ "range" ] = "300"
TOOL.ClientConVar[ "sequencer" ] = "0"
TOOL.ClientConVar[ "isolation" ] = "0"

TOOL.ClientConVar[ "key_left" ]   = ""
TOOL.ClientConVar[ "key_right" ]   = ""
TOOL.ClientConVar[ "key_reload" ]   = ""



function TOOL:RightClick( trace )
  if !trace.Entity then return false end
  if !(trace.Entity:GetClass() == "stool_turret") then return false end

  local mode = self:GetClientInfo( "mode" )
  
  if !self:GetSWEP().Tool[mode] then
    ply:PrintMessage(HUD_PRINTCENTER,"Tool Invalid")
    return false
  end
  
  if !AllowTool(mode) then
    ply:PrintMessage(HUD_PRINTCENTER,"That tool is disabled for Turret use")
    return false
  end

  local mode = self:GetClientInfo( "mode" )
  local model = self:GetClientInfo( "model" )
  local Isolated = self:GetClientNumber( "isolation" )
  
  local delay = self:GetClientNumber( "delay" )
  local range = self:GetClientNumber( "range" )
  local ply = self:GetOwner()
  
  local ent = trace.Entity

  ent.Mode = mode
  ent.Delay = delay
  ent.Range = range
  ent:SetNWInt("range",range)
  ent.Isolated = Isolated


  ent.Tool = nil
  --Find all the ConVars for this tool
  local Vers = {}
  for k,v in pairs(Tools[mode].ClientConVar) do
    local key = mode .. "_" .. k
    local value = ply:GetInfo(key)
    Vers[k] = value
  end
  ent.Vers = Vers
  ent:Update()
  
  return true
end

function TOOL:LeftClick( trace )

  if (SERVER) then 
    
    local ply = self:GetOwner()

    local mode = self:GetClientInfo( "mode" )
    
    if !Tools[mode] then
      ply:PrintMessage(HUD_PRINTCENTER,"Tool Invalid")
      return false
    end
    
    if !AllowTool(mode) then
      ply:PrintMessage(HUD_PRINTCENTER,"That tool is disabled for Turret use")
      return false
    end
    
    local sequencer = self:GetClientNumber( "sequencer" )
    local Isolated = self:GetClientNumber( "isolation" )
    local delay = self:GetClientNumber( "delay" )
    local range = self:GetClientNumber( "range" )
    
    local mode = self:GetClientInfo( "mode" )
    local model = self:GetClientInfo( "model" )
    
    if sequencer > 0 then
      ply:ConCommand("stool_turret_delay " .. tostring(delay + 0.1) .. "\n")
    end
    
    local Vars = {}
    
    for k,v in pairs(Tools[mode].ClientConVar) do
      local key = mode .. "_" .. k
      local value = ply:GetInfo(key)
      Vars[k] = value
    end
    
    local key_left = self:GetClientNumber( "key_left" )
    local key_right = self:GetClientNumber( "key_right" )
    local key_reload = self:GetClientNumber( "key_reload" )
    
    ent = MakeStoolTurret(ply, trace.StartPos, ply:GetAngles(), mode, ply, delay, range, model, Vars, Isolated, key_left, key_right, key_reload)
    

    
    undo.Create("Stool Turret")
      undo.AddEntity( ent )
      undo.SetPlayer( ply )
    undo.Finish()
    
    ply:AddCleanup( "Stool Turrets", ent )
    
    
    return true
    
  end
end




function AllowTool(name)
  if name == "" then return false end
  
  for i,rule in ipairs(StoolTurretBlacklist) do
    if (string.find(name,rule) ~= nil) then return false end
  end
  
  return true
end

function TOOL.BuildCPanel(panel)
  panel:AddControl("Header", { Text = "Tool Turret", Description = "Choose the settings for the turret by switching the tool you want to use an seting them up in its dialog and then coming back here" })

  local Actions = {
    Label = "Tool modes",
    MenuButton = "0",
    Height = 180,
    Options = {}
  }
  
  for toolname,tool in pairs(Tools) do
    local name = string.gsub(tool.Name or toolname,   '#','') 
    local cat =  string.gsub(tool.Category or "No Category",   '#','') 
    
    
    if AllowTool(toolname) then
      Actions.Options[cat .. ": " .. name] = { stool_turret_mode = toolname }
    end
  end

  panel:AddControl("ListBox", Actions)
  
  panel:AddControl("Slider", {
    Label = "Add Delay",
    Type = "Float",
    Min = "0",
    Max = "5",
    Command = "stool_turret_delay"
  })
  
  panel:AddControl("CheckBox", {
    Label = "Sequencing mode",
    Description = "Checking this will increment the delay by 0.1 each time you create a turret",
    Command = "stool_turret_sequencer" 
  })
  
  panel:AddControl("CheckBox", {
    Label = "Isolation mode",
    Description = "Checking this will make the turret's stool functions act alone", --khm: Probably a really bad description but can't think of a better one at the moment
    Command = "stool_turret_isolation" 
  })
  
  
  panel:AddControl("Slider", {
    Label = "Range",
    Type = "Int",
    Min = "10",
    Max = "500",
    Command = "stool_turret_range"
  })
  
  --[[
  panel:AddControl("Textbox", {
      Label = "Model",
      Command = "stool_turret_model",
      Type="String"
  })
  ]]--
  
  panel:AddControl( "PropSelect", { Label = "Model",
            ConVar = "stool_turret_model",
            Category = "Buttons",
            Models = list.Get( "StoolTurretModels" ) } )
  
  panel:AddControl("Header", { Text = "Keys", Description = "Which keys to use to activate the tool, leave these unchecked to use wire inputs" })

  panel:AddControl("Numpad", {
    Label = "Left Click Action",
    Command = "stool_turret_key_left",
    ButtonSize = "22"
  })
  
  panel:AddControl("Numpad", {
    Label = "Right Click Action",
    Command = "stool_turret_key_right",
    ButtonSize = "22"
  })
  
  panel:AddControl("Numpad", {
    Label = "Reload Action",
    Command = "stool_turret_key_reload",
    ButtonSize = "22"
  })
  
end

 
function MakeStoolTurret(ply, Pos, Angle, Mode, Owner, Delay, Range, Model, Vars, Isolated, key_left, key_right, key_reload)
  local ent = ents.Create("stool_turret")
  
  ent:SetPos(Pos)
  ent:SetAngles(Angle)
  
  
  ent.Mode = Mode
  ent.Owner = Owner
  ent.Delay = Delay
  ent.Range = Range
  ent:SetNWInt("range",Range)
  ent.Model = Model
  ent.Isolated = Isolated or 0
  
  ent.key_left =key_left
  ent.key_right=key_right
  ent.key_reload=key_reload
  
  numpad.OnDown( ply, key_left, "StoolTurret_Left",   ent)
  numpad.OnDown( ply, key_right, "StoolTurret_Right",   ent )
  numpad.OnDown( ply, key_reload, "StoolTurret_Reload",   ent )

  
  ent.Vars = Vars
  
  ent:Spawn()
  
  return ent
end

duplicator.RegisterEntityClass( "stool_turret", MakeStoolTurret, "Pos", "Angle", "Mode", "Owner", "Delay", "Range", "Model", "Vars", "Isolated", "key_left", "key_right", "key_reload") 
 

list.Set( "StoolTurretModels", "models/weapons/w_physics.mdl", {} )
list.Set( "StoolTurretModels", "models/weapons/w_pistol.mdl", {} )
list.Set( "StoolTurretModels", "models/weapons/AR2_Grenade.mdl", {} )
