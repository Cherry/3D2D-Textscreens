include("shared.lua")

local render_convar_range = CreateClientConVar("ss_render_range", 1500, true, false, "Determines the render range for Textscreens. Default 1500")
local render_range = render_convar_range:GetInt() * render_convar_range:GetInt() --We multiply this is that we can use DistToSqr instead of Distance so we don't need to workout the square root all the time
local textscreenFonts = textscreenFonts
local screenInfo = {}
local shouldDrawBoth = false

-- Numbers used in conjunction with text width to work out the render bounds
local widthBoundsDivider = 7.9
local heightBoundsDivider = 12.4

-- ENUM type things for faster table indexing
local FONT = 1
local TEXT = 2
local POSX = 3
local POSY = 4
local COL = 5
local LEN = 6

-- Make ply:ShouldDrawLocalPlayer() never get called more than once a frame
hook.Add("Think", "ss_should_draw_both_sides", function()
	shouldDrawBoth = LocalPlayer():ShouldDrawLocalPlayer()
end)

local function ValidFont(f)
	if textscreenFonts[f] ~= nil then
		return textscreenFonts[f]
	elseif table.HasValue(textscreenFonts, f) then
		return f
	else
		return false
	end
end

cvars.AddChangeCallback("ss_render_range", function(convar_name, value_old, value_new)
	render_range = tonumber(value_new) * tonumber(value_new)
end, "3D2DScreens")

function ENT:Initialize()
	self:SetMaterial("models/effects/vol_light001")
	self:SetRenderMode(RENDERMODE_NONE)
	net.Start("textscreens_download")
	net.WriteEntity(self)
	net.SendToServer()
end

local product
local function IsInFront(entPos, plyShootPos, direction)
	product = (entPos.x - plyShootPos.x) * direction.x +
		(entPos.y - plyShootPos.y) * direction.y +
		(entPos.z - plyShootPos.z) * direction.z
	return product < 0
end

-- Draws the 3D2D text with the given positions, angles and data(text/font/col)
local function Draw3D2D(ang, pos, camangle, data)
	cam.Start3D2D(pos, camangle, .25)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)

		-- Loop through each line
		for i = 1, data[LEN] do
			if not data[i] or not data[i][TEXT] then continue end
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

local plyShootPos, ang, pos, camangle, showFront, data -- Less variables being created each frame
function ENT:DrawTranslucent()
	-- Cache the shoot pos for this frame
	plyShootPos = LocalPlayer():GetShootPos()

	if screenInfo[self] ~= nil and self:GetPos():DistToSqr(plyShootPos) < render_range then
		ang = self:GetAngles()
		pos = self:GetPos() + ang:Up()
		camangle = Angle(ang.p, ang.y, ang.r)
		data = screenInfo[self]

		-- Should we draw both screens? (Third person/calview drawing fix)
		if shouldDrawBoth then
			Draw3D2D(ang, pos, camangle, data)
			camangle:RotateAroundAxis(camangle:Right(), 180)
			Draw3D2D(ang, pos, camangle, data)
		else
			-- Is the front of the screen facing us or the back?
			showFront = IsInFront(pos, plyShootPos, ang:Up())

			-- Draw the front of the screen
			if showFront then
				Draw3D2D(ang, pos, camangle, data)
			else
			-- Draw the back of the screen
				camangle:RotateAroundAxis(camangle:Right(), 180)
				Draw3D2D(ang, pos, camangle, data)
			end
		end
	end
end

local function AddDrawingInfo(ent, rawData)
	local drawData = {}
	local textSize = {}

	local totalHeight = 0
	local maxWidth = 0
	local currentHeight = 0

	for i = 1, #rawData do
		-- Setup tables
		if not rawData[i] or not rawData[i].text then continue end
		drawData[i] = {}
		textSize[i] = {}
		-- Text
		drawData[i][TEXT] = rawData[i].text
		-- Font
		drawData[i][FONT] = (ValidFont(rawData[i].font) or textscreenFonts[1]) .. rawData[i].size
		-- Text size
		surface.SetFont(drawData[i][FONT])
		textSize[i][1], textSize[i][2] = surface.GetTextSize(drawData[i][TEXT])
		-- Workout max width for render bounds
		maxWidth = maxWidth > textSize[i][1] and maxWidth or textSize[i][1]
		-- Position
		totalHeight = totalHeight + textSize[i][2]
		-- Colour
		drawData[i][COL] = Color(rawData[i].color.r, rawData[i].color.g, rawData[i].color.b, 255)
	end

	-- Sort out heights
	for i = 1, #rawData do
		if not rawData[i] then continue end
		-- The x position at which to draw the text relative to the text screen entity
		drawData[i][POSX] = math.ceil(-textSize[i][1] / 2)
		-- The y position at which to draw the text relative to the text screen entity
		drawData[i][POSY] = math.ceil(-(totalHeight / 2) + currentHeight)
		-- Highest line to lowest, so that everything is central
		currentHeight = currentHeight + textSize[i][2]
	end

	-- Cache the number of lines/length
	drawData[LEN] = #drawData
	-- Add the new data to our text screen list
	screenInfo[ent] = drawData

	-- Calculate the render bounds
	local x = maxWidth / widthBoundsDivider
	local y = currentHeight / heightBoundsDivider + 13 -- Text is above the centre

	-- Setup the render bounds
	ent:SetRenderBounds(Vector(-x, -y, -1.75), Vector(x, y, 1.75))
end

net.Receive("textscreens_update", function(len)
	local ent = net.ReadEntity()

	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then

		local t = net.ReadTable()

		ent.lines = t -- Incase an addon or something wants to read the information.

		AddDrawingInfo(ent, t)
	end
end)

-- Auto refresh
if IsValid(LocalPlayer()) then
	local screens = ents.FindByClass("sammyservers_textscreen")
	for k, v in ipairs(screens) do
		if screenInfo[v] == nil and v.lines ~= nil then
			AddDrawingInfo(v, v.lines)
		end
	end
end
