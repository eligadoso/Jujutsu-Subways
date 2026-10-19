local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "SpeedWind", false, true, -1
gui.Parent = player:WaitForChild("PlayerGui")
local streaks = {}
for i = 1, 24 do
	local line = Instance.new("Frame")
	line.Name, line.BorderSizePixel, line.AnchorPoint = "Wind", 0, Vector2.new(0.5, 0.5)
	line.BackgroundColor3 = if i % 3 == 0 then Color3.fromRGB(124, 220, 255) else Color3.fromRGB(231, 246, 255)
	line.BackgroundTransparency = 1
	line.Parent = gui
	local gradient = Instance.new("UIGradient", line)
	gradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.2), NumberSequenceKeypoint.new(1, 1)})
	streaks[i] = {line = line, phase = i / 24, angle = i * 2.399963}
end
local strength = 0
local lastRoot, lastSpeed, gust = nil, 0, 0
local steering = 0
RunService:BindToRenderStep("RunnerWind", Enum.RenderPriority.Camera.Value + 40, function(dt)
	local camera = workspace.CurrentCamera
	local watching = player:GetAttribute("Spectating") == true
	local subject = if watching then Players:GetPlayerByUserId(player:GetAttribute("SpectateTarget") or 0) else player
	local state = player:GetAttribute("SessionState")
	local root = subject and subject.Character and subject.Character:FindFirstChild("HumanoidRootPart")
	local active = watching or state == "Race" or state == "Solo"
	local speed = if active and root then math.max(0, -root.AssemblyLinearVelocity.Z) else 0
	if root ~= lastRoot then lastSpeed, gust = speed, 0 end
	local acceleration = math.max(0, speed - lastSpeed) / math.max(dt, 0.001)
	lastRoot, lastSpeed = root, speed
	gust += (math.clamp(acceleration / 24, 0, 1) - gust) * (1 - math.exp(-10 * math.min(dt, 0.1)))
	local boosted = subject and math.max(subject:GetAttribute("BoostUntil") or 0, subject:GetAttribute("DraftUntil") or 0) > workspace:GetServerTimeNow()
	local amount = math.clamp((speed - 16) / math.max(1, Config.Speed.Max - 16) + gust * 0.2 + (if boosted then 0.15 else 0), 0, 1)
	if not Config.MotionEffects.Enabled then amount = 0 end
	amount *= math.clamp(Config.MotionEffects.Intensity, 0, 1)
	strength += (amount - strength) * (1 - math.exp(-8 * math.min(dt, 0.1)))
	local lateral = if active and root then math.clamp(root.AssemblyLinearVelocity.X / 40, -1, 1) else 0
	steering += (lateral - steering) * (1 - math.exp(-10 * math.min(dt, 0.1)))
	gui.Enabled = camera ~= nil and strength > 0.005
	if not gui.Enabled then return end
	local size = camera.ViewportSize
	for _, streak in streaks do
		streak.line.BackgroundColor3 = if boosted then Color3.fromRGB(155, 228, 255) else Color3.fromRGB(231, 246, 255)
		streak.phase = (streak.phase + dt * (0.45 + strength * 1.3)) % 1
		local phase = streak.phase
		local radius = 0.66 + phase * 0.65
		local x, y = math.cos(streak.angle) * size.X * 0.55, math.sin(streak.angle) * size.Y * 0.62
		streak.line.Position = UDim2.fromOffset(size.X * (0.5 - steering * 0.04) + x * radius, size.Y * 0.48 + y * radius)
		streak.line.Rotation = math.deg(math.atan2(y, x))
		streak.line.Size = UDim2.fromOffset((28 + 95 * strength) * (0.5 + phase), 1 + strength)
		streak.line.BackgroundTransparency = 1 - math.sin(phase * math.pi) * strength * 0.5
	end
end)
return true
