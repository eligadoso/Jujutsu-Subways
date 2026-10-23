local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "ProjectileWarnings", false, true, 8
gui.Parent = player:WaitForChild("PlayerGui")
local warnings = {}
ReplicatedStorage:WaitForChild("ProjectileWarning").OnClientEvent:Connect(function(x, deadline)
	local key = math.round(x * 10)
	local item = warnings[key]
	if not item then
		local label = Instance.new("TextLabel", gui)
		label.Size, label.AnchorPoint = UDim2.fromOffset(38, 46), Vector2.new(0.5, 0.5)
		label.BackgroundColor3, label.BackgroundTransparency = Color3.fromRGB(161, 33, 57), 0.15
		label.Text, label.Font, label.TextSize = "!", Enum.Font.FredokaOne, 40
		label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(255, 225, 79), 0.25
		Instance.new("UICorner", label).CornerRadius = UDim.new(0.5, 0)
		item = {label = label, x = x}; warnings[key] = item
	end
	item.deadline = math.max(item.deadline or 0, deadline)
end)
RunService:BindToRenderStep("IncomingProjectile", Enum.RenderPriority.Camera.Value + 50, function()
	local camera = workspace.CurrentCamera
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local state = player:GetAttribute("SessionState")
	local now = workspace:GetServerTimeNow()
	for key, item in warnings do
		if now >= item.deadline or not root or (state ~= "Race" and state ~= "Solo") then item.label:Destroy(); warnings[key] = nil; continue end
		if not camera then item.label.Visible = false; continue end
		local point = camera:WorldToViewportPoint(Vector3.new(item.x, root.Position.Y + 1, root.Position.Z - 20))
		item.label.Position = UDim2.fromOffset(math.clamp(point.X, 24, math.max(24, camera.ViewportSize.X - 24)), math.clamp(point.Y, 55, math.max(55, camera.ViewportSize.Y - 55)))
		item.label.Rotation = math.sin(now * 15) * 5
		item.label.Visible = true
	end
end)
return true
