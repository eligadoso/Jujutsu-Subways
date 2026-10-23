local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "AbilityEffects", false, true, 3
gui.Parent = player:WaitForChild("PlayerGui")
local splats = {}
for i = 1, 7 do
	local blob = Instance.new("Frame", gui)
	blob.BorderSizePixel, blob.AnchorPoint = 0, Vector2.new(0.5, 0.5)
	blob.Position = UDim2.fromScale(0.5 + math.sin(i * 2.4) * 0.2, 0.48 + math.cos(i * 2.4) * 0.19)
	blob.Size, blob.Rotation = UDim2.fromScale(0.26 + i % 2 * 0.08, 0.3), i * 31
	blob.BackgroundColor3, blob.Visible = if i == 1 then Color3.fromRGB(255, 201, 57) else Color3.fromRGB(255, 243, 211), false
	Instance.new("UICorner", blob).CornerRadius = UDim.new(0.5, 0)
	table.insert(splats, blob)
end
local status = Instance.new("TextLabel", gui)
status.AnchorPoint, status.Position, status.Size = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 175), UDim2.fromOffset(260, 28)
status.BackgroundTransparency, status.Font, status.TextSize = 1, Enum.Font.FredokaOne, 18
status.TextColor3, status.TextStrokeTransparency = Color3.fromRGB(255, 219, 94), 0.3
local noticeUntil, notice = 0, ""
ReplicatedStorage:WaitForChild("AbilityFeedback").OnClientEvent:Connect(function(kind, duration, power)
	notice = if kind == "Used" then (if power == "Sneakers" then "¡DOBLE VELOCIDAD!" else "¡LANZADO!")
		elseif kind == "Lightning" then "¡RAYO!" elseif kind == "MouseTrap" then "¡TRAMPA!  +3" elseif kind == "Boomerang" then "¡BUMERAN!" else "¡HUEVO!"
	noticeUntil = os.clock() + duration
end)
RunService:BindToRenderStep("AbilityStatus", Enum.RenderPriority.Last.Value, function()
	local now = workspace:GetServerTimeNow()
	local state = player:GetAttribute("SessionState")
	local active = state == "Race" or state == "Solo"
	local eggTime = (player:GetAttribute("EggUntil") or 0) - now
	for i, blob in splats do
		blob.Visible = active and eggTime > 0
		blob.BackgroundTransparency = math.clamp(1 - eggTime / 0.3, 0, 1)
		if i == 1 then blob.ZIndex = 2 end
	end
	status.Visible = active and os.clock() < noticeUntil
	status.Text = notice
end)
return true
