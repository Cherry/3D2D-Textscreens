local function checkAdmin(ply)
	-- The server console always has access. `ply` is NULL in this case
	local isConsole = ply == nil or ply == NULL
	if isConsole then
		return true
	end
	local canAdmin = hook.Run("TextscreensCanAdmin", ply) -- run custom hook function to check admin
	if canAdmin == nil then -- if hook hasn't returned anything, default to super admin check
		canAdmin = ply:IsSuperAdmin()
	end
	return canAdmin
end

-- allow servers to disable rainbow effect for everyone
CreateConVar("ss_enable_rainbow", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Determines whether rainbow textscreens will render for all clients. When disabled, rainbow screens will render as solid white.", 0, 1)

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("textscreens_config.lua")
	include("textscreens_config.lua")
	CreateConVar("sbox_maxtextscreens", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Determines the maximum number of textscreens users can spawn.")
	CreateConVar("ss_call_to_home", 0, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Determines whether anonymous usage analytics can be sent to the addon author.", 0, 1)

	--local rainbow_enabled = cvars.Number('ss_enable_rainbow', 1)

	local version = "1.18.1"

	local function GetOS()
		if system.IsLinux() then return "linux" end
		if system.IsWindows() then return "windows" end
		if system.IsOSX() then return "osx" end
		return "unknown"
	end

	local submitted = false
	local function submitAnalytics()
		if GetConVar("ss_call_to_home"):GetInt() ~= 1 or submitted then return end

		submitted = true
		http.Post("https://jross.me/textscreens/analytics.php", {
			["operating_system"] = GetOS(),
			["server_dedicated"] = game.IsDedicated() and "true" or "false",
			["server_name"] = GetHostName(),
			["server_ip"] = util.CRC(game.GetIPAddress()),
			["version"] = version
		})
	end

	-- Set ss_call_to_home to 1 to opt-in to anonymous stat tracking
	-- These won't be used for anything other than putting a smile on my face :)
	hook.Add("Initialize", "CallToHomeSS", function()
		timer.Simple(15, function()
			submitAnalytics()
		end)
	end)

	cvars.AddChangeCallback("ss_call_to_home", function(convar_name, value_old, value_new)
		if value_new == "1" then
			submitAnalytics()
		end
	end)

	local function StringRandom(int)
		math.randomseed(os.time())
		local s = ""

		for i = 1, int do
			s = s .. string.char(math.random(65, 90))
		end

		return s
	end

	local textscreens = {}

	local function SpawnPermaTextscreens()
		print("[3D2D Textscreens] Spawning textscreens...")
		textscreens = file.Read("sammyservers_textscreens.txt", "DATA")
		if not textscreens or textscreens == "" then
			textscreens = {}
			print("[3D2D Textscreens] Spawned 0 textscreens for map " .. game.GetMap())
			return
		end
		textscreens = util.JSONToTable(textscreens)

		local existingTextscreens = {}
		for k,v in pairs(ents.FindByClass("sammyservers_textscreen")) do
			if not v.uniqueName then continue end
			existingTextscreens[v.uniqueName] = true
		end

		local count = 0
		for k, v in pairs(textscreens) do
			if v.MapName ~= game.GetMap() then continue end
			if existingTextscreens[v.uniqueName] then continue end

			local textScreen = ents.Create("sammyservers_textscreen")
			textScreen:SetPos(Vector(v.posx, v.posy, v.posz))
			textScreen:SetAngles(Angle(v.angp, v.angy, v.angr))
			textScreen.uniqueName = v.uniqueName
			textScreen:Spawn()
			textScreen:Activate()
			textScreen:SetMoveType(MOVETYPE_NONE)

			for lineNum, lineData in pairs(v.lines or {}) do
				textScreen:SetLine(lineNum, lineData.text, Color(lineData.color.r, lineData.color.g, lineData.color.b, lineData.color.a), lineData.size, lineData.font, lineData.rainbow or 0)
			end

			textScreen:SetIsPersisted(true)
			count = count + 1
		end

		print("[3D2D Textscreens] Spawned " .. count .. " textscreens for map " .. game.GetMap())
	end

	hook.Add("InitPostEntity", "loadTextScreens", function()
		timer.Simple(10, SpawnPermaTextscreens)
	end)

	hook.Add("PostCleanupMap", "loadTextScreens", SpawnPermaTextscreens)

	-- If a player, use ChatPrint method, else print directly to server console
	local function printMessage(ply, msg)
		local isConsole = ply == nil or ply == NULL
		if isConsole then
			print(msg)
		else
			ply:ChatPrint(msg)
		end
	end
	concommand.Add("SS_TextScreen", function(ply, cmd, args)
		if not checkAdmin(ply) or not args or not args[1] or not args[2] or not (args[1] == "delete" or args[1] == "add") then
			printMessage(ply, "not authorised, or bad arguments")
			return
		end
		local ent = Entity(args[2])
		if not IsValid(ent) or ent:GetClass() ~= "sammyservers_textscreen" then return false end

		if args[1] == "add" then
			local pos = ent:GetPos()
			local ang = ent:GetAngles()
			local toAdd = {}
			toAdd.posx = pos.x
			toAdd.posy = pos.y
			toAdd.posz = pos.z
			toAdd.angp = ang.p
			toAdd.angy = ang.y
			toAdd.angr = ang.r
			-- So we can reference it easily later because EntIndexes are so unreliable
			toAdd.uniqueName = StringRandom(10)
			toAdd.MapName = game.GetMap()
			toAdd.lines = ent.lines
			table.insert(textscreens, toAdd)
			file.Write("sammyservers_textscreens.txt", util.TableToJSON(textscreens))
			ent:SetIsPersisted(true)

			return printMessage(ply, "Textscreen made permanent and saved.")
		else
			for k, v in pairs(textscreens) do
				if v.uniqueName == ent.uniqueName then
					textscreens[k] = nil
				end
			end

			ent:Remove()
			file.Write("sammyservers_textscreens.txt", util.TableToJSON(textscreens))

			return printMessage(ply, "Textscreen removed and is no longer permanent.")
		end
	end)

	-- Add to pocket blacklist for DarkRP
	-- Not using gamemode == "darkrp" because there are lots of flavours of darkrp
	hook.Add("loadCustomDarkRPItems", "sammyservers_pocket_blacklist", function()
		GAMEMODE.Config.PocketBlacklist["sammyservers_textscreen"] = true
	end)
end

if CLIENT then
	include("textscreens_config.lua")

	properties.Add("addPermaScreen", {
		MenuLabel = "Make perma textscreen",
		Order = 2001,
		MenuIcon = "icon16/transmit.png",
		Filter = function(self, ent, ply)
			if not IsValid(ent) or ent:GetClass() ~= "sammyservers_textscreen" then return false end
			if ent:GetIsPersisted() then return false end

			return checkAdmin(ply)
		end,
		Action = function(self, ent)
			if not IsValid(ent) then return false end

			return RunConsoleCommand("SS_TextScreen", "add", ent:EntIndex())
		end
	})

	properties.Add("removePermaScreen", {
		MenuLabel = "Remove perma textscreen",
		Order = 2002,
		MenuIcon = "icon16/transmit_delete.png",
		Filter = function(self, ent, ply)
			if not IsValid(ent) or ent:GetClass() ~= "sammyservers_textscreen" then return false end
			if not ent:GetIsPersisted() then return false end

			return checkAdmin(ply)
		end,
		Action = function(self, ent)
			if not IsValid(ent) then return end

			return RunConsoleCommand("SS_TextScreen", "delete", ent:EntIndex())
		end
	})
end
