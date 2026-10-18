local Lobby = {}
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
	for _, side in {-1, 1} do
		part("Rail", Vector3.new(1, 5, 90), Vector3.new(side * 50, 2.5, 280), Color3.fromRGB(100, 146, 166), Enum.Material.Glass).Transparency = 0.35
		part("Rail", Vector3.new(100, 5, 1), Vector3.new(0, 2.5, 280 + side * 45), Color3.fromRGB(100, 146, 166), Enum.Material.Glass).Transparency = 0.35
		part("Glow", Vector3.new(0.3, 0.1, 72), Vector3.new(side * 17, 0.1, 280), Color3.fromRGB(68, 215, 216), Enum.Material.Neon)
		for z = 260, 300, 40 do
			part("Bench", Vector3.new(12, 1, 3), Vector3.new(side * 34, 1.5, z), Color3.fromRGB(179, 126, 76), Enum.Material.Wood)
			part("BenchBack", Vector3.new(12, 3, 0.5), Vector3.new(side * 34, 2.5, z + 1.5), Color3.fromRGB(179, 126, 76), Enum.Material.Wood)
		end
	end
	local board = part("Welcome", Vector3.new(34, 12, 1), Vector3.new(0, 10, 241), Color3.fromRGB(23, 30, 48))
	local gui = Instance.new("SurfaceGui", board)
	gui.Face = Enum.NormalId.Back
	local title = Instance.new("TextLabel", gui)
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = "ELROBLO\nLOBBY"
	title.TextColor3 = Color3.fromRGB(109, 239, 227)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
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
