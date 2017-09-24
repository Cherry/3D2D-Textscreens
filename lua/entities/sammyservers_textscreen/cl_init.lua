include("shared.lua")

local render_convar_range = CreateClientConVar("ss_render_range", 1500, true, false, "Determines the render range for Textscreens. Default 1500")
local render_convar_refresh = CreateClientConVar("ss_render_refresh", 0.5, true, false, "Determines the refresh rate for Textscreens. Default 0.5 (seconds)")
local render_range = render_convar_range:GetInt() * render_convar_range:GetInt() --We multiply this is that we can use DistToSqr instead of Distance so we don't need to workout the square root all the time
local render_refresh = render_convar_refresh:GetFloat() --Using decimals
local textscreenFonts = textscreenFonts
local screenInfo = {}
local toDraw = {}

local function ValidFont(f)
	if textscreenFonts[f] != nil then
		return textscreenFonts[f]
	elseif table.HasValue(textscreenFonts, f) then
		return f
	else
		return false
	end
end

local function SearchForScreens()
	local new = {}
	local plyPos = IsValid(LocalPlayer()) and LocalPlayer():GetPos() or Vector(0, 0, 0)
	for self, v in pairs(screenInfo) do
		if IsValid(self) then
			if self:GetPos():DistToSqr(plyPos) < render_range then
				table.insert(new, {self, self:GetPos():DistToSqr(plyPos)})
			end
		else
			screenInfo[self] = nil
		end
	end
	table.sort(new, function(a, b) return a[2] > b[2] end) --Draw order fix although this won't work all the time with long text
	for i=1, #new do
		new[i] = new[i][1]
	end
	toDraw = new
end

cvars.AddChangeCallback("ss_render_range", function(convar_name, value_old, value_new)
	render_range = tonumber(value_new) * tonumber(value_new)
end, "3D2DScreens")

cvars.AddChangeCallback("ss_render_refresh", function(convar_name, value_old, value_new)
	render_refresh = tonumber(value_new)
	timer.Create("FindSammyServers3D2DTextScreens", render_refresh, 0, SearchForScreens)
end, "3D2DScreens")

timer.Create("FindSammyServers3D2DTextScreens", render_refresh, 0, SearchForScreens)

function ENT:Initialize()
	self:SetMaterial("models/effects/vol_light001")
	self:SetRenderMode(RENDERMODE_NONE)
	net.Start("textscreens_download")
	net.WriteEntity(self)
	net.SendToServer()
end

function ENT:Draw()

end

hook.Add( "PostDrawTranslucentRenderables", "SammyServers3D2DTextScreens", function()
	for k, self in ipairs(toDraw) do
		if IsValid(self) and screenInfo[self] != nil then
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
end)

local function AddDrawingInfo(ent, t)
	local t2 = {}
	local curheight = 0
	local totheight = 0
	local font

	for i=1, #t do
		t2[i] = {}
		// Text
		t2[i].text = t[i].text
		// Colour
		t2[i].color = t[i].color
		// Font
		t2[i].font = (ValidFont(t[i].font) or textscreenFonts[1]) .. t[i].size
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

net.Receive("textscreens_update", function(len)
	local ent = net.ReadEntity()

	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then

		local t = net.ReadTable()

		ent.lines = t -- Incase an addon or something wants to read the information.

		AddDrawingInfo(ent, t)

		// Add to table to remove the delay from the timer
		if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) < render_range then
			table.insert(toDraw, ent)
		end

	end
end)

// Auto refresh
if IsValid(LocalPlayer()) then
	local screens = ents.FindByClass("sammyservers_textscreen")
	for k, v in ipairs(screens) do
		if screenInfo[v] == nil and v.lines != nil then
			AddDrawingInfo(v, v.lines)
		end
	end
end
