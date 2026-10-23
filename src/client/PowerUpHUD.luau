local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Brand = require(ReplicatedStorage.Shared:WaitForChild("Brand"))
local Config = require(ReplicatedStorage.Shared:WaitForChild("GameConfig"))
local player = Players.LocalPlayer
local input = ReplicatedStorage:WaitForChild("RunnerInput")
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "PowerUpHUD", false
gui.Parent = player:WaitForChild("PlayerGui")
local slot = Instance.new("TextButton")
slot.Name, slot.Size, slot.AnchorPoint = "PowerSlot", UDim2.fromOffset(170, 62), Vector2.new(0.5, 1)
slot.BackgroundColor3, slot.BorderSizePixel = Brand.Panel, 0
slot.Font, slot.TextSize, slot.TextColor3 = Enum.Font.FredokaOne, 16, Brand.Cyan
slot.TextWrapped, slot.Parent = true, gui
Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", slot)
stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness = Enum.ApplyStrokeMode.Border, Brand.Purple, 2
local backwards = false
local aim = Instance.new("TextButton", gui)
aim.Size, aim.AnchorPoint = UDim2.fromOffset(70, 26), Vector2.new(0.5, 1)
aim.BackgroundColor3, aim.TextColor3, aim.Font, aim.TextSize = Brand.Panel, Brand.Cyan, Enum.Font.FredokaOne, 12
aim.Text = "FRENTE"
Instance.new("UICorner", aim).CornerRadius = UDim.new(0, 8)
aim.Activated:Connect(function() backwards = not backwards; aim.Text = if backwards then "ATRAS" else "FRENTE" end)
local function active()
	local state = player:GetAttribute("SessionState")
	return (state == "Race" or state == "Solo") and player:GetAttribute("Spectating") ~= true
end
local function use()
	if not UIS:GetFocusedTextBox() and active() and (player:GetAttribute("HeldPowerUp") or "") ~= "" then
		local back = backwards or UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
		input:FireServer(if back then "UsePowerUpBack" else "UsePowerUp")
	end
end
slot.Activated:Connect(use)
CAS:BindActionAtPriority("UseHeldPowerUp", function(_, state)
	if not active() or UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if state == Enum.UserInputState.Begin then use() end
	return Enum.ContextActionResult.Sink
end, false, 3100, Enum.KeyCode.E, Enum.KeyCode.ButtonX)
RunService:BindToRenderStep("PowerUpSlot", Enum.RenderPriority.Last.Value, function()
	slot.Visible = active()
	local camera = workspace.CurrentCamera
	local compact = camera and camera.ViewportSize.X < 600
	slot.AnchorPoint = if compact then Vector2.zero else Vector2.new(0.5, 1)
	slot.Position = if compact then UDim2.fromOffset(16, 144) else UDim2.new(0.5, 0, 1, -20)
	slot.Size = if compact then UDim2.fromOffset(130, 44) else UDim2.fromOffset(170, 62)
	local id = player:GetAttribute("HeldPowerUp") or ""
	aim.Visible = active() and id == "Egg"
	aim.Position = if compact then UDim2.new(0, 80, 0, 218) else UDim2.new(0.5, 0, 1, -86)
	local name
	for _, power in Config.PowerUps.Catalog do if power.Id == id then name = power.Name; break end end
	slot.Text = if name then "◆  " .. name .. "  [E]" else "◇  SIN PODER"
	slot.TextColor3 = if name then Brand.Gold else Brand.Muted
	stroke.Color = if name then Brand.Gold else Brand.Purple
	slot.AutoButtonColor, slot.Active = name ~= nil, name ~= nil
end)
return true
