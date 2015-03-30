TOOL.Category		= "Construction"
TOOL.Name			= "#Tool.textscreen.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

local textBox = {}
local lineLabels = {}
local labels = {}
local sliders = {}
for i = 1, 5 do
	TOOL.ClientConVar[ "text"..i ] = ""
	TOOL.ClientConVar[ "size"..i ] = 20
	TOOL.ClientConVar[ "r"..i ] = 255
	TOOL.ClientConVar[ "g"..i ] = 255
	TOOL.ClientConVar[ "b"..i ] = 255
	TOOL.ClientConVar[ "a"..i ] = 255
end

cleanup.Register("textscreens")

if (CLIENT) then
	language.Add("Tool.textscreen.name", "3D2D Textscreen")
	language.Add("Tool.textscreen.desc", "Create a textscreen with multiple lines, font colours and sizes.")

	language.Add("Tool.textscreen.0", "Left Click: Spawn a textscreen Right Click: Update textscreen with settings")
	language.Add("Tool_textscreen_0", "Left Click: Spawn a textscreen Right Click: Update textscreen with settings")

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

	if not (self:GetWeapon():CheckLimit("textscreens")) then return false end

	local textScreen = ents.Create("sammyservers_textscreen")
	textScreen:SetPos(tr.HitPos)
	local angle = tr.HitNormal:Angle()
	angle:RotateAroundAxis(tr.HitNormal:Angle():Right(), -90)
	angle:RotateAroundAxis(tr.HitNormal:Angle():Forward(), 90)
	textScreen:SetAngles(angle)
	textScreen:Spawn()
	textScreen:Activate()
	for i = 1, 5 do
		textScreen:SetLine(
			i, -- Line
			self:GetClientInfo("text"..i), -- text
			Color( -- Color
				tonumber(self:GetClientInfo("r"..i)), 
				tonumber(self:GetClientInfo("g"..i)), 
				tonumber(self:GetClientInfo("b"..i)), 
				tonumber(self:GetClientInfo("a"..i))
			),
			tonumber(self:GetClientInfo("size"..i))
		)
	end

	undo.Create("textscreens")
	undo.AddEntity(textScreen)
	undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCount("textscreens", textScreen)
	ply:AddCleanup("textscreens", textScreen)

	return true
end

function TOOL:RightClick(tr)
	if (tr.Entity:GetClass() == "player") then return false end
	if (CLIENT) then return true end

	local TraceEnt = tr.Entity

	if (IsValid(TraceEnt) and TraceEnt:GetClass() == "sammyservers_textscreen") then
		for i = 1, 5 do
			TraceEnt:SetLine(
				i, -- Line
				tostring(self:GetClientInfo("text"..i)), -- text
				Color( -- Color
					tonumber(self:GetClientInfo("r"..i)), 
					tonumber(self:GetClientInfo("g"..i)), 
					tonumber(self:GetClientInfo("b"..i)), 
					tonumber(self:GetClientInfo("a"..i))
				),
				tonumber(self:GetClientInfo("size"..i))
			)
		end
		TraceEnt:Broadcast()
		return true
	end
