textscreenFonts = {}

local function addFont(font, t)
	if CLIENT then
		t.size = 100
		surface.CreateFont(font, t)
		t.size = 50
		surface.CreateFont(font .. "_MENU", t)
	end

	table.insert(textscreenFonts, font)
end

--[[
---------------------------------------------------------------------------
Custom fonts - requires server restart to take affect -- "Screens_" will be removed from the font name in spawnmenu
---------------------------------------------------------------------------
--]]

-- Default textscreens font
addFont("Coolvetica outlined", {
	font = "coolvetica",
	weight = 400,
	antialias = false,
	outline = true
})

addFont("Coolvetica", {
	font = "coolvetica",
	weight = 400,
	antialias = false,
	outline = false
})

-- Trebuchet
addFont("Screens_Trebuchet outlined", {
	font = "Trebuchet MS",
	weight = 400,
	antialias = false,
	outline = true
})

addFont("Screens_Trebuchet", {
	font = "Trebuchet MS",
	weight = 400,
	antialias = false,
	outline = false
})

-- Arial
addFont("Screens_Arial outlined", {
	font = "Arial",
	weight = 600,
	antialias = false,
	outline = true
})

addFont("Screens_Arial", {
	font = "Arial",
	weight = 600,
	antialias = false,
	outline = false
})

-- Roboto Bk
addFont("Screens_Roboto outlined", {
	font = "Roboto Bk",
	weight = 400,
	antialias = false,
	outline = true
})

addFont("Screens_Roboto", {
	font = "Roboto Bk",
	weight = 400,
	antialias = false,
	outline = false
})

-- Helvetica
addFont("Screens_Helvetica outlined", {
	font = "Helvetica",
	weight = 400,
	antialias = false,
	outline = true
})

addFont("Screens_Helvetica", {
	font = "Helvetica",
	weight = 400,
	antialias = false,
	outline = false
})

-- akbar
addFont("Screens_Akbar outlined", {
	font = "akbar",
	weight = 400,
	antialias = false,
	outline = true
})

addFont("Screens_Akbar", {
	font = "akbar",
	weight = 400,
	antialias = false,
	outline = false
})

-- csd
addFont("Screens_csd outlined", {
	font = "csd",
	weight = 400,
	antialias = false,
	outline = true
})

addFont("Screens_csd", {
	font = "csd",
	weight = 400,
	antialias = false,
	outline = false
})

if CLIENT then

	local function addFonts(path)
		local files, folders = file.Find("resource/fonts/" .. path .. "*", "MOD")

		for k, v in ipairs(files) do
			if string.GetExtensionFromFilename(v) == "ttf" then
				local font = string.StripExtension(v)
				if table.HasValue(textscreenFonts, "Screens_" .. font) then continue end
print("-- "  .. font .. "\n" .. [[
addFont("Screens_ ]] .. font .. [[", {
	font = font,
	weight = 400,
	antialias = false,
	outline = true
})
				]])
			end
		end

		for k, v in ipairs(folders) do
			addFonts(path .. v .. "/")
		end
	end

	concommand.Add("get_fonts", function(ply)
		addFonts("")
	end)

end
