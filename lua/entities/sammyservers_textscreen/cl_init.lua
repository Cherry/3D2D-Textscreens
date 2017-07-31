include("shared.lua")

local render_convar = CreateClientConVar("ss_render_range", 1500, true, false, "Determines the render range for Textscreens. Default 1500")
local render_range = render_convar:GetInt() * render_convar:GetInt() --We multiply this is that we can use DistToSqr instead of Distance so we don't need to workout the square root all the time
local textscreenFonts = textscreenFonts
local screenInfo = {}

cvars.AddChangeCallback("ss_render_range", function(convar_name, value_old, value_new)
	render_range = tonumber(value_new) * tonumber(value_new)
end)

local function validFont(f)
	if textscreenFonts[f] != nil then
		return textscreenFonts[f]
	elseif table.HasValue(textscreenFonts, f) then
		return f
	else
		return false
	end
end

function ENT:Initialize()
	self:SetMaterial("models/effects/vol_light001")
	self:SetRenderMode(RENDERMODE_NONE)
	self.lines = self.lines or {}
	net.Start("textscreens_download")
	net.WriteEntity(self)
	net.SendToServer()
end

function ENT:Draw()
	if self:GetPos():DistToSqr(LocalPlayer():GetPos()) < render_range and screenInfo[self] != nil then
		local ang = self:GetAngles()
		local pos = self:GetPos() + ang:Up()
		local camangle = Angle(ang.p, ang.y, ang.r)

		cam.Start3D2D(pos, camangle, .25)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)

		for i=1, screenInfo[self].tableSize do
			draw.DrawText(screenInfo[self][i].text, screenInfo[self][i].font, 0, screenInfo[self][i].pos, screenInfo[self][i].color, TEXT_ALIGN_CENTER)
		end

		render.PopFilterMin()
		cam.End3D2D()
		camangle:RotateAroundAxis(camangle:Right(), 180)
		cam.Start3D2D(pos, camangle, .25)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)

		for i=1, screenInfo[self].tableSize do
			draw.DrawText(screenInfo[self][i].text, screenInfo[self][i].font, 0, screenInfo[self][i].pos, screenInfo[self][i].color, TEXT_ALIGN_CENTER)
		end

		render.PopFilterMin()
		cam.End3D2D()
	end
end

function ENT:OnRemove()
	screenInfo[self] = nil
end

net.Receive("textscreens_update", function(len)
	local ent = net.ReadEntity()

	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then

		local t = net.ReadTable()
		local t2 = {}
		local curheight = 0
		local totheight = 0
		local font

		ent.lines = t -- Incase an addon or something wants to read the information.

		for i=1, #t do
			t2[i] = {}
			// Text
			t2[i].text = t[i].text
			// Colour
			t2[i].color = t[i].color
			// Font
			t2[i].font = (validFont(t[i].font) or textscreenFonts[1]) .. t[i].size
			// Textsize
			surface.SetFont(t2[i].font)
			local TextWidth, TextHeight = surface.GetTextSize(t2[i].text)
			// Pos
			totheight = totheight + TextHeight
			t2[i].height = TextHeight
		end

		for i=1, #t do
			t2[i].pos = -(totheight / 2) + curheight
			curheight = curheight + t2[i].height
		end

		t2.tableSize = #t

		screenInfo[ent] = t2

	end
end)
