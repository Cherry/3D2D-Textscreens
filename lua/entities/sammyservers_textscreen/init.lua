AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
resource.AddWorkshop("109643223")

include("shared.lua")

local CurTime = CurTime
local IsValid = IsValid


function ENT:Initialize()
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:DrawShadow(false)
	self:SetModel("models/hunter/plates/plate1x1.mdl")
	self:SetMaterial("models/effects/vol_light001")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
	self.heldby = 0
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
hook.Add("PhysgunPickup", "3D2DTextScreensPreventTravelPickup", textScreenPickup)

local function textScreenDrop(ply, ent)
	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.heldby = ent.heldby - 1
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			ent:PhysicsUpdate(phys)
		end
	end
end
hook.Add("PhysgunDrop", "3D2DTextScreensPreventTravelDrop", textScreenDrop)

util.AddNetworkString("textscreens_update")
util.AddNetworkString("textscreens_download")

function ENT:SetLine(line, text, color, size, font, rainbow)
	if not text then return end
	if string.sub(text, 1, 1) == "#" then
		text = string.sub(text, 2)
	end
	if string.len(text) > 180 then
		text = string.sub(text, 1, 180) .. "..."
	end

	size = math.Clamp(size, 1, 100)

	font = textscreenFonts[font] ~= nil and font or 1

	rainbow = rainbow or 0

	self.lines = self.lines or {}
	self.lines[tonumber(line)] = {
		["text"] = text,
		["color"] = color,
		["size"] = size,
		["font"] = font,
		["rainbow"] = rainbow
	}
end

local function canSendUpdate(ply, ent)
	local updates = ply.TextScreenUpdates
	if not updates then
		updates = {}
		ply.TextScreenUpdates = updates
	end

	local now = CurTime()
	local lastSent = updates[ent] or 0
	if lastSent > (now - 1) then
		return false
	end

	updates[ent] = now
	return true
end

function ENT:OnRemove()
	local plys = player.GetAll()
	local plyCount = #plys

	for i = 1, plyCount do
		local updates = plys[i].TextScreenUpdates
		if updates then updates[self] = nil end
	end
end

net.Receive("textscreens_download", function(len, ply)
	if not IsValid(ply) then return end

	local ent = net.ReadEntity()
	if not IsValid( ent ) then return end
	if ent:GetClass() ~= "sammyservers_textscreen" then return end

	if not canSendUpdate(ply, ent) then return end

	ent:SendLines(ply)
end)

function ENT:SendLines(ply)
	if not self.lines then self.lines = {} end

	net.Start("textscreens_update")
	net.WriteEntity(self)
	net.WriteTable(self.lines)

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function ENT:Broadcast()
	self:SendLines(nil)
end
