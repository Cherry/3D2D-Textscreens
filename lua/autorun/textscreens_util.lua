if SERVER then
	AddCSLuaFile()
	CreateConVar("sbox_maxtextscreens", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED})
	CreateConVar("ss_call_to_home", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED})

	function SSGetIP()
		local hostip = GetConVar("hostip"):GetString()
		hostip = tonumber(hostip)
		if not hostip or hostip == nil then return 0 end
		local ip = {}
		ip[1] = bit.rshift(bit.band(hostip, 0xFF000000), 24)
		ip[2] = bit.rshift(bit.band(hostip, 0x00FF0000), 16)
		ip[3] = bit.rshift(bit.band(hostip, 0x0000FF00), 8)
		ip[4] = bit.band(hostip, 0x000000FF)

		return table.concat(ip, ".")
	end

	-- You can opt out of this call-to-home if you'd like, I just like stats.
	-- These won't be used for anything other than putting a smile on my face :)
	-- Set ss_call_to_home to 0 to opt out
	hook.Add("Initialize", "CallToHomeSS", function()
		timer.Simple(15, function()
			if GetConVar("ss_call_to_home"):GetInt() == 0 then return end
			local ip = SSGetIP()
			if ip == 0 then return end

			http.Post("http://sammyservers.com/misc/index.php", {
				["server_name"] = GetHostName(),
				["server_ip"] = util.CRC(ip)
			})
		end)
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

	hook.Add("InitPostEntity", "loadTextScreens", function()
		timer.Simple(10, function()
			print("Spawning textscreens...")
			textscreens = file.Read("sammyservers_textscreens.txt", "DATA")

			if not textscreens then textscreens = {} return	end

			textscreens = util.JSONToTable(textscreens)
			local count = 0

			for k, v in pairs(textscreens) do
				if v.MapName ~= game.GetMap() then continue end
				local textScreen = ents.Create("sammyservers_textscreen")
				textScreen:SetPos(Vector(v.posx, v.posy, v.posz))
				textScreen:SetAngles(Angle(v.angp, v.angy, v.angr))
				textScreen.uniqueName = v.uniqueName
				textScreen:Spawn()
				textScreen:Activate()
				textScreen:SetMoveType(MOVETYPE_NONE)

				for k, v in pairs(v.lines or {}) do
					textScreen:SetLine(k, v.text, Color(v.color.r, v.color.g, v.color.b, v.color.a), v.size)
				end

				textScreen:SetIsPersisted(true)
				count = count + 1
			end

			return print("Spawned " .. count .. " textscreens for map " .. game.GetMap())
		end)
	end)

	concommand.Add("SS_TextScreen", function(ply, cmd, args)
		if not ply:IsSuperAdmin() or not args or not args[1] or not args[2] or not (args[1] == "delete" or args[1] == "add") then
			ply:ChatPrint("not authorised, or bad arguments")
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
			-- So we can reference it easilly later because EntIndexes are so unreliable
			toAdd.uniqueName = StringRandom(10)
			toAdd.MapName = game.GetMap()
			toAdd.lines = ent.lines
			table.insert(textscreens, toAdd)
			file.Write("sammyservers_textscreens.txt", util.TableToJSON(textscreens))
			ent:SetIsPersisted(true)

			return ply:ChatPrint("Textscreen made permament and saved.")
		else
			for k, v in pairs(textscreens) do
				if v.uniqueName == ent.uniqueName then
					textscreens[k] = nil
				end
			end

			ent:Remove()
			file.Write("sammyservers_textscreens.txt", util.TableToJSON(textscreens))

			return ply:ChatPrint("Textscreen removed and is no longer permanent.")
		end
	end)
end

if CLIENT then
	properties.Add("addPermaScreen", {
		MenuLabel = "Make perma textscreen",
		Order = 2001,
		MenuIcon = "icon16/transmit.png",
		Filter = function(self, ent, ply)
			if not IsValid(ent) or ent:GetClass() ~= "sammyservers_textscreen" then return false end
			if ent:GetIsPersisted() then return false end

			return ply:IsAdmin()
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

			return ply:IsAdmin()
		end,
		Action = function(self, ent)
			if not IsValid(ent) then return end

			return RunConsoleCommand("SS_TextScreen", "delete", ent:EntIndex())
		end
	})
end