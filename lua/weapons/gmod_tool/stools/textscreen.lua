TOOL.Category = "Construction"
TOOL.Name = "#tool.textscreen.name"
TOOL.Command = nil
TOOL.ConfigName = ""
local textBox = {}
local lineLabels = {}
local labels = {}
local sliders = {}
local rainbowCheckboxes = {}
local textscreenFonts = textscreenFonts
local rainbow_enabled = cvars.Number("ss_enable_rainbow", 1)
local max_characters = cvars.Number("ss_max_characters", 0)

for i = 1, 5 do
	TOOL.ClientConVar["text" .. i] = ""
	TOOL.ClientConVar["size" .. i] = 20
	TOOL.ClientConVar["r" .. i] = 255
	TOOL.ClientConVar["g" .. i] = 255
	TOOL.ClientConVar["b" .. i] = 255
	TOOL.ClientConVar["a" .. i] = 255
	TOOL.ClientConVar["font" .. i] = 1
	TOOL.ClientConVar["rainbow" .. i] = 0
end

cleanup.Register("textscreens")

if (CLIENT) then
	TOOL.Information = {
		{ name = "left" },
		{ name = "right" },
		{ name = "reload" },
	}
	-- Add default english language strings here, in case no localisation exists
	language.Add("tool.textscreen.name", "3D2D Textscreen")
	language.Add("tool.textscreen.desc", "Create a textscreen with multiple lines, font colours and sizes.")
	language.Add("tool.textscreen.left", "Spawn a textscreen.") -- Does not work with capital T in tool. Same with right and reload.
	language.Add("tool.textscreen.right", "Update textscreen with settings.")
	language.Add("tool.textscreen.reload", "Copy textscreen.")
	language.Add("Undone.textscreens", "Undone textscreen")
	language.Add("Undone_textscreens", "Undone textscreen")
	language.Add("Cleanup.textscreens", "Textscreens")
	language.Add("Cleanup_textscreens", "Textscreens")
	language.Add("Cleaned.textscreens", "Cleaned up all textscreens")
	language.Add("Cleaned_textscreens", "Cleaned up all textscreens")
	language.Add("SBoxLimit.textscreens", "You've hit the textscreen limit!")
	language.Add("SBoxLimit_textscreens", "You've hit the textscreen limit!")
end

function TOOL:LeftClick(tr)
	if (tr.Entity:GetClass() == "player") then return false end
	if (CLIENT) then return true end
	local ply = self:GetOwner()

	if hook.Run("PlayerSpawnTextscreen", ply, tr) == false then return false end

	if not (self:GetWeapon():CheckLimit("textscreens")) then return false end
	-- ensure at least 1 line of the textscreen has text before creating entity
	local hasText = false
	for i = 1, 5 do
		local text = self:GetClientInfo("text" .. i) or ""
		if text ~= "" then
			hasText = true
		end
	end
	if not hasText then return false end
	local textScreen = ents.Create("sammyservers_textscreen")
	textScreen:SetPos(tr.HitPos)
	local angle = tr.HitNormal:Angle()
	angle:RotateAroundAxis(tr.HitNormal:Angle():Right(), -90)
	angle:RotateAroundAxis(tr.HitNormal:Angle():Forward(), 90)
	textScreen:SetAngles(angle)
	textScreen:Spawn()
	textScreen:Activate()

	undo.Create("textscreens")
	undo.AddEntity(textScreen)
	undo.SetPlayer(ply)
	undo.Finish()
	ply:AddCount("textscreens", textScreen)
	ply:AddCleanup("textscreens", textScreen)

	for lineNum = 1, 5 do
		textScreen:SetLine(
			lineNum,
			self:GetClientInfo("text" .. lineNum),
			Color(
				tonumber(self:GetClientInfo("r" .. lineNum)) or 255,
				tonumber(self:GetClientInfo("g" .. lineNum)) or 255,
				tonumber(self:GetClientInfo("b" .. lineNum)) or 255,
				tonumber(self:GetClientInfo("a" .. lineNum)) or 255
			),
			tonumber(self:GetClientInfo("size" .. lineNum)),
			tonumber(self:GetClientInfo("font" .. lineNum)),
			tonumber(self:GetClientInfo("rainbow" .. lineNum))
		)
	end

	return true
end

