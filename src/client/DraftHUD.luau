local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.Parent = "DraftHUD", false, player:WaitForChild("PlayerGui")
local strip = Instance.new("Frame", gui)
strip.Size, strip.Position, strip.AnchorPoint = UDim2.fromOffset(180, 10), UDim2.new(0.5, 0, 0, 85), Vector2.new(0.5, 0)
strip.BackgroundTransparency = 1
local label = Instance.new("TextLabel", strip)
label.Size, label.BackgroundTransparency = UDim2.fromOffset(76, 10), 1
label.Text, label.TextSize, label.Font = "REBUFO", 10, Enum.Font.GothamBold
label.TextColor3 = Color3.fromRGB(110, 230, 255)
local track = Instance.new("Frame", strip)
track.Position, track.Size, track.BackgroundColor3 = UDim2.fromOffset(80, 2), UDim2.fromOffset(100, 6), Color3.fromRGB(45, 39, 65)
track.BorderSizePixel = 0
local fill = Instance.new("Frame", track)
fill.BorderSizePixel, fill.BackgroundColor3 = 0, Color3.fromRGB(110, 230, 255)
RunService:BindToRenderStep("DraftChargeHUD", Enum.RenderPriority.Last.Value, function()
	local charge = player:GetAttribute("DraftCharge") or 0
	local boosted = (player:GetAttribute("DraftUntil") or 0) > workspace:GetServerTimeNow()
	strip.Visible = player:GetAttribute("SessionState") == "Race" and (charge > 0.01 or boosted)
	fill.Size = UDim2.fromScale(if boosted then 1 else math.clamp(charge, 0, 1), 1)
	fill.BackgroundColor3 = if boosted then Color3.fromRGB(255, 213, 65) else Color3.fromRGB(110, 230, 255)
end)
return true
