--STOOL Turret Schedular


TOOL_ACTION_LEFT   = 1
TOOL_ACTION_RIGHT  = 2
TOOL_ACTION_RELOAD = 3

MAX_RATE = 5 --The maximum of stool turret actions per server tick

if (CLIENT) then return end

local ToolEvents = {}

function AddToolEvent(delay,entity,action) 
	delay = delay or 0
	table.insert(ToolEvents, {t=CurTime() + delay, e=entity,a=action })
end

local function SchedThink()

	local i=0

	for _, e in ipairs(ToolEvents) do
		
		if e.t < CurTime() then
			table.remove(ToolEvents,_)
			
			local ent = e.e
			
			if(ent:IsValid()) then

				ent:DoToolAction(e.a) 
				i=i+1
			end
			
			
			if i > MAX_RATE then return end
		end
		
	end
end

 hook.Add("Think", "STOOLTurretSched", SchedThink) 
 
