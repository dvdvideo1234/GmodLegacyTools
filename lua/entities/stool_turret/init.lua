
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

---------------------------------------------------------
--   Name: Initialize
---------------------------------------------------------

function ENT:Initialize()
  self.Entity:SetModel(self.Model)
  self.Entity:PhysicsInit(SOLID_VPHYSICS)
  self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
  self.Entity:SetSolid(SOLID_VPHYSICS)

  --Don't collide with the player
  self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON )

  -- Wake the physics object up. It's time to have fun.
  local phys = self.Entity:GetPhysicsObject()
  if(phys:IsValid()) then
    phys:EnableMotion(false) --Freeze it
    phys:Wake()
  end

  self.ToolGun = nil
  self.FireCount = 0

  --Wire Addon
  if(WireAddon == 1) then
    self.Inputs = WireLib.CreateSpecialInputs(self.Entity,
      {"LeftClick", "RightClick", "Reload", "Freeze", "Mode", "Isolate", "Config"}, {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING", "NORMAL", "TABLE"})
    self.Outputs = WireLib.CreateSpecialOutputs(self.Entity,
      {"FireCount", "Mode", "Isolated", "Config"}, {"NORMAL", "STRING", "NORMAL", "TABLE"})
    self.CanLeft = true
    self.CanRight = true
    self.CanReload = true
    Wire_TriggerOutput(self.Entity, "FireCount", self.FireCount)
  end

  self:Update()
end

--Wire input, only triggers on rising edge, must set value to < 1 before triggering again
function ENT:TriggerInput(iname, value)
  if (iname == "LeftClick") then
    if (value >= 1) and self.CanLeft then
      self.CanLeft = false
      AddToolEvent(self.Delay, self, TOOL_ACTION_LEFT)
    else
      self.CanLeft = true
    end

  elseif (iname == "RightClick") then
    if (value >= 1) and self.CanRight then
      self.CanRight = false
      AddToolEvent(self.Delay, self, TOOL_ACTION_RIGHT)
    else
      self.CanRight = true
    end

  elseif (iname == "Reload") then
    if (value >= 1) and self.CanReload then
      self.CanReload = false
      AddToolEvent(self.Delay, self, TOOL_ACTION_RELOAD)
    else
      self.CanReload = true
    end

  elseif (iname == "Freeze") then
    local phys = self.Entity:GetPhysicsObject()
    if(value ~= 0) then
      phys:EnableMotion(false)
      phys:Wake()
    else
      phys:EnableMotion(true)
      phys:Wake()
    end

  elseif (iname == "Mode") then
    if (value ~= "" and value ~= self.Mode) then
      if not self.ToolGun.Tool[value] then
        self.Owner:PrintMessage(HUD_PRINTCENTER,"Tool Invalid")
      elseif not AllowTool(value) then
        self.Owner:PrintMessage(HUD_PRINTCENTER,"That tool is disabled for Turret use")
      else
        self.Mode = value
        local Vars = {}
        for k,v in pairs(self.ToolGun.Tool[value].ClientConVar) do
          local key = value .. "_" .. k
          local val = self.Owner:GetInfo(key)
          Vars[k] = val
        end
        self.Vars = Vars
        self:Update()
      end
    end

  elseif (iname == "Isolate") then
    if(value ~= 0) then
      self.Isolated = 1
    else
      self.Isolated = 0
    end
    self:Update()

  elseif(iname == "Config") then
    -- self.Owner:ChatPrint(value.ToString())
    -- PrintTable(self.Vars)
    if(type(value) == "table") then
      for Key,Type in pairs(value["stypes"]) do
        if(Type == "n") then
          if(type(self.Vars[Key]) == "number") then
            self.Vars[Key] = value["s"][Key]
          end
        elseif(Type == "s") then
          if(type(self.Vars[Key]) == "string") then
            self.Vars[Key] = value["s"][Key]
          end
        elseif(Type == "r") then
        elseif(Type == "t") then
        elseif(Type == "e") then
        elseif(Type == "a") then
        elseif(Type == "v") then
        elseif(Type == "m") then
        elseif(Type == "b") then
        elseif(Type == "c") then
        elseif(Type == "q") then
        elseif(Type == "xv2") then
        elseif(Type == "xv4") then
        elseif(Type == "xm2") then
        elseif(Type == "xm4") then
        elseif(Type == "xwl") then
        elseif(Type == "xrd") then
        end
      end
      self:Update()
    end
  end
end




function ENT:DoToolAction(action)
  local trace = util.QuickTrace( self.Entity:GetPos() + self.Entity:GetForward() * 5 , self.Entity:GetForward() * self.Range,self.Entity)

  if trace.Hit and gamemode.Call( "CanTool", self.Owner, trace, self.Mode ) then
    --Ask the gamemode if it's ok to do this

    self.Tool.TurretEntity = self.Entity

    self.Tool.GetClientInfo =   ToolOveride.GetClientInfo   --This will call our function rather than the ones on the ToolObj metatable
    self.Tool.GetClientNumber = ToolOveride.GetClientNumber
    -- self.Tool.SetStage =     ToolOveride.SetStage    --khm: no idea why this was overwritten originally but i'll leave the code just in case taking them out was a bad idea later on
    -- self.Tool.GetStage =     ToolOveride.GetStage

    local oldGetSWEP = self.Tool.GetSWEP
    self.Tool.GetSWEP = ToolOveride.GetSWEP

    if(action == TOOL_ACTION_LEFT) then local r = self.Tool:LeftClick(trace) end
    if(action == TOOL_ACTION_RIGHT) then local r = self.Tool:RightClick(trace) end
    if(action == TOOL_ACTION_RELOAD) then local r = self.Tool:Reload(trace) end

    self.CanReload = true
    self.CanLeft = true
    self.CanRight = true

    if(r ~= false) then
      --Do the effect
      self.Entity:EmitSound(self.ShootSound,100,50)

      local effectdata = EffectData()
        effectdata:SetOrigin( trace.HitPos )
        effectdata:SetNormal( trace.HitNormal )
        effectdata:SetEntity( trace.Entity )
        effectdata:SetAttachment( trace.PhysicsBone  )
        util.Effect( "selection_indicator", effectdata )

      local effectdata = EffectData()
        effectdata:SetStart( self.Entity:GetPos() )
        effectdata:SetOrigin( trace.HitPos )
        effectdata:SetScale( 1 )
        effectdata:SetEntity( self.Entity )
        util.Effect( "ToolTracer", effectdata )
    end

    self.Tool.GetSWEP = oldGetSWEP


    self.Tool.GetClientInfo = nil
    self.Tool.GetClientNumber = nil
    -- self.Tool.SetStage = nil
    -- self.Tool.GetStage = nil

    if WireAddon == 1 then
      self.FireCount = self.FireCount + 1
      Wire_TriggerOutput(self.Entity, "FireCount", self.FireCount)
    end

  end
end

function ENT:SetConVar(name,value)
  self.Vars[name] = value
end

function ENT:Update()

  self:CheckToolGun()

  local E2Table = {}
  local tname = string.gsub((self.Tool.Name or self.Mode),'#','')
  local lbl = "Stool Turret " .. tname.. "\n"

  lbl = lbl .. "Delay: " .. self.Delay .. "\n"
  lbl = lbl .. "Tool config:\n"

  if(WireAddon == 1)then
    E2Table["size"]    = 0
    E2Table["s"]       = {}
    E2Table["stypes"]  = {}
    E2Table["istable"] = true
    E2Table["depth"]   = 0
    E2Table["n"]       = {}
    E2Table["ntypes"]  = {}
  end

  for k,v in pairs(self.Vars) do
    lbl = lbl .. k .. ": " .. v .."\n"
    if(WireAddon == 1) then
      if(type(v) == "number") then
        E2Table["size"] = E2Table["size"] + 1
        E2Table["s"][k] = v
        E2Table["stypes"][k] = "n"
      elseif(type(v) == "string") then
        E2Table["size"] = E2Table["size"] + 1
        E2Table["s"][k] = v
        E2Table["stypes"][k] = "s"
      elseif(type(v) == "boolean") then
        E2Table["size"] = E2Table["size"] + 1
        E2Table["s"][k] = v == true
        E2Table["stypes"][k] = "n"
      elseif(type(v) == "table") then
      elseif(type(v) == "Vector") then
        E2Table["size"] = E2Table["size"] + 1
        E2Table["s"][k] = v
        E2Table["stypes"][k] = "v"
      elseif(type(v) == "Angle") then
        E2Table["size"] = E2Table["size"] + 1
        E2Table["s"][k] = {v.p, v.y, v.r}
        E2Table["stypes"][k] = "a"
      elseif(type(v) == "Color") then
      end
    end
  end

  self.Entity:SetNWString("label",lbl)

  if(WireAddon == 1) then
    Wire_TriggerOutput(self.Entity, "Mode", self.Mode)
    Wire_TriggerOutput(self.Entity, "Config", E2Table)
  end
end

---------------------------------------------------------
--- gmod_tool Emulation functions
--- It is not nessesary to overide every function
---------------------------------------------------------

ToolOveride = {}

function ToolOveride.GetClientInfo(tool, property )
  return tool.TurretEntity.Vars[property]
end

function ToolOveride.GetClientNumber(tool, property, default )
  return tonumber(tool.TurretEntity.Vars[property]) or default
end

function ToolOveride.SetStage(tool, i )
  if(SERVER) then
    tool.TurretEntity.Owner:SetNWInt(tool.TurretEntity.Mode .. "_stage", i, true)
  end
end

function ToolOveride.GetStage(tool)
  return tool.TurretEntity.Owner:GetNWInt(tool.TurretEntity.Mode .. "_stage", 0)
end

function ToolOveride.GetSWEP(tool)
  return tool.TurretEntity
end

function ENT:CheckToolGun()
  if(self.ToolGun and self.ToolGun:IsValid()) then
    if(self.Isolated ~= 0 and self.ToolGun:GetOwner() ~= self) then
      self.Owner:ChatPrint("Changed to Isolated")
      self.ToolGun = nil
    elseif(self.Isolated == 0 and self.ToolGun:GetOwner() == self) then
      self.Owner:ChatPrint("Changed to not Isolated")
      self:RemoveCallOnRemove("Tool Gun Cleanup")
      self.ToolGun:Remove()
      self.ToolGun = nil
    end
  end
  if not (self.ToolGun and self.ToolGun:IsValid()) then
    --Disaster the player has died and the tool gun was deleted.
    if(self.Isolated ~= 0) then
      self.ToolGun = ents.Create("gmod_tool")
      self.ToolGun:Spawn()
      self.ToolGun:SetOwner(self)
      self:CallOnRemove("Tool Gun Cleanup", self.ToolGun.Remove)
    elseif not (self.Owner and self.Owner:IsValid()) then
      --Worse, the player has left the game

      --Create our own toolgun
      self.ToolGun = ents.Create("gmod_tool")
      self.ToolGun:Spawn()
    else
      local toolguns = ents.FindByClass("gmod_tool")
      for _,gun in ipairs(toolguns) do
        if gun:GetOwner() == self.Owner then
          self.ToolGun = gun
        end
      end
    end
  end

  if(WireAddon == 1) then
    Wire_TriggerOutput(self.Entity, "Isolated", self.Isolated)
  end

  self.Tool = self.ToolGun.Tool[self.Mode]
end

--SWEP Functions
function ENT:GetOwner()
  return self.Owner
end

function ENT:CheckLimit( str )
  local ply = self:GetOwner()
  if ply.CheckLimit then return ply:CheckLimit( str ) end
  return true
end

-- Numpad functions

local function Left( pl, ent )
  if(ent == nil or not ent:IsValid()) then return false end
  AddToolEvent(ent.Delay,ent, 1)
end

local function Right( pl, ent )
  if(ent == nil or not ent:IsValid()) then return false end
  AddToolEvent(ent.Delay,ent, 2)
end

local function Reload( pl, ent)
  if(ent == nil or not ent:IsValid()) then return false end
  AddToolEvent(ent.Delay,ent, 3)
end

-- register numpad functions
numpad.Register( "StoolTurret_Left", Left )
numpad.Register( "StoolTurret_Right", Right )
numpad.Register( "StoolTurret_Reload", Reload )

function ENT:OnRestore()
  Wire_Restored(self.Entity)
  self.ToolGun = nil
  self.FireCount = 0

  -- Wire Addon
  if(WireAddon == 1) then
    self.Inputs = WireLib.CreateSpecialInputs(self.Entity, {"LeftClick", "RightClick", "Reload", "Freeze", "Mode", "Isolate", "Config"}, {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING", "NORMAL", "TABLE"})
    self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, {"FireCount", "Mode", "Isolated", "Config"}, {"NORMAL", "STRING", "NORMAL", "TABLE"})
    self.CanLeft = true
    self.CanRight = true
    self.CanReload = true
    Wire_TriggerOutput(self.Entity, "FireCount", self.FireCount)
  end
  self:Update()
end

function ENT:OnRemove()
  Wire_Remove(self.Entity)
end


function ENT:BuildDupeInfo()
  -- return WireLib.BuildDupeInfo( self.Entity )
  if (not self.Inputs) then return end

  local info = { Wires = {} }
  for k,input in pairs(self.Inputs) do
    if (input.Src) and (input.Src:IsValid()) then
        info.Wires[k] = {
        StartPos = input.StartPos,
        Material = input.Material,
        Color = input.Color,
        Width = input.Width,
        Src = input.Src:EntIndex(),
        SrcId = input.SrcId,
        SrcPos = Vector(0, 0, 0),
      }

      if (input.Path) then
        info.Wires[k].Path = {}

          for _,v in ipairs(input.Path) do
              if (v.Entity) and (v.Entity:IsValid()) then
                table.insert(info.Wires[k].Path, { Entity = v.Entity:EntIndex(), Pos = v.Pos })
          end
          end

          local n = table.getn(info.Wires[k].Path)
          if (n > 0) and (info.Wires[k].Path[n].Entity == info.Wires[k].Src) then
              info.Wires[k].SrcPos = info.Wires[k].Path[n].Pos
              table.remove(info.Wires[k].Path, n)
          end
      end
    end
  end

  return info
end

-- Copied form Wire
function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
  -- WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
  if (info.Wires) then
    for k,input in pairs(info.Wires) do

      Wire_Link_Start(ply:UniqueID(), ent, input.StartPos, k, input.Material, input.Color, input.Width)

      if (input.Path) then
            for _,v in ipairs(input.Path) do

          local ent2 = GetEntByID(v.Entity)
          if (not ent2) or (not ent2:IsValid()) then ent2 = ents.GetByIndex(v.Entity) end
          if (ent2) or (ent2:IsValid()) then
            Wire_Link_Node(ply:UniqueID(), ent2, v.Pos)
          else
            Msg("ApplyDupeInfo: Error, Could not find the entity for wire path\n")
          end
        end
        end

      local ent2 = GetEntByID(input.Src)
        if (not ent2) or (not ent2:IsValid()) then ent2 = ents.GetByIndex(input.Src) end
      if (ent2) or (ent2:IsValid()) then
        Wire_Link_End(ply:UniqueID(), ent2, input.SrcPos, input.SrcId)
      else
        Msg("ApplyDupeInfo: Error, Could not find the output entity\n")
      end
    end
  end
end


-- new duplicator stuff
function ENT:PreEntityCopy()
  -- build the DupeInfo table and save it as an entity mod
  local DupeInfo = self:BuildDupeInfo()
  if DupeInfo then
    duplicator.StoreEntityModifier( self.Entity, "WireDupeInfo", DupeInfo )
  end
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
  -- apply the DupeInfo
  if (Ent.EntityMods) and (Ent.EntityMods.WireDupeInfo) then
    Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
  end
end