function TOOL:RightClick(tr)
	if (tr.Entity:GetClass() == "player") then return false end
	if (CLIENT) then return true end
	local traceEnt = tr.Entity

	if (IsValid(traceEnt) and traceEnt:GetClass() == "sammyservers_textscreen") then
		for lineNum = 1, 5 do
			traceEnt:SetLine(
				lineNum,
				self:GetClientInfo("text" .. lineNum),
				Color(
					tonumber(self:GetClientInfo("r" .. lineNum)) or 255,
					tonumber(self:GetClientInfo("g" .. lineNum)) or 255,
					tonumber(self:GetClientInfo("b" .. lineNum)) or 255,
					tonumber(self:GetClientInfo("a" .. lineNum)) or 255
				),
				tonumber(self:GetClientInfo("size" .. lineNum)),
				tonumber(self:GetClientInfo("font" .. lineNum)),
				tonumber(self:GetClientInfo("rainbow" .. lineNum))
			)
		end

		traceEnt:Broadcast()

		return true
	end
end

function TOOL:Reload(tr)
	if (SERVER) then return true end
	local traceEnt = tr.Entity
	if (not isentity(traceEnt) or traceEnt:GetClass() ~= "sammyservers_textscreen") then return false end

	-- reset
	for lineNum = 1, 5 do
		if traceEnt.lines[lineNum] == nil then
			RunConsoleCommand("textscreen_r" .. lineNum, 255)
			RunConsoleCommand("textscreen_g" .. lineNum, 255)
			RunConsoleCommand("textscreen_b" .. lineNum, 255)
			RunConsoleCommand("textscreen_a" .. lineNum, 255)
			RunConsoleCommand("textscreen_size" .. lineNum, 20)
			RunConsoleCommand("textscreen_text" .. lineNum, "")
			RunConsoleCommand("textscreen_font" .. lineNum, 1)
			RunConsoleCommand("textscreen_rainbow" .. lineNum, 0)
		end
	end
	
	for lineNum, linedata in pairs(traceEnt.lines) do
		RunConsoleCommand("textscreen_r" .. lineNum, linedata.color.r)
		RunConsoleCommand("textscreen_g" .. lineNum, linedata.color.g)
		RunConsoleCommand("textscreen_b" .. lineNum, linedata.color.b)
		RunConsoleCommand("textscreen_a" .. lineNum, linedata.color.a)
		RunConsoleCommand("textscreen_size" .. lineNum, linedata.size)
		RunConsoleCommand("textscreen_text" .. lineNum, linedata.text)
		RunConsoleCommand("textscreen_font" .. lineNum, linedata.font)
		RunConsoleCommand("textscreen_rainbow" .. lineNum, linedata.rainbow)
	end

	return true
end

local conVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	local logo = vgui.Create("DImage", CPanel)
	logo:SetSize(267, 134)
	logo:SetImage("textscreens/logo.png")
	CPanel:AddItem(logo)

	CPanel:AddControl("Header", {
		Text = "#tool.textscreen.name",
		Description = "#tool.textscreen.desc"
	})

	local analytics = vgui.Create("DCheckBoxLabel", CPanel)
	analytics:SetText("Anonymous Analytics")
	analytics:SetTextColor(Color(0,0,0,255))
	analytics:SetConVar("ss_call_to_home")
	analytics:SetTooltip("Enabling this will submit anonymous analytics to the author of this addon, including your Operating System, version of the addon, and anonymised IP address.")
	CPanel:AddItem(analytics)

	local function TrimFontName(fontnum)
		return string.Left(textscreenFonts[fontnum], 8) == "Screens_" and string.TrimLeft(textscreenFonts[fontnum], "Screens_") or textscreenFonts[fontnum]
	end

	local changefont
	local fontnum = textscreenFonts[GetConVar("textscreen_font1"):GetInt()] ~= nil and GetConVar("textscreen_font1"):GetInt() or 1

	cvars.AddChangeCallback("textscreen_font1", function(convar_name, value_old, value_new)
		fontnum = textscreenFonts[tonumber(value_new)] ~= nil and tonumber(value_new) or 1
		local font = TrimFontName(fontnum)
		changefont:SetText("Change font (" .. font .. ")")
	end)

	local function SetColor(lineNum, col, uiOnly)
		if not uiOnly then
			RunConsoleCommand("textscreen_r" .. lineNum, col.r)
			RunConsoleCommand("textscreen_g" .. lineNum, col.g)
			RunConsoleCommand("textscreen_b" .. lineNum, col.b)
			RunConsoleCommand("textscreen_a" .. lineNum, col.a)
		end
	end

	local function ResetColor(lineNum, uiOnly)
		SetColor(lineNum, Color(255,255,255,255), uiOnly)
	end

	local function SetSize(lineNum, size, uiOnly)
		size = tonumber(size) or 20
		if not uiOnly then
			RunConsoleCommand("textscreen_size" .. lineNum, size)
			sliders[lineNum]:SetValue(size)
		end
		labels[lineNum]:SetFont(textscreenFonts[fontnum] .. "_MENU")
	end

	local function ResetSize(lineNum, uiOnly)
		SetSize(lineNum, 20, uiOnly)
	end

	local function SetText(lineNum, text, uiOnly)
		if not uiOnly then
			RunConsoleCommand("textscreen_text" .. lineNum, text)
			textBox[lineNum]:SetValue(text)
		end
		labels[lineNum]:SetText(text)
	end

	local function ResetText(lineNum, uiOnly)
		SetText(lineNum, "")
	end

	local function SetFont(lineNum, fontNum, uiOnly)
		fontnum = tonumber(fontNum) or 1
		if not uiOnly then
			RunConsoleCommand("textscreen_font" .. lineNum, fontnum)
		end
		labels[lineNum]:SetFont(textscreenFonts[fontnum] .. "_MENU")
	end

	local function ResetFont(lineNum, uiOnly)
		fontnum = 1
		SetFont(lineNum, fontnum, uiOnly)
	end

	local function SetRainbow(lineNum, enabled, uiOnly)
		enabled = tonumber(tobool(enabled))
		if not uiOnly then
			RunConsoleCommand("textscreen_rainbow" .. lineNum, enabled)
			rainbowCheckboxes[lineNum]:SetValue(enabled)
		end
	end

	local function ResetRainbow(lineNum, uiOnly)
		SetRainbow(lineNum, 0, uiOnly)
	end

	local function fnResetLine(lineNum, fns, uiOnly)
		uiOnly = isbool(uiOnly) and uiOnly or false
		return function()
			for _, fn in pairs(fns) do
				fn(lineNum, uiOnly)
			end
		end
	end

	local function fnResetAllLines(fns, uiOnly)
		uiOnly = isbool(uiOnly) and uiOnly or false
		return function()
			for lineNum = 1, 5 do
				fnResetLine(lineNum, fns, uiOnly)()
			end
		end
	end

	local allResets = {
		ResetColor,
		ResetSize,
		ResetText,
		ResetFont,
		ResetRainbow
	}

	local function ResetEverything(uiOnly)
		uiOnly = isbool(uiOnly) and uiOnly or false
		fnResetAllLines(allResets, uiOnly)()
	end

	-- Update ui when copying screens
	local function addConVarListener(var, setter)
		for i = 1, 5 do
			cvars.AddChangeCallback(var..i, function(convar_name, value_old, value_new)
				setter(i, value_new, true)
			end)
		end
	end
	local prefix = "textscreen"
	local fnMap = {
		text = SetText,
		font = SetFont,
		rainbow = SetRainbow
	}
	for name, fn in pairs(fnMap) do
		addConVarListener(prefix.."_"..name, fn)
	end

	resetall = vgui.Create("DButton", resetbuttons)
	resetall:SetSize(100, 25)
	resetall:SetText("Reset all")

	resetall.DoClick = function()
		local menu = DermaMenu()

		menu:AddOption("Reset colors", fnResetAllLines({ResetColor}))
		menu:AddOption("Reset sizes", fnResetAllLines({ResetSize}))
		menu:AddOption("Reset textboxes", fnResetAllLines({ResetText}))
		menu:AddOption("Reset fonts", fnResetAllLines({ResetFont}))

		if rainbow_enabled == 1 then
			menu:AddOption("Reset rainbow", fnResetAllLines({ResetRainbow}))
		end

		menu:AddOption("Reset everything", ResetEverything)

		menu:Open()
	end

	CPanel:AddItem(resetall)
	resetline = vgui.Create("DButton")
	resetline:SetSize(100, 25)
	resetline:SetText("Reset line")

	resetline.DoClick = function()
		local menu = DermaMenu()

		for i = 1, 5 do
			menu:AddOption("Reset line " .. i, fnResetLine(i, allResets))
		end

		menu:Open()
	end

	CPanel:AddItem(resetline)

	-- Change font
	changefont = vgui.Create("DButton")
	changefont:SetSize(100, 25)
	changefont:SetText("Change font (" .. TrimFontName(fontnum) .. ")" )

	changefont.DoClick = function()
		local menu = DermaMenu()

		for i = 1, #textscreenFonts do
			local font = TrimFontName(i)
			menu:AddOption(font, function()
				fontnum = i
				for o = 1, 5 do
					RunConsoleCommand("textscreen_font" .. o, i)
					labels[o]:SetFont(textscreenFonts[fontnum] .. "_MENU")
				end
				changefont:SetText("Change font (" .. font .. ")")
			end)
		end

		menu:Open()
	end

	CPanel:AddItem(changefont)

	local controlPresets = CPanel:AddControl("ComboBox", {
		MenuButton = 1,
		Folder = "textscreen",
		Options = {
			["#preset.default"] = conVarsDefault
		},
		CVars = table.GetKeys(conVarsDefault)
	})
	local originalOnSelect = controlPresets.DropDown.OnSelect
	controlPresets.DropDown.OnSelect = function(self, index, value, data, ...)
		ResetEverything()
		return originalOnSelect(self, index, value, data, ...)
	end

	for i = 1, 5 do
		lineLabels[i] = CPanel:AddControl("Label", {
			Text = "Line " .. i,
			Description = "Line " .. i
		})

		lineLabels[i]:SetFont("Default")

		CPanel:AddControl("Color", {
			Label = "Line " .. i .. " font color",
			Red = "textscreen_r" .. i,
			Green = "textscreen_g" .. i,
			Blue = "textscreen_b" .. i,
			Alpha = "textscreen_a" .. i,
			ShowHSV = 1,
			ShowRGB = 1,
			Multiplier = 255
		})

		if rainbow_enabled == 1 then
			rainbowCheckboxes[i] = vgui.Create("DCheckBoxLabel")
			rainbowCheckboxes[i]:SetText("Rainbow Text")
			rainbowCheckboxes[i]:SetTextColor(Color(0,0,0,255))
			rainbowCheckboxes[i]:SetConVar("textscreen_rainbow" .. i)
			rainbowCheckboxes[i]:SetTooltip("Enable for rainbow text")
			rainbowCheckboxes[i]:SetValue(GetConVar("textscreen_rainbow" .. i):GetInt())
			CPanel:AddItem(rainbowCheckboxes[i])
		end

		sliders[i] = vgui.Create("DNumSlider")
		sliders[i]:SetText("Font size")
		sliders[i]:SetMinMax(20, 100)
		sliders[i]:SetDecimals(0)
		sliders[i]:SetValue(GetConVar("textscreen_size" .. i))
		sliders[i]:SetConVar("textscreen_size" .. i)

		CPanel:AddItem(sliders[i])
		textBox[i] = vgui.Create("DTextEntry")
		textBox[i]:SetUpdateOnType(true)
		textBox[i]:SetEnterAllowed(true)
		textBox[i]:SetConVar("textscreen_text" .. i)
		textBox[i]:SetValue(GetConVar("textscreen_text" .. i):GetString())

		textBox[i].OnTextChanged = function()
			labels[i]:SetText(textBox[i]:GetValue())
		end

		if max_characters ~= 0 then
			textBox[i].AllowInput = function()
				if string.len(textBox[i]:GetValue()) >= max_characters then return true end
			end
		end

		CPanel:AddItem(textBox[i])

		labels[i] = CPanel:AddControl("Label", {
			Text = #GetConVar("textscreen_text" .. i):GetString() >= 1 and GetConVar("textscreen_text" .. i):GetString() or "Line " .. i,
			Description = "Line " .. i
		})

		labels[i]:SetFont(textscreenFonts[fontnum] .. "_MENU")
		labels[i]:SetAutoStretchVertical(true)
		labels[i]:SetDisabled(true)
		labels[i]:SetHeight(50)

		labels[i].Think = function()
			labels[i]:SetColor(
				Color(
					GetConVar("textscreen_r" .. i):GetInt(),
					GetConVar("textscreen_g" .. i):GetInt(),
					GetConVar("textscreen_b" .. i):GetInt(),
					GetConVar("textscreen_a" .. i):GetInt()
				)
			)
		end
	end
end
