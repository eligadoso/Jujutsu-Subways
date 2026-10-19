local CoinModel = {}

function CoinModel.create(position, value, parent)
	local model = Instance.new("Model")
	model.Name = "Coin"
	model:SetAttribute("Value", value)
	local frame = CFrame.new(position) * CFrame.Angles(0, math.pi / 2, 0)
	local function piece(name, size, offset, color, cylinder)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame = name, size, frame * offset
		p.Color, p.Material = color, Enum.Material.Metal
		p.Reflectance = 0.12
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.CastShadow = false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if cylinder then p.Shape = Enum.PartType.Cylinder end
		p.Parent = model
		return p
	end
	local core = piece("MilledRim", Vector3.new(0.28, 1.65, 1.65), CFrame.identity, Color3.fromRGB(255, 204, 55), true)
	core:SetAttribute("Value", value)
	model.PrimaryPart = core
	for _, side in {-1, 1} do
		piece("InsetFace", Vector3.new(0.025, 1.34, 1.34), CFrame.new(side * 0.15, 0, 0), Color3.fromRGB(206, 136, 24), true)
		piece("RaisedEmblem", Vector3.new(0.045, 0.57, 0.57), CFrame.new(side * 0.18, 0, 0) * CFrame.Angles(math.pi / 4, 0, 0), Color3.fromRGB(255, 231, 129), false)
	end
	model.Parent = parent
	return model, core
end

return CoinModel
