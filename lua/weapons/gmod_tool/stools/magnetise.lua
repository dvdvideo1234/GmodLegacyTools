TOOL.Category   = "Construction"
TOOL.Name       = "#Magnetise"
TOOL.Command    = nil
TOOL.ConfigName = nil

TOOL.ClientConVar = {
  [ "key" ]        = "153",
  [ "maxobjects" ] = "0",
  [ "strength" ]   = "25000",
  [ "nopull" ]     = "0",
  [ "allowrot" ]   = "0",
  [ "starton" ]    = "0",
  [ "toggle" ]     = "1"
}

cleanup.Register( "magnet" )

if ( CLIENT ) then
  language.Add("tool.magnetise.name", "Magnetise")
  language.Add("tool.magnetise.desc", "Magnetises props, of course!")
  language.Add("tool.magnetise.0", "Left click to magnetise a prop, right click to attach a magnet")
  language.Add("tool.magnetise.maxobjects", "Max objects magnet can hold")
  language.Add("tool.magnetise.strength", "Strength of the magnet")
  language.Add("tool.magnetise.starton", "Enabled from spawn")
  language.Add("tool.magnetise.toggle", "Pressing the key toggles the magnet")
  language.Add("tool.magnetise.nopull", "Disallows the magnet to pull objects towards it")
  language.Add("tool.magnetise.allowrot", "Allows rotation of the objects attached")
  language.Add("tool.magnetise.key", "Key button:")
  language.Add( "Cleanup_magnet", "Magnets" )
end

function TOOL:LeftClick( trace )
  if ( CLIENT ) then return true end  

  if( not trace) then return false end
  local   trEnt = trace.Entity

  if( not trEnt
   or not trEnt:IsValid()
   or     trEnt:IsPlayer())
  then return false end

  trPhys = trEnt:GetPhysicsObject()
  -- If there's no physics object then we PROBABLY can't make it a magnet
  if ( SERVER and not trPhys:IsValid() )
  then return false end

  if (trEnt:GetClass() == "phys_magnet"
   or trEnt:GetClass() == "prop_ragdoll")
  then return false end
  
  local key        = self:GetClientNumber( "key" ) 
  local maxobjects = self:GetClientNumber( "maxobjects" ) or 1
  local strength   = self:GetClientNumber( "strength" ) or 1
  local nopull     = self:GetClientNumber( "nopull" ) or 0
  local allowrot   = self:GetClientNumber( "allowrot" ) or 1
  local starton    = self:GetClientNumber( "starton" ) or 1
  local toggle     = self:GetClientNumber( "toggle" ) or 0
  local ply        = self:GetOwner()
  print("Cl Info key: ".. tostring(key))
  local eMagnet = construct.Magnet(
        ply, 
        trEnt:GetPos(), 
        trEnt:GetAngles(), 
        trEnt:GetModel(), 
        trEnt:GetMaterial(), 
        key, maxobjects, strength, 
        nopull, allowrot, starton, 
        toggle)
        
  if (eMagnet and eMagnet:IsValid())  then
    print("Magnet Valid")
    local isAsleep = trPhys:IsAsleep()
    trEnt:Remove()
    
    DoPropSpawnedEffect( eMagnet )
    
    undo.Create("Magnet")
      undo.AddEntity( eMagnet )
      undo.SetPlayer( ply )
    undo.Finish()
        
    ply:AddCleanup( "magnet", eMagnet )

    if (isAsleep) then
      eMagnet:GetPhysicsObject():Sleep()
    end
    return true
  end
  return false
end

function TOOL:RightClick( trace )
  return false    
end

function TOOL.BuildCPanel( pPanel )
  pPanel:AddControl( "Slider",  {
      Label   = "#tool.magnetise.maxobjects",
      Type    = "Integer",
      Min     = 1,
      Max     = 50,
      Command = "magnetise_maxobjects",
      Description = "Max Objects that magnet can hold."} )
      
  pPanel:AddControl( "Numpad", {
      Label = "#tool.magnetise.key",
      Command = "magnetise_key",
      Buttonsize = "22" } )
      
  pPanel:AddControl( "Slider",  {
      Label   = "#tool.magnetise.strength",
      Type    = "Float",
      Min     = 1,
      Max     = 50000,
      Command = "magnetise_strength",
      Description = "Strength of the magnet."}   )
  
  pPanel:AddControl("CheckBox", {
     Label       = "#tool.magnetise.nopull",
     Description = "Pull props",
     Command = "magnetise_nopull"})
     
  pPanel:AddControl("CheckBox", {
     Label       = "#tool.magnetise.allowrot",
     Description = "Allow rotation",
     Command = "magnetise_allowrot"})
     
  pPanel:AddControl("CheckBox", {
     Label       = "#tool.magnetise.starton",
     Description = "Start On",
     Command = "magnetise_starton"})
     
  pPanel:AddControl("CheckBox", {
     Label       = "#tool.magnetise.toggle",
     Description = "Toggle",
     Command = "magnetise_toggle"})
end




