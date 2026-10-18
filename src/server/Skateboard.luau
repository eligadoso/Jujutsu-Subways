local Skateboard = {}

function Skateboard.equip(character, humanoid, root)
	if character:FindFirstChild("Skateboard") then return end
	local footDistance = root.Size.Y / 2 + humanoid.HipHeight
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = character:FindFirstChild("Left Leg")
		footDistance += leg and leg.Size.Y or 2
	end
	-- Lift the rider enough to fit the deck and wheels above the track.
	humanoid.HipHeight += 0.65
	local model = Instance.new("Model")
	model.Name = "Skateboard"
	local origin = root.CFrame * CFrame.new(0, -footDistance - 0.12, 0)

	local function piece(name, size, offset, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = origin * CFrame.new(offset)
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Shape = shape or Enum.PartType.Block
		p.Anchored = false
		p.Massless = true
		p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		if model.PrimaryPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1 = model.PrimaryPart, p
			weld.Parent = p
		else
			local mount = Instance.new("Weld")
			mount.Name = "SkateboardMount"
			mount.Part0, mount.Part1 = root, p
			mount.C0 = root.CFrame:ToObjectSpace(p.CFrame)
			mount.Parent = p
		end
		return p
	end

	local orange = Color3.fromRGB(255, 119, 43)
	local black = Color3.fromRGB(27, 31, 40)
	local metal = Color3.fromRGB(170, 181, 193)
	model.PrimaryPart = piece("Deck", Vector3.new(2.6, 0.2, 3.6), Vector3.zero, orange, Enum.Material.Wood)
	for _, direction in {-1, 1} do
		piece("RoundedTip", Vector3.new(2.6, 0.2, 1.4), Vector3.new(0, 0, direction * 1.8), orange, nil, Enum.PartType.Ball)
	end
	piece("GripTape", Vector3.new(2.35, 0.035, 3.65), Vector3.new(0, 0.115, 0), black, Enum.Material.Asphalt)
	piece("CenterStripe", Vector3.new(0.16, 0.015, 3.6), Vector3.new(0, 0.14, 0), Color3.fromRGB(57, 220, 230), Enum.Material.Neon)
	for _, z in {-1.5, 1.5} do
		piece("Truck", Vector3.new(0.6, 0.24, 0.45), Vector3.new(0, -0.2, z), metal, Enum.Material.Metal)
		piece("Axle", Vector3.new(2.8, 0.14, 0.14), Vector3.new(0, -0.3, z), metal, Enum.Material.Metal)
		for _, side in {-1, 1} do
			piece("Wheel", Vector3.new(0.38, 0.56, 0.56), Vector3.new(side * 1.35, -0.3, z), Color3.fromRGB(240, 236, 213), nil, Enum.PartType.Cylinder)
			piece("WheelHub", Vector3.new(0.4, 0.22, 0.22), Vector3.new(side * 1.35, -0.3, z), black, Enum.Material.Metal, Enum.PartType.Cylinder)
		end
	end
	model.Parent = character
	character:SetAttribute("Skateboarding", true)
end

return Skateboard
