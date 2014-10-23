AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")


function ENT:Initialize()
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:DrawShadow(false)
	self:SetModel("models/hunter/plates/plate1x1.mdl")
	self:SetMaterial("models/effects/vol_light001")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	for i = 1, 5 do
		self:SetNWString("Text"..i, "")
		self:SetNWInt("r"..i, 255)
		self:SetNWInt("g"..i, 255)
		self:SetNWInt("b"..i, 255)
		self:SetNWInt("a"..i, 255)
		self:SetNWInt("size"..i, 50)
	end
	self.heldby = 0
	self:SetMoveType(MOVETYPE_NONE)
end

function ENT:PhysicsUpdate(phys)
	if self.heldby <= 0 then
		phys:Sleep()
	end
end

local function textscreenpickup(ply, ent)
	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.heldby = ent.heldby+1
	end
end
hook.Add("PhysgunPickup", "textscreenpreventtravelpickup", textscreenpickup)

local function textscreendrop(ply, ent)
	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.heldby = ent.heldby-1
	end
end
hook.Add("PhysgunDrop", "textscreenpreventtraveldrop", textscreendrop)

function ENT:UpdateText(NewText, NewColor, NewSize)
	for i = 1, 5 do
		if NewText[i] and NewColor[i] and NewSize[i] then
			self:SetNWString("Text"..i, NewText[i])
			self:SetNWInt("r"..i, NewColor[i].r)
			self:SetNWInt("g"..i, NewColor[i].g)
			self:SetNWInt("b"..i, NewColor[i].b)
			self:SetNWInt("a"..i, NewColor[i].a)
			self:SetNWInt("size"..i, NewSize[i])
		end
	end
end

local function textscreencantool(ply, trace, tool)
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "sammyservers_textscreen" then
		if !(tool == "sammyservers_textscreen" or tool == "remover") then
			return false
		end
	end
end
hook.Add("CanTool", "textscreenpreventtools", textscreencantool)