include("shared.lua")

local render_convar_range = CreateClientConVar("ss_render_range", 1500, true, false, "Determines the render range for Textscreens. Default 1500")
local render_convar_refresh = CreateClientConVar("ss_render_refresh", 0.5, true, false, "Determines the refresh rate for Textscreens. Default 0.5 (seconds)")
local render_range = render_convar_range:GetInt() * render_convar_range:GetInt() --We multiply this is that we can use DistToSqr instead of Distance so we don't need to workout the square root all the time
local render_refresh = render_convar_refresh:GetFloat() --Using decimals
local textscreenFonts = textscreenFonts
local screenInfo = {}
local toDraw = {}

-- ENUM type things faster faster table indexing
local FONT = 1
local TEXT = 2
local POSX = 3
local POSY = 4
local COL = 5
local LEN = 6

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

-- Return whether the first position is in front of the second with the given direction
local product
local function IsInFront(entPos, plyShootPos, direction)
    product = (entPos.x - plyShootPos.x) * direction.x +
                      (entPos.y - plyShootPos.y) * direction.y +
                      (entPos.z - plyShootPos.z) * direction.z
    return (product < 0)
end

local plyShootPos, ang, pos, camangle, showFront, data -- Less variables being created each frame
hook.Add( "PostDrawTranslucentRenderables", "SammyServers3D2DTextScreens", function()

	-- Cache the shoot pos for this frame
	plyShootPos = LocalPlayer():GetShootPos()

	for k, self in ipairs(toDraw) do
		if IsValid(self) and screenInfo[self] != nil then
			ang = self:GetAngles()
			pos = self:GetPos() + ang:Up()
			camangle = Angle(ang.p, ang.y, ang.r)
			data = screenInfo[self]

			-- Is the front of the screen facing us or the back?
			showFront = IsInFront(pos, plyShootPos, ang:Up())

			-- Draw the front of the screen
			if showFront then
				cam.Start3D2D(pos, camangle, .25)
					render.PushFilterMin(TEXFILTER.ANISOTROPIC)

					-- Loop through each line
					for i=1, data[LEN] do
						-- Font
						surface.SetFont(data[i][FONT])
						-- Posistion
						surface.SetTextPos(data[i][POSX], data[i][POSY])
						-- Colour
						surface.SetTextColor(data[i][COL])
						-- Text
						surface.DrawText(data[i][TEXT])
					end

					render.PopFilterMin()
				cam.End3D2D()
			else
			-- Draw the back of the screen
				camangle:RotateAroundAxis(camangle:Right(), 180)
				cam.Start3D2D(pos, camangle, .25)
					render.PushFilterMin(TEXFILTER.ANISOTROPIC)

					-- Loop through each line
					for i=1, data[LEN] do
						-- Font
						surface.SetFont(data[i][FONT])
						-- Posistion
						surface.SetTextPos(data[i][POSX], data[i][POSY])
						-- Colour
						surface.SetTextColor(data[i][COL])
						-- Text
						surface.DrawText(data[i][TEXT])
					end

					render.PopFilterMin()
				cam.End3D2D()
			end
		end
	end
end)

local function AddDrawingInfo(ent, rawData)
	local data = {}
	local textSize = {}

	local totalHeight = 0
	local currentHeight = 0

	for i=1, #rawData do
		-- Setup tables
		data[i] = {}
		textSize[i] = {}
		-- Text
		data[i][TEXT] = rawData[i].text
		-- Font
		data[i][FONT] = (ValidFont(rawData[i].font) or textscreenFonts[1]) .. rawData[i].size
		-- Text size
		surface.SetFont(data[i][FONT])
		textSize[i][1], textSize[i][2] = surface.GetTextSize(data[i][TEXT])
		-- Position
		totalHeight = totalHeight + textSize[i][2]
		-- Colour
		data[i][COL] = Color(rawData[i].color.r, rawData[i].color.g, rawData[i].color.g, 255)
	end

	-- Sort out heights
	for i=1, #rawData do
		-- The x position at which to draw the text relative to the text screen entity
		data[i][POSX] = math.ceil(-textSize[i][1] / 2)
		-- The y position at which to draw the text relative to the text screen entity
		data[i][POSY] = math.ceil(-(totalHeight / 2) + currentHeight)
		-- Heights line to lowest, so that everything is central
		currentHeight = currentHeight + textSize[i][2]
	end

	-- Cache the number of lines/length
	data[LEN] = #data
	-- Add the new data to our text screen list
	screenInfo[ent] = data

end

net.Receive("textscreens_update", function(len)
	local ent = net.ReadEntity()

	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then

		local t = net.ReadTable()

		ent.lines = t -- Incase an addon or something wants to read the information.

		AddDrawingInfo(ent, t)

		-- Add to table to remove the delay from the timer
		if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) < render_range then
			table.insert(toDraw, ent)
		end

	end
end)

-- Auto refresh
if IsValid(LocalPlayer()) then
	local screens = ents.FindByClass("sammyservers_textscreen")
	for k, v in ipairs(screens) do
		if screenInfo[v] == nil and v.lines != nil then
			AddDrawingInfo(v, v.lines)
		end
	end
end
