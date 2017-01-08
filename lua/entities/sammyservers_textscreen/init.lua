AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")


function ENT:Initialize()
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:DrawShadow(false)
	self:SetModel("models/hunter/plates/plate1x1.mdl")
	self:SetMaterial("models/effects/vol_light001")
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self.heldby = 0
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionBounds(Vector(0, -20, -10),Vector(1, 20, 10))
end

function ENT:PhysicsUpdate(phys)
	if self.heldby <= 0 then
		phys:Sleep()
	end
end

local function textScreenPickup(ply, ent)
	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.heldby = ent.heldby + 1
	end
end
hook.Add("PhysgunPickup", "textScreensPreventTravelPickup", textScreenPickup)

local function textScreenDrop(ply, ent)
	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.heldby = ent.heldby - 1
	end
end
hook.Add("PhysgunDrop", "textScreensPreventTravelDrop", textScreenDrop)

local function textScreenCanTool(ply, trace, tool)
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "sammyservers_textscreen" then
		if !(tool == "textscreen" or tool == "remover") then
			return false
		end
	end
end
hook.Add("CanTool", "textScreensPreventTools", textScreenCanTool)

util.AddNetworkString("textscreens_update")
util.AddNetworkString("textscreens_download")

function ENT:SetLine(line, text, color, size)
	if string.sub(text, 1, 1) == "#" then
		text = string.sub(text, 2)
	end
	if string.len(text) > 180 then
		text = string.sub(text, 1, 180) .. "..."
	end

	self.lines = self.lines or {}
	self.lines[tonumber(line)] = {
		["text"] = text,
		["color"] = color,
		["size"] = size
	}
end

net.Receive("textscreens_download", function(len, ply)
	if not IsValid(ply) then return end

	local ent = net.ReadEntity()
	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.lines = ent.lines or {}
		net.Start("textscreens_update")
			net.WriteEntity(ent)
			net.WriteTable(ent.lines)
		net.Send(ply)
	end
end)

function ENT:Broadcast()
	net.Start("textscreens_update")
		net.WriteEntity(self)
		net.WriteTable(self.lines)
	net.Broadcast()
end

function ENT:Think()
	if self.heldby == 1 then
		local forwardvec = self:GetForward()
		local forwardvecstr = util.TypeToString(forwardvec)
		local forwardvectbl = string.Explode(" ", forwardvecstr, false)
		local x, y, z = math.Round(forwardvectbl[1]), math.Round(forwardvectbl[2]), math.Round(forwardvectbl[3])

		if x == 1 and y == 0 and z == 0 and self:OBBMins() ~= Vector(-20, 0, 10) then -- Positive Y
			self:SetCollisionBounds(Vector(-20, 0, -10), Vector(20, 1, 10))
		end

		if x == -1 and y == 0 and z == 0 and self:OBBMins() ~= Vector(-20, 0, 10) then -- Negative Y
			self:SetCollisionBounds(Vector(-20, 0, -10), Vector(20, 1, 10))
		end

		if x == 0 and y == 1 and z == 0 and self:OBBMins() ~= Vector(-20, -10, 0) then -- Pos/Neg Z
			self:SetCollisionBounds(Vector(-20, -10, 0), Vector(20, 10, 1))
		end
	end
end