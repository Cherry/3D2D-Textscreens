textscreenFonts = {}

local function addFont(font, t)
	if CLIENT then
		for i = 1, 100 do
			t.size = i
			surface.CreateFont(font .. i, t)
		end
	end

	table.insert(textscreenFonts, font)
end

/*---------------------------------------------------------------------------
Custom fonts - requires server restart to take affect -- "Screens_" will be removed from the font name in spawnmenu
---------------------------------------------------------------------------*/

// Default textscreens font
addFont("Coolvetica", {
	font = "coolvetica",
	weight = 400,
	antialias = false,
	outline = true
})

// Trebuchet
addFont("Screens_Trebuchet", {
	font = "Trebuchet18",
	weight = 400,
	antialias = false,
	outline = true
})

// CloseCaption_Normal
addFont("Screens_CloseCaption", {
	font = "CloseCaption_Normal",
	weight = 400,
	antialias = false,
	outline = true
})

// Arial
addFont("Screens_Arial", {
	font = "Arial",
	weight = 600,
	antialias = false,
	outline = true
})

// DejaVu Sans
addFont("Screens_DejaVu Sans", {
	font = "DejaVu Sans",
	weight = 400,
	antialias = false,
	outline = true
})

// Tahoma
addFont("Screens_Tahoma", {
	font = "Tahoma",
	weight = 400,
	antialias = false,
	outline = true
})

// Roboto Bk
addFont("Screens_Roboto", {
	font = "Roboto Bk",
	weight = 400,
	antialias = false,
	outline = true
})

// Helvetica
addFont("Screens_Helvetica", {
	font = "Helvetica",
	weight = 400,
	antialias = false,
	outline = true
})

// Default
addFont("Screens_Default", {
	font = "Default",
	weight = 400,
	antialias = false,
	outline = true
})

// akbar
addFont("Screens_akbar", {
	font = "akbar",
	weight = 400,
	antialias = false,
	outline = true
})

// boogaloo
addFont("Screens_boogaloo", {
	font = "boogaloo",
	weight = 400,
	antialias = false,
	outline = true
})

// csd
addFont("Screens_csd", {
	font = "csd",
	weight = 400,
	antialias = false,
	outline = true
})

if CLIENT then

	local function addFonts(path)
		local files, folders = file.Find("resource/fonts/" .. path .. "*", "MOD")

		for k, v in ipairs(files) do
			if string.GetExtensionFromFilename(v) == "ttf" then
				local font = string.StripExtension(v)
				if table.HasValue(textscreenFonts, "Screens_" .. font) then continue end
print("//"  .. font .. "\n" .. [[
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