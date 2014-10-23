if SERVER then
	AddCSLuaFile()
	CreateConVar('sbox_maxtextscreens', "1", {FCVAR_NOTIFY, FCVAR_REPLICATED})
	CreateConVar('ss_call_to_home', "1", {FCVAR_NOTIFY, FCVAR_REPLICATED})

	function SSGetIP()
		local hostip = GetConVarString("hostip")
		hostip = tonumber(hostip)
		if not hostip or hostip == nil then
			return 0
		end
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
			if GetConVarNumber('ss_call_to_home') == 0 then return end
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
			s = s..string.char(math.random(65, 90))
		end
		return s
	end

	local textscreens = {}

	hook.Add("InitPostEntity", "loadTextScreens", function()
		timer.Simple(10, function()
			print("Spawning textscreens...")
			textscreens = file.Read("sammyservers_textscreens.txt", "DATA")
			if not textscreens then textscreens = {} return end
			textscreens = util.JSONToTable(textscreens)
			local i = 0
			for k, v in pairs(textscreens) do
				if v.MapName ~= game.GetMap() then continue end
				local textscreen = ents.Create("sammyservers_textscreen")
				textscreen:SetPos(Vector(v.posx, v.posy, v.posz))
				textscreen:SetAngles(Angle(v.angp, v.angy, v.angr))
				textscreen.uniqueName = v.uniqueName
				textscreen:Spawn()
				textscreen:Activate()
				textscreen:SetMoveType(MOVETYPE_NONE)
				textscreen:UpdateText(
					{v.text1, v.text2, v.text3, v.text4, v.text5},
					{Color(v.r1, v.g1, v.b1), Color(v.r2, v.g2, v.b2), Color(v.r3, v.g3, v.b3), Color(v.r4, v.g4, v.b4), Color(v.r5, v.g5, v.b5)},
					{v.size1, v.size2, v.size3, v.size4, v.size5}
				)
				textscreen.isPermaTextScreen = true
				textscreen:SetNWBool("isPermaTextScreen", true)
				i = i + 1
			end
			return print("Spawned "..i.." textscreens for map "..game.GetMap())
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
			local toAdd = {}
			local pos = ent:GetPos()
			local ang = ent:GetAngles()
			toAdd.posx = pos.x
			toAdd.posy = pos.y
			toAdd.posz = pos.z
			toAdd.angp = ang.p
			toAdd.angy = ang.y
			toAdd.angr = ang.r

			-- So we can reference it easilly later because EntIndexes are so unreliable
			toAdd.uniqueName = StringRandom(10)

			toAdd.MapName = game.GetMap()

			-- This should really use Data Tables nowadays...
			toAdd.r1 = ent:GetNWInt("r1", 255)
			toAdd.r2 = ent:GetNWInt("r2", 255)
			toAdd.r3 = ent:GetNWInt("r3", 255)
			toAdd.r4 = ent:GetNWInt("r4", 255)
			toAdd.r5 = ent:GetNWInt("r5", 255)

			toAdd.g1 = ent:GetNWInt("g1", 255)
			toAdd.g2 = ent:GetNWInt("g2", 255)
			toAdd.g3 = ent:GetNWInt("g3", 255)
			toAdd.g4 = ent:GetNWInt("g4", 255)
			toAdd.g5 = ent:GetNWInt("g5", 255)

			toAdd.b1 = ent:GetNWInt("b1", 255)
			toAdd.b2 = ent:GetNWInt("b2", 255)
			toAdd.b3 = ent:GetNWInt("b3", 255)
			toAdd.b4 = ent:GetNWInt("b4", 255)
			toAdd.b5 = ent:GetNWInt("b5", 255)

			toAdd.a1 = ent:GetNWInt("a1", 255)
			toAdd.a2 = ent:GetNWInt("a2", 255)
			toAdd.a3 = ent:GetNWInt("a3", 255)
			toAdd.a4 = ent:GetNWInt("a4", 255)
			toAdd.a5 = ent:GetNWInt("a5", 255)

			toAdd.size1 = ent:GetNWInt("size1", 20)
			toAdd.size2 = ent:GetNWInt("size2", 20)
			toAdd.size3 = ent:GetNWInt("size3", 20)
			toAdd.size4 = ent:GetNWInt("size4", 20)
			toAdd.size5 = ent:GetNWInt("size5", 20)

			toAdd.text1 = ent:GetNWString("text1", "")
			toAdd.text2 = ent:GetNWString("text2", "")
			toAdd.text3 = ent:GetNWString("text3", "")
			toAdd.text4 = ent:GetNWString("text4", "")
			toAdd.text5 = ent:GetNWString("text5", "")

			table.insert(textscreens, toAdd)
			file.Write("sammyservers_textscreens.txt", util.TableToJSON(textscreens))
			ent.isPermaTextScreen = true
			ent:SetNWBool("isPermaTextScreen", true)

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
			if ent:GetNWBool("isPermaTextScreen") == true then return false end
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
			if ent:GetNWBool("isPermaTextScreen") ~= true then return false end
			return ply:IsAdmin()
		end,

		Action = function(self, ent)
			if not IsValid(ent) then return end
			return RunConsoleCommand("SS_TextScreen", "delete", ent:EntIndex())
		end
	})

end