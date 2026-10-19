local Lobby = {}
local Style = require(script.Parent:WaitForChild("VisualStyle"))
local Brand = require(game:GetService("ReplicatedStorage").Shared:WaitForChild("Brand"))
Lobby.Position = Vector3.new(0, 4, 280)

function Lobby.build()
	local folder = Instance.new("Folder", workspace)
	folder.Name = "Lobby"
	local function part(name, size, position, color, material)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position, p.Color = name, size, position, color
		p.Anchored = true
		p.Material = material or Enum.Material.SmoothPlastic
		p.Parent = folder
		return p
	end
	part("Plaza", Vector3.new(100, 2, 90), Vector3.new(0, -1, 280), Color3.fromRGB(42, 51, 72), Enum.Material.Concrete)
	part("Center", Vector3.new(28, 0.1, 28), Vector3.new(0, 0.05, 280), Color3.fromRGB(63, 88, 118))
	for tile = -40, 40, 10 do
		Style.detail(folder, "PlazaJoint", Vector3.new(90, 0.015, 0.08), CFrame.new(0, 0.02, 280 + tile), Color3.fromRGB(78, 92, 112))
	end
	for _, side in {-1, 1} do
		part("Rail", Vector3.new(1, 5, 90), Vector3.new(side * 50, 2.5, 280), Color3.fromRGB(100, 146, 166), Enum.Material.Glass).Transparency = 0.35
		part("Rail", Vector3.new(100, 5, 1), Vector3.new(0, 2.5, 280 + side * 45), Color3.fromRGB(100, 146, 166), Enum.Material.Glass).Transparency = 0.35
		part("Glow", Vector3.new(0.3, 0.1, 72), Vector3.new(side * 17, 0.1, 280), Color3.fromRGB(68, 215, 216), Enum.Material.Neon)
		for z = 260, 300, 40 do
			part("Planter", Vector3.new(5, 2.3, 5), Vector3.new(side * 42, 1.15, z), Color3.fromRGB(78, 91, 105), Enum.Material.Concrete)
			Style.detail(folder, "Shrub", Vector3.new(4.3, 2, 4.3), CFrame.new(side * 42, 2.7, z), Color3.fromRGB(65, 125, 102), Enum.Material.Grass)
			part("Bench", Vector3.new(12, 1, 3), Vector3.new(side * 34, 1.5, z), Color3.fromRGB(179, 126, 76), Enum.Material.Wood)
			part("BenchBack", Vector3.new(12, 3, 0.5), Vector3.new(side * 34, 2.5, z + 1.5), Color3.fromRGB(179, 126, 76), Enum.Material.Wood)
		end
	end
	local board = part("Welcome", Vector3.new(24, 18, 1), Vector3.new(0, 12, 241), Brand.Ink)
	local gui = Instance.new("SurfaceGui", board)
	gui.Face = Enum.NormalId.Back
	gui.SizingMode, gui.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Brand.LogoResolution
	gui.LightInfluence = 0.1
	Brand.logo(gui, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0))
	for _, side in {-1, 1} do
		Style.detail(folder, "WelcomeEnergy", Vector3.new(0.2, 18, 0.2), CFrame.new(side * 12.2, 12, 241.6), Brand.Purple, Enum.Material.Neon)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Position, spawn.Size = Vector3.new(0, 0.1, 280), Vector3.new(8, 0.2, 8)
	spawn.Anchored, spawn.Neutral = true, true
	spawn.Transparency, spawn.Duration = 1, 0
	spawn.CanCollide = false
	spawn.Parent = folder
end

function Lobby.place(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return false end
	root.CFrame = CFrame.new(Lobby.Position + Vector3.new((player.UserId % 5 - 2) * 4, 0, 0))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	root:SetNetworkOwnershipAuto()
	humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16
	player:SetAttribute("SessionState", "Lobby")
	player:SetAttribute("TrackOriginX", 0)
	return true
end

return Lobby
