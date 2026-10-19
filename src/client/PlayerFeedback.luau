local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Brand = require(Shared:WaitForChild("Brand"))
local player = Players.LocalPlayer
local Feedback = {}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "PlayerFeedback", false, true, 5
gui.Parent = player:WaitForChild("PlayerGui")
local pool, cursor = {}, 0
for _ = 1, 48 do
	local p = Instance.new("Frame")
	p.AnchorPoint, p.BorderSizePixel, p.Visible, p.Parent = Vector2.new(0.5, 0.5), 0, false, gui
	table.insert(pool, {frame = p})
end
local function text(size)
	local label = Instance.new("TextLabel")
	label.Size, label.AnchorPoint, label.BackgroundTransparency = size, Vector2.new(0.5, 0.5), 1
	label.Font, label.TextSize, label.TextStrokeTransparency = Enum.Font.GothamBlack, 22, 0.5
	label.Visible, label.Parent = false, gui
	return label
end
local reward = text(UDim2.fromOffset(300, 36))
local pickups, pickupCursor = {}, 0
for _ = 1, 8 do
	local label = text(UDim2.fromOffset(110, 44))
	label.TextSize, label.TextStrokeColor3, label.TextStrokeTransparency = 30, Brand.Ink, 0.15
	local scale = Instance.new("UIScale", label)
	table.insert(pickups, {label = label, scale = scale})
end
local rewardUntil, pulse = 0, 0
local pulseColor = Brand.Cyan
local edges = {}
for _, side in {-1, 1} do
	local edge = Instance.new("Frame")
	edge.BorderSizePixel, edge.Size = 0, UDim2.new(0, 5, 1, 0)
	edge.AnchorPoint, edge.Position = Vector2.new(if side == 1 then 1 else 0, 0), UDim2.fromScale(if side == 1 then 1 else 0, 0)
	edge.BackgroundTransparency, edge.Parent = 1, gui
	table.insert(edges, edge)
end
local function intensity()
	return if Config.MotionEffects.Enabled then math.clamp(Config.MotionEffects.Intensity, 0, 1) else 0
end
function Feedback.burst(point, color, count)
	if intensity() <= 0 then return end
	for i = 1, count do
		cursor = cursor % #pool + 1
		local item = pool[cursor]
		local angle = i * 2.399963
		item.started, item.origin = os.clock(), point
		item.velocity = Vector2.new(math.cos(angle), math.sin(angle)) * (55 + i % 4 * 25)
		item.frame.BackgroundColor3, item.frame.Visible = color, true
		item.frame.Position, item.frame.Size = UDim2.fromOffset(point.X, point.Y), UDim2.fromOffset(5, 5)
		item.frame.BackgroundTransparency = 1 - intensity()
		item.frame.Rotation = 45
	end
end
function Feedback.route(state)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local color = if state == "Failed" then Color3.fromRGB(255, 85, 100) elseif state == "Complete" then Color3.fromRGB(90, 255, 161) else Brand.Gold
	reward.Text = if state == "Failed" then "×" elseif state == "Complete" then "✓  RETO COMPLETADO" else "✓"
	reward.TextColor3, reward.Visible, rewardUntil = color, true, os.clock() + (if state == "Complete" then 1.2 else 0.55)
	pulse, pulseColor = 1, color
	if state ~= "Failed" then Feedback.burst(Vector2.new(camera.ViewportSize.X * 0.5, 155), color, if state == "Complete" then 16 else 6) end
end
ReplicatedStorage:WaitForChild("CoinPickup").OnClientEvent:Connect(function(positions, value)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local lastPoint
	for _, position in positions do
		local projected, visible = camera:WorldToViewportPoint(position)
		if visible then
			lastPoint = Vector2.new(projected.X, projected.Y)
			Feedback.burst(lastPoint, Brand.Gold, 6)
		end
	end
	if lastPoint then
		pickupCursor = pickupCursor % #pickups + 1
		local item = pickups[pickupCursor]
		item.started, item.origin = os.clock(), lastPoint - Vector2.new(0, 22)
		item.drift = if pickupCursor % 2 == 0 then 16 else -16
		item.label.Text, item.label.TextColor3, item.label.Visible = "+" .. value, Brand.Gold, true
		item.label.Position, item.label.Rotation = UDim2.fromOffset(item.origin.X, item.origin.Y), -10
		item.scale.Scale, item.label.TextTransparency = 0.45, 0
	end
end)
RunService:BindToRenderStep("RunnerRewardEffects", Enum.RenderPriority.Last.Value + 1, function(dt)
	local now, amount = os.clock(), intensity()
	local state = player:GetAttribute("SessionState")
	local active = state == "Race" or state == "Solo"
	local camera = workspace.CurrentCamera
	if camera then reward.Position = UDim2.fromOffset(camera.ViewportSize.X * 0.5, 150) end
	reward.Visible = active and now < rewardUntil
	reward.TextTransparency = math.clamp(1 - (rewardUntil - now) / 0.25, 0, 1)
	for _, item in pickups do
		if not item.started then continue end
		local age = now - item.started
		if age >= 0.85 or not active then item.label.Visible = false; item.started = nil; continue end
		local bounce = math.exp(-14 * age) * math.cos(25 * age)
		item.scale.Scale = 1 - 0.55 * bounce * amount
		item.label.Rotation = -10 * math.exp(-9 * age) * math.cos(20 * age) * amount
		local p = item.origin + Vector2.new(item.drift * age * amount, (-55 * age - math.sin(age * 18) * math.exp(-6 * age) * 13) * amount)
		item.label.Position = UDim2.fromOffset(p.X, p.Y)
		item.label.TextTransparency = math.clamp((age - 0.5) / 0.35, 0, 1)
		item.label.TextStrokeTransparency = 0.15 + item.label.TextTransparency * 0.85
	end
	pulse *= math.exp(-7 * dt)
	for _, edge in edges do
		edge.BackgroundColor3 = pulseColor
		edge.BackgroundTransparency = 1 - (if active then pulse * 0.5 * amount else 0)
	end
	for _, item in pool do
		if not item.started then continue end
		local age = now - item.started
		if age >= 0.5 or not active or amount <= 0 then item.frame.Visible = false; item.started = nil; continue end
		local p = item.origin + item.velocity * age + Vector2.new(0, 95 * age * age)
		item.frame.Position = UDim2.fromOffset(p.X, p.Y)
		item.frame.Size = UDim2.fromOffset(5 * (1 - age), 5 * (1 - age))
		item.frame.BackgroundTransparency = 1 - (1 - age / 0.5) * amount
	end
end)
return Feedback
