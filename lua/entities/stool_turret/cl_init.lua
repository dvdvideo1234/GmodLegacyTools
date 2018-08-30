
include('shared.lua')

local mat = Material("cable/redlaser" )
-----------------------------------------------
--   Name: Initialize
---------------------------------------------------------
function ENT:Initialize()
	
	local range = self.Entity:GetNWInt("range")
	local minb = Vector(-20,-20,-20)
	local maxb = Vector(20,range,20)
	
	self.Entity:SetRenderBoundsWS(minb,maxb,Vector()*6)
end



 function ENT:Draw()
  -- self.BaseClass.Draw(self) -- We want to override rendering, so don't call baseclass.
  -- Use this when you need to add to the rendering.
  self.Entity:DrawModel() -- Draw the model.
  
  local tr =  LocalPlayer():GetEyeTrace()
  if tr.Entity == self.Entity then
	AddWorldTip( self.Entity:EntIndex(), self.Entity:GetNetworkedString("label"), 0.5, self.Entity:GetPos(), self.Entity )
  end
  
  self.Range = self.Entity:GetNWInt("range")
  
  local tr = util.QuickTrace( self.Entity:GetPos() + self.Entity:GetForward() * 5 , self.Entity:GetForward() * self.Range,self.Entity)
  
  local startPos = self.Entity:GetPos()
  local endPos = tr.HitPos

  render.SetMaterial(mat)
  render.DrawBeam( startPos,endPos,1, 0, 10 )
  
  if Wire_Render then Wire_Render(self.Entity) end
  
 end 
 
 function ENT:Think()
   if Wire_Render then 
		if (CurTime() >= (self.NextRBUpdate or 0)) then
			self.NextRBUpdate = CurTime()+2
			Wire_UpdateRenderBounds(self.Entity)
		end
	end
end

