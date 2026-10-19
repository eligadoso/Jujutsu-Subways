local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Brand = require(Shared:WaitForChild("Brand"))
local player = Players.LocalPlayer
local currentDeck
local objects, trails = {}, {}

local function clear()
	for _, object in objects do object:Destroy() end
	objects, trails, currentDeck = {}, {}, nil
end

local function attach(deck)
	currentDeck = deck
	for _, side in {-1, 1} do
		local first, second = Instance.new("Attachment"), Instance.new("Attachment")
		first.Position, second.Position = Vector3.new(side * 1.05, -0.12, 1.65), Vector3.new(side * 1.05, 0.02, 1.65)
		first.Parent, second.Parent = deck, deck
		local trail = Instance.new("Trail")
		trail.Name, trail.Attachment0, trail.Attachment1 = "SkateSlipstream", first, second
		trail.Color = ColorSequence.new(Brand.Cyan, Brand.Purple)
		trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)})
		trail.WidthScale = NumberSequence.new(1, 0)
		trail.Lifetime, trail.MinLength, trail.FaceCamera = 0.18, 0.1, true
		trail.LightEmission, trail.Enabled = 0.6, false
		trail.Parent = deck
		table.insert(objects, first); table.insert(objects, second); table.insert(objects, trail)
		table.insert(trails, trail)
	end
end

RunService:BindToRenderStep("RunnerSkateEffects", Enum.RenderPriority.Character.Value + 5, function()
	local character = player.Character
	local board = character and character:FindFirstChild("Skateboard")
	local deck = board and board.PrimaryPart
	if deck ~= currentDeck then clear(); if deck then attach(deck) end end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local state = player:GetAttribute("SessionState")
	local active = (state == "Race" or state == "Solo") and humanoid and humanoid.Health > 0
	local speed = if root then math.max(0, -root.AssemblyLinearVelocity.Z) else 0
	local protected = (player:GetAttribute("RecoveringUntil") or 0) > workspace:GetServerTimeNow()
	local enabled = active and root and Config.MotionEffects.Enabled and Config.MotionEffects.Intensity > 0
		and not protected and humanoid.FloorMaterial ~= Enum.Material.Air and speed > 30
	for _, trail in trails do
		trail.Enabled = enabled == true
		trail.Lifetime = 0.12 + math.clamp((speed - 30) / 30, 0, 1) * 0.12 * math.clamp(Config.MotionEffects.Intensity, 0, 1)
		if not enabled then trail:Clear() end
	end
end)

player.CharacterRemoving:Connect(clear)
return true
