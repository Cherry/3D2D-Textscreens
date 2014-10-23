include("shared.lua")

for i=1, 100 do
	surface.CreateFont("CV"..tostring(i), {
		font ="coolvetica",
		size = i,
		weight = 400,
		antialias = false,
		outline = true
	})
end

function ENT:Initialize()
	self:SetMaterial("models/effects/vol_light001")
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(255, 255, 255, 1)
end

function ENT:Draw()	
	if self:GetPos():Distance(LocalPlayer():GetPos()) < 1500 then
		self:DrawModel()
		local ang = self:GetAngles()
		local pos = self:GetPos() + ang:Up()
		local camangle = Angle(ang.p, ang.y, ang.r)
		local lines = {}
		for i = 1, 5 do
			if self:GetNWString("Text"..i) ~= "" then
				table.insert(lines, {text = self:GetNWString("Text"..i), r = self:GetNWInt("r"..i), g = self:GetNWInt("g"..i), b = self:GetNWInt("b"..i), a = self:GetNWInt("a"..i), size = self:GetNWInt("size"..i)})
			end
		end
		local totheight = 0
		for k, v in pairs(lines) do
			v.size = v.size > 100 and 100 or v.size
			surface.SetFont("CV"..v.size)
			TextWidth, TextHeight = surface.GetTextSize(v.text)
			lines[k].twidth = TextWidth
			lines[k].theight = TextHeight
			totheight = totheight + TextHeight
		end
		cam.Start3D2D(pos, camangle, .25)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
			local curheight = 0
			for k, v in pairs(lines) do
				local fontcolor = Color(v.r, v.g, v.b, v.a)
				draw.DrawText(v.text, "CV"..v.size, 0, -(totheight/2)+curheight, fontcolor, TEXT_ALIGN_CENTER)
				curheight = curheight + v.theight
			end
			render.PopFilterMin()
		cam.End3D2D()
		camangle:RotateAroundAxis(camangle:Right(), 180)
		cam.Start3D2D(pos, camangle, .25)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
			local curheight = 0
			for k, v in pairs(lines) do
				local fontcolor = Color(v.r, v.g, v.b, v.a)
				draw.DrawText(v.text, "CV"..v.size, 0, -(totheight/2)+curheight, fontcolor, TEXT_ALIGN_CENTER)
				curheight = curheight + v.theight
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