end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Text = "#Tool.textscreen.name", Description = "#Tool.textscreen.desc"})
	CPanel:AddControl("Label", {Text = "By NodeCraft.com - affordable, high performance game servers!"})
	resetall = vgui.Create("DButton", resetbuttons)
	resetall:SetSize(100, 25)
	resetall:SetText("Reset all")
	resetall.DoClick = function()
		local menu = DermaMenu()
		menu:AddOption("Reset colors", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_r"..i, 255)
				RunConsoleCommand("textscreen_g"..i, 255)
				RunConsoleCommand("textscreen_b"..i, 255)
				RunConsoleCommand("textscreen_a"..i, 255)
			end
		end)
		menu:AddOption("Reset sizes", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_size"..i, 20)
				sliders[i]:SetValue(20)
			end
		end)
		menu:AddOption("Reset textboxes", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_text"..i, "")
				textBox[i]:SetValue("")
			end
		end)
		menu:AddOption("Reset everything", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_r"..i, 255)
				RunConsoleCommand("textscreen_g"..i, 255)
				RunConsoleCommand("textscreen_b"..i, 255)
				RunConsoleCommand("textscreen_a"..i, 255)
				RunConsoleCommand("textscreen_size"..i, 20)
				sliders[i]:SetValue(20)
				RunConsoleCommand("textscreen_text"..i, "")
				textBox[i]:SetValue("")
			end
		end)
		menu:Open()
	end
	CPanel:AddItem(resetall)
	resetline = vgui.Create("DButton")
	resetline:SetSize(100, 25)
	resetline:SetText("Reset line")
	resetline.DoClick = function()
		local menu = DermaMenu()
		for i = 1, 5 do
			menu:AddOption("Reset line "..i, function()
				RunConsoleCommand("textscreen_r"..i, 255)
				RunConsoleCommand("textscreen_g"..i, 255)
				RunConsoleCommand("textscreen_b"..i, 255)
				RunConsoleCommand("textscreen_a"..i, 255)
				RunConsoleCommand("textscreen_size"..i, 20)
				sliders[i]:SetValue(20)
				RunConsoleCommand("textscreen_text"..i, "")
				textBox[i]:SetValue("")
			end)
		end
		menu:AddOption("Reset all lines", function()
			for i = 1, 5 do
				RunConsoleCommand("textscreen_r"..i, 255)
				RunConsoleCommand("textscreen_g"..i, 255)
				RunConsoleCommand("textscreen_b"..i, 255)
				RunConsoleCommand("textscreen_a"..i, 255)
				RunConsoleCommand("textscreen_size"..i, 20)
				sliders[i]:SetValue(20)
				RunConsoleCommand("textscreen_text"..i, "")
				textBox[i]:SetValue("")
			end
		end)
		menu:Open()
	end
	CPanel:AddItem(resetline)

	for i = 1, 5 do
		lineLabels[i] = CPanel:AddControl("Label", {
			Text = "Line "..i,
			Description = "Line "..i
		})
		lineLabels[i]:SetFont("Default")
		CPanel:AddControl("Color", {
			Label = "Line "..i.." font color",
			Red = "textscreen_r"..i,
			Green = "textscreen_g"..i,
			Blue = "textscreen_b"..i,
			Alpha = "textscreen_a"..i,
			ShowHSV = 1,
			ShowRGB = 1,
			Multiplier = 255
		})
		sliders[i] = vgui.Create("DNumSlider")
		sliders[i]:SetText("Font size")
		sliders[i]:SetMinMax(20, 100)
		sliders[i]:SetDecimals(0)
		sliders[i]:SetValue(20)
		sliders[i]:SetConVar("textscreen_size"..i)
		sliders[i].OnValueChanged = function(panel, value)
			labels[i]:SetFont("CV"..math.Round(value))
		end
		CPanel:AddItem(sliders[i])
		textBox[i] = vgui.Create("DTextEntry")
		textBox[i]:SetUpdateOnType(true)
		textBox[i]:SetEnterAllowed(true)
		textBox[i]:SetConVar("textscreen_text"..i)
		textBox[i]:SetValue(GetConVarString("textscreen_text"..i))
		textBox[i].OnTextChanged = function()
			labels[i]:SetText(textBox[i]:GetValue())
		end
		CPanel:AddItem(textBox[i])
		labels[i] = CPanel:AddControl("Label", {
			Text = "Line "..i,
			Description = "Line "..i
		})
		labels[i]:SetFont("Default")
		labels[i].Think = function()
			labels[i]:SetColor(Color(GetConVarNumber("textscreen_r"..i), GetConVarNumber("textscreen_g"..i), GetConVarNumber("textscreen_b"..i), GetConVarNumber("textscreen_a"..i)))
		end
	end
end