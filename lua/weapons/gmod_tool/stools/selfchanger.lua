
TOOL.Category   = "GUI Panels"
TOOL.Name       = "Self changer"
TOOL.Command    = nil
TOOL.ConfigName = ""

TOOL.ClientConVar =
{
	["widvariable"] = "",
	["widvalue"]    = "",
	["widvaluenum"] = "0"
}

local function playerNotify(var, val, set, ply)
	local msg = "["..tostring(var).."] = <"..tostring(val)..">{"..tostring(set).."}"
	if(SERVER) then
		if(ply and ply:IsValid()) then
			ply:SendLua("GAMEMODE:AddNotify(\"Server: "..msg.."\", NOTIFY_GENERIC, 6)")
		  ply:SendLua("surface.PlaySound(\"ambient/water/drip\"..math.random(1, 4)..\".wav\")")
		end
	else
		GAMEMODE:AddNotify("Client: "..msg, NOTIFY_GENERIC, 6)
		surface.PlaySound("ambient/water/drip"..math.random(1, 4)..".wav")
	end
end

if ( CLIENT ) then
	language.Add( "tool.selfchanger.name", "Developer Tool" )
	language.Add( "tool.selfchanger.desc", "Changes self....." )
	language.Add( "tool.selfchanger.0", "Primary: Set self value, Secondary: reload draw parameters" )
	language.Add( "tool.selfchanger.widvariable", "Variable:")
  language.Add( "tool.selfchanger.widvariable_con", "Enter variable name here")
	language.Add( "tool.selfchanger.widvalue", "Value:")
  language.Add( "tool.selfchanger.widvalue_con", "Enter value name here")
	language.Add( "tool.selfchanger.widvaluenum", "Force value number conversion" )
  language.Add( "tool.selfchanger.widvaluenum_con", "Check this for force converting the value to a number" )

	function setEntitySetting()
		local ent = net.ReadEntity()
		local var = net.ReadString()
		local val = net.ReadString()
		local bnv = net.ReadBool()

		if(bnv) then
			ent[var] = (tonumber(val) or 0)
		else
			ent[var] = (tostring(val) or "")
		end

		playerNotify(var, val, (ent and ent[var] or "N/A"))
	end

	net.Receive("selfchangerSetEntitySetting", setEntitySetting)
end

if( SERVER ) then
	util.AddNetworkString("selfchangerSetEntitySetting")
end

function TOOL:sendSetVal(ent, var, val)
	local bnv = (self:GetClientNumber("widvaluenum") ~= 0)

	if(bnv) then
		ent[var] = (tonumber(val) or 0)
	else
		ent[var] = (tostring(val) or "")
	end

	playerNotify(var, val, (ent and ent[var] or "N/A"), self:GetOwner())

	net.Start("selfchangerSetEntitySetting")
		net.WriteEntity(ent)
		net.WriteString(var)
		net.WriteString(val)
		net.WriteBool(bnv)
	net.Broadcast()
end

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local widValue    = self:GetClientInfo("widvalue")
	local widVariable = self:GetClientInfo("widvariable")

	--if (trace.Entity:IsValid() && trace.Entity.guiPanelVersion && trace.Entity.pl == ply) then
	--trace.Entity[widVariable] = widValue
	self:sendSetVal(trace.Entity, widVariable, widValue)

	return true
end

function TOOL:RightClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	--if (CLIENT) then return true end
	if (SERVER) then return true end

	--local themeName = self:GetClientInfo("themename")

	--if (trace.Entity:IsValid() && trace.Entity.guiPanelVersion && trace.Entity.pl == ply) then
		--trace.Entity:SetPanelScheme(themeName)
		--return true
	--end
	gpSetupVals(trace.Entity)

	return true
end


function TOOL:Think()
end

function TOOL.BuildCPanel(cPanel)
	cPanel:SetName( "#tool.selfchanger.name" )
	cPanel:Help   ( "#tool.selfchanger.desc" )
	cPanel:TextEntry( "#tool.selfchanger.widvariable", "selfchanger_widvariable" ):SetTooltip( "#tool.selfchanger.widvariable_con" )
	cPanel:TextEntry( "#tool.selfchanger.widvalue"   , "selfchanger_widvalue"    ):SetTooltip( "#tool.selfchanger.widvalue_con"    )
	cPanel:CheckBox ( "#tool.selfchanger.widvaluenum", "selfchanger_widvaluenum" ):SetTooltip( "#tool.selfchanger.widvaluenum_con" )
end
