include("shared.lua")
ENT.RenderGroup = RENDERGROUP_BOTH

local render_range = CreateClientConVar("ss_render_range", 1500, true, false, "Determines the render range for Textscreens. Default 1500")

for i = 1, 100 do
	surface.CreateFont("CV" .. tostring(i), {
		font = "coolvetica",
		size = i,
		weight = 400,
		antialias = false,
		outline = true
	})
end

function ENT:Initialize()
	self:SetMaterial("models/effects/vol_light001")
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(255, 255, 255, 1))
	self.lines = self.lines or {}
	net.Start("textscreens_download")
	net.WriteEntity(self)
	net.SendToServer()
end

function ENT:Draw()
	if self:GetPos():Distance(LocalPlayer():GetPos()) < render_range:GetInt() then
		local ang = self:GetAngles()
		local pos = self:GetPos() + ang:Up()
		local camangle = Angle(ang.p, ang.y, ang.r)
		self.lines = self.lines or {}
		local totheight = 0

		for k, v in pairs(self.lines) do
			v.size = tonumber(v.size) > 100 and 100 or v.size
			surface.SetFont("CV" .. math.Clamp(v.size, 1, 100))
			TextWidth, TextHeight = surface.GetTextSize(v.text)
			self.lines[k].width = TextWidth
			self.lines[k].height = TextHeight
			totheight = totheight + TextHeight
		end

		cam.Start3D2D(pos, camangle, .25)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		local curheight = 0

		for k, v in pairs(self.lines) do
			draw.DrawText(v.text, "CV" .. math.Clamp(v.size, 1, 100), 0, -(totheight / 2) + curheight, v.color, TEXT_ALIGN_CENTER)
			curheight = curheight + v.height
		end

		render.PopFilterMin()
		cam.End3D2D()
		camangle:RotateAroundAxis(camangle:Right(), 180)
		cam.Start3D2D(pos, camangle, .25)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		local curheight = 0

		for k, v in pairs(self.lines) do
			draw.DrawText(v.text, "CV" .. math.Clamp(v.size, 1, 100), 0, -(totheight / 2) + curheight, v.color, TEXT_ALIGN_CENTER)
			curheight = curheight + v.height
		end

		render.PopFilterMin()
		cam.End3D2D()
	end
end

function ENT:DrawTranslucent()
	self:Draw()
end

function ENT:Think()
end

net.Receive("textscreens_update", function(len)
	local ent = net.ReadEntity()

	if IsValid(ent) and ent:GetClass() == "sammyservers_textscreen" then
		ent.lines = net.ReadTable()
	end
end)