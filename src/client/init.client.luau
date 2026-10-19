local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Brand = require(ReplicatedStorage.Shared:WaitForChild("Brand"))
local Config = require(ReplicatedStorage.Shared:WaitForChild("GameConfig"))
local player = Players.LocalPlayer
local input = ReplicatedStorage:WaitForChild("RunnerInput")
local sessionAction = ReplicatedStorage:WaitForChild("SessionAction")
local rosterUpdate = ReplicatedStorage:WaitForChild("RosterUpdate")
local devRemote = ReplicatedStorage:WaitForChild("DevTelemetry")
require(script:WaitForChild("CameraController"))
require(script:WaitForChild("InvulnerabilityEffects"))
require(script:WaitForChild("WindEffects"))
require(script:WaitForChild("SkateEffects"))
require(script:WaitForChild("RouteEffects"))
require(script:WaitForChild("CoinEffects"))
require(script:WaitForChild("PowerUpHUD"))
require(script:WaitForChild("PersonalPickups"))
require(script:WaitForChild("DraftHUD"))
local Presentation = require(ReplicatedStorage.Shared:WaitForChild("PlayerPresentation"))
local root, humanoid, controls
local lastRunning, lastWatching
local roster, rows = {}, {}
local devData, devTab, devCollapsed = {}, "State", false
local boardCollapsed = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 850 or false
local resultUntil = 0
local fps = 60

local function running()
	local state = player:GetAttribute("SessionState")
	return state == "Solo" or state == "Race"
end
local function watching() return player:GetAttribute("Spectating") == true end
local function canWatch() return Presentation.canSpectate(player:GetAttribute("SessionState"), player:GetAttribute("AFK"), workspace:GetAttribute("MatchState")) end
local function clock(seconds)
	local n = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", math.floor(n / 60), n % 60)
end
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "RunnerHUD", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local background = Brand.Ink
local muted = Brand.Muted
local mint = Brand.Cyan
local function outline(item, color, thickness)
	local stroke = Instance.new("UIStroke", item)
	stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness = Enum.ApplyStrokeMode.Border, color, thickness or 1
	stroke.Transparency = 0.35
	return stroke
end
local function gradient(item, top, bottom)
	local fill = Instance.new("UIGradient", item)
	fill.Color, fill.Rotation = ColorSequence.new(top, bottom), 100
end
local function round(item, radius) Instance.new("UICorner", item).CornerRadius = UDim.new(0, radius or 10) end
local function panel(name, size, position, anchor)
	local frame = Instance.new("Frame")
	frame.Name, frame.Size, frame.Position = name, size, position
	frame.AnchorPoint = anchor or Vector2.zero
	frame.BackgroundColor3, frame.BackgroundTransparency = Brand.Panel, 0.06
	frame.BorderSizePixel = 0
	frame.Parent = gui
	round(frame, 14)
	local accent = if name == "Wallet" or name == "Notification" then Brand.Gold elseif name == "MatchStatus" or name == "Spectator" then Brand.Cyan else Brand.Purple
	outline(frame, accent, 2)
	gradient(frame, Color3.fromRGB(255, 230, 255), Color3.fromRGB(139, 148, 196))
	local tab = Instance.new("Frame", frame)
	tab.Name, tab.BorderSizePixel, tab.BackgroundColor3 = "AccentTab", 0, accent
	tab.Size, tab.Position = UDim2.fromOffset(24, 4), UDim2.fromOffset(16, -2)
	round(tab, 2)
	return frame
end
local function label(parent, size, position, fontSize, alignment)
	local item = Instance.new("TextLabel")
	item.Size, item.Position = size, position
	item.BackgroundTransparency = 1
	item.TextColor3, item.Font, item.TextSize = Color3.fromRGB(248, 244, 255), Enum.Font.GothamMedium, fontSize
	item.TextXAlignment = alignment or Enum.TextXAlignment.Left
	item.TextWrapped = true
	item.Parent = parent
	return item
end
local function button(parent, title, size, position, color)
	local item = Instance.new("TextButton")
	item.Size, item.Position, item.Text = size, position, title
	item.BackgroundColor3 = color or Brand.Panel
	item.BorderSizePixel = 0
	item.TextColor3, item.TextSize, item.Font = Color3.new(1, 1, 1), 14, Enum.Font.FredokaOne
	item.Parent = parent
	round(item, 12)
	local border = outline(item, Color3.fromRGB(119, 93, 164), 2)
	gradient(item, Color3.new(1, 1, 1), Color3.fromRGB(185, 177, 215))
	local scale = Instance.new("UIScale", item)
	local function animate(value, transparency)
		TweenService:Create(scale, TweenInfo.new(0.12), {Scale = value}):Play()
		TweenService:Create(border, TweenInfo.new(0.12), {Transparency = transparency}):Play()
	end
	item.MouseEnter:Connect(function() animate(1.025, 0) end)
	item.MouseLeave:Connect(function() animate(1, 0.35) end)
	item.MouseButton1Down:Connect(function() animate(0.97, 0) end)
	item.MouseButton1Up:Connect(function() animate(1, 0.35) end)
	return item
end
local status = panel("MatchStatus", UDim2.new(0.48, 0, 0, 72), UDim2.new(0.5, 0, 0, 12), Vector2.new(0.5, 0))
local statusSize = Instance.new("UISizeConstraint", status)
statusSize.MaxSize, statusSize.MinSize = Vector2.new(440, 72), Vector2.new(270, 72)
local heading = label(status, UDim2.new(1, -112, 0, 28), UDim2.fromOffset(16, 7), 19)
heading.Font = Enum.Font.FredokaOne
heading.TextColor3 = Brand.Gold
heading.TextScaled, heading.TextWrapped = true, false
local headingSize = Instance.new("UITextSizeConstraint", heading)
headingSize.MaxTextSize, headingSize.MinTextSize = 19, 12
local raceClock = label(status, UDim2.fromOffset(85, 30), UDim2.new(1, -97, 0, 6), 27, Enum.TextXAlignment.Right)
raceClock.Font, raceClock.TextColor3 = Enum.Font.FredokaOne, Brand.Cyan
local subtitle = label(status, UDim2.new(1, -32, 0, 20), UDim2.fromOffset(16, 37), 12)
subtitle.TextColor3 = muted
local progressTrack = Instance.new("Frame", status)
progressTrack.Name, progressTrack.BorderSizePixel = "RaceTrack", 0
progressTrack.Size, progressTrack.Position = UDim2.new(1, -32, 0, 5), UDim2.new(0, 16, 1, -10)
progressTrack.BackgroundColor3 = Color3.fromRGB(64, 51, 84)
round(progressTrack, 3)
local progress = Instance.new("Frame", progressTrack)
progress.Size, progress.Position = UDim2.new(0, 0, 1, 0), UDim2.fromOffset(0, 0)
round(progress, 3)
progress.BorderSizePixel, progress.BackgroundColor3 = 0, mint
gradient(progress, Brand.Purple, Brand.Cyan)
local wallet = panel("Wallet", UDim2.fromOffset(166, 68), UDim2.new(0, 16, 1, -16), Vector2.new(0, 1))
wallet.BackgroundColor3 = Color3.fromRGB(53, 33, 49)
local coinMedal = Instance.new("Frame", wallet)
coinMedal.Size, coinMedal.Position, coinMedal.BackgroundColor3 = UDim2.fromOffset(42, 42), UDim2.fromOffset(10, 13), Brand.Gold
coinMedal.BorderSizePixel, coinMedal.Rotation = 0, -12
round(coinMedal, 21)
outline(coinMedal, Color3.fromRGB(138, 78, 25), 3)
local coinIcon = label(coinMedal, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 26, Enum.TextXAlignment.Center)
coinIcon.Text, coinIcon.TextColor3 = "◆", Color3.fromRGB(255, 249, 197)
coinIcon.TextStrokeColor3, coinIcon.TextStrokeTransparency = Color3.fromRGB(165, 100, 22), 0.2
local walletTitle = label(wallet, UDim2.fromOffset(98, 16), UDim2.fromOffset(62, 9), 10)
walletTitle.Text, walletTitle.TextColor3 = "MONEDAS", Brand.Gold
local coinCount = label(wallet, UDim2.fromOffset(98, 32), UDim2.fromOffset(62, 26), 30)
coinCount.Font = Enum.Font.FredokaOne
local coinScale = Instance.new("UIScale", coinCount)
local walletScale = Instance.new("UIScale", wallet)
local lastCoins = player:GetAttribute("Coins") or 0
player:GetAttributeChangedSignal("Coins"):Connect(function()
	local coins = player:GetAttribute("Coins") or 0
	if coins > lastCoins then
		coinScale.Scale, coinCount.TextColor3 = 1.18, Brand.Gold
		TweenService:Create(coinScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
		TweenService:Create(coinCount, TweenInfo.new(0.45), {TextColor3 = Color3.fromRGB(248, 244, 255)}):Play()
	end
	lastCoins = coins
end)
local options = panel("Options", UDim2.fromOffset(184, 145), UDim2.new(1, -16, 1, -16), Vector2.new(1, 1))
local optionsScale = Instance.new("UIScale", options)
options.BackgroundTransparency = 1
options:FindFirstChildOfClass("UIStroke").Enabled = false
options:FindFirstChild("AccentTab").Visible = false
local afk = button(options, "AFK", UDim2.fromOffset(184, 40), UDim2.fromOffset(0, 0))
local solo = button(options, "▶  JUGAR SOLO", UDim2.fromOffset(184, 40), UDim2.fromOffset(0, 48), Brand.Gold)
solo.TextColor3 = Brand.Ink
solo:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(255, 238, 146)
solo.TextSize = 18
solo.Rotation = -2
local spectate = button(options, "ESPECTAR", UDim2.fromOffset(184, 40), UDim2.fromOffset(0, 96))
local endSolo = button(options, "TERMINAR", UDim2.fromOffset(184, 40), UDim2.fromOffset(0, 96), Color3.fromRGB(158, 66, 60))
afk.TextSize, spectate.TextSize, endSolo.TextSize = 13, 15, 15
afk.Activated:Connect(function() sessionAction:FireServer("ToggleAFK") end)
solo.Activated:Connect(function() sessionAction:FireServer("StartSolo") end)
spectate.Activated:Connect(function()
	sessionAction:FireServer(if watching() then "StopSpectate" else "Spectate")
end)
endSolo.Activated:Connect(function() sessionAction:FireServer("EndSolo") end)

local spectator = panel("Spectator", UDim2.fromOffset(330, 66), UDim2.new(0.5, 0, 1, -24), Vector2.new(0.5, 1))
local watchedName = label(spectator, UDim2.new(1, -12, 0, 23), UDim2.fromOffset(6, 3), 13, Enum.TextXAlignment.Center)
local prev = button(spectator, "<", UDim2.fromOffset(40, 27), UDim2.fromOffset(8, 31))
local stop = button(spectator, "SALIR DE ESPECTADOR", UDim2.fromOffset(218, 27), UDim2.fromOffset(56, 31))
local nextButton = button(spectator, ">", UDim2.fromOffset(40, 27), UDim2.fromOffset(282, 31))
prev.Activated:Connect(function() sessionAction:FireServer("SpectatePrevious") end)
nextButton.Activated:Connect(function() sessionAction:FireServer("SpectateNext") end)
stop.Activated:Connect(function() sessionAction:FireServer("StopSpectate") end)
local toast = panel("Notification", UDim2.new(0.45, 0, 0, 38), UDim2.new(0.5, 0, 0, 96), Vector2.new(0.5, 0))
Instance.new("UISizeConstraint", toast).MaxSize = Vector2.new(420, 38)
local toastText = label(toast, UDim2.new(1, -16, 1, -6), UDim2.fromOffset(8, 3), 13, Enum.TextXAlignment.Center)
local protection = Instance.new("Frame", toast)
protection.Name, protection.BorderSizePixel, protection.BackgroundColor3 = "Protection", 0, Brand.Cyan
protection.Position = UDim2.new(0, 0, 1, -3)
player:GetAttributeChangedSignal("MatchResult"):Connect(function()
	resultUntil = workspace:GetServerTimeNow() + 7
end)

local board = panel("PlayerBoard", UDim2.fromOffset(280, 340), UDim2.new(1, -16, 0, 86), Vector2.new(1, 0))
local boardToggle = button(board, "JUGADORES  [TAB]", UDim2.new(1, 0, 0, 32), UDim2.fromOffset(0, 0), Brand.Panel)
boardToggle.TextColor3 = Brand.Cyan
local list = Instance.new("ScrollingFrame", board)
list.Size, list.Position = UDim2.new(1, -8, 1, -40), UDim2.fromOffset(4, 36)
list.BackgroundTransparency, list.BorderSizePixel = 1, 0
list.ScrollBarThickness = 3
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.fromOffset(0, 0)
local layout = Instance.new("UIListLayout", list)
layout.Padding, layout.SortOrder = UDim.new(0, 3), Enum.SortOrder.LayoutOrder
local function groupHeader(name, order, color)
	local frame = Instance.new("Frame", list)
	frame.Size, frame.BackgroundTransparency, frame.LayoutOrder = UDim2.new(1, -5, 0, 28), 1, order
	local title = label(frame, UDim2.new(1, -108, 1, 0), UDim2.fromOffset(7, 0), 12)
	title.TextColor3, title.Font = color, Enum.Font.GothamBold
	local columns = label(frame, UDim2.fromOffset(105, 28), UDim2.new(1, -108, 0, 0), 10, Enum.TextXAlignment.Right)
	columns.Text, columns.TextColor3 = "STUDS       $", muted
	return title
end
local playingHeader = groupHeader("Jugando", 0, mint)
local afkHeader = groupHeader("AFK", 10000, muted)
local function updateBoardAppearance()
	list.Visible = not boardCollapsed
	board.Size = UDim2.fromOffset(280, if boardCollapsed then 32 else 340)
	boardToggle.Text = if boardCollapsed then "JUGADORES  +  [TAB]" else "JUGADORES  -  [TAB]"
end
boardToggle.Activated:Connect(function() boardCollapsed = not boardCollapsed; updateBoardAppearance() end)
CAS:BindActionAtPriority("ToggleCustomPlayerList", function(_, state)
	if state == Enum.UserInputState.Begin then boardCollapsed = not boardCollapsed; updateBoardAppearance() end
	return Enum.ContextActionResult.Sink
end, false, 3500, Enum.KeyCode.Tab)
updateBoardAppearance()
rosterUpdate.OnClientEvent:Connect(function(records)
	roster = {}
	local playingCount, idleCount = 0, 0
	for _, record in records do
		roster[record.id] = record
		local row = rows[record.id]
		if not row then
			local item = button(list, "", UDim2.new(1, -5, 0, 39), UDim2.fromOffset(0, 0))
			item.AutoButtonColor = false
			row = {
				item = item,
				name = label(item, UDim2.new(1, -111, 0, 20), UDim2.fromOffset(8, 2), 12),
				detail = label(item, UDim2.new(1, -111, 0, 14), UDim2.fromOffset(8, 22), 10),
				studs = label(item, UDim2.fromOffset(59, 35), UDim2.new(1, -108, 0, 2), 12, Enum.TextXAlignment.Right),
				coins = label(item, UDim2.fromOffset(43, 35), UDim2.new(1, -46, 0, 2), 12, Enum.TextXAlignment.Right),
			}
			row.name.TextWrapped, row.name.TextTruncate = false, Enum.TextTruncate.AtEnd
			row.detail.TextColor3, row.coins.TextColor3 = muted, Color3.fromRGB(255, 209, 88)
			local id = record.id
			item.Activated:Connect(function()
				local target = roster[id]
				if canWatch() and target and target.team == "Jugando" then sessionAction:FireServer("Spectate", id) end
			end)
			rows[id] = row
		end
		if record.team == "Jugando" then playingCount += 1; row.item.LayoutOrder = playingCount
		else idleCount += 1; row.item.LayoutOrder = 10000 + idleCount end
		row.item.BackgroundColor3 = if record.id == player.UserId then Color3.fromRGB(65, 36, 98) else Brand.Panel
		row.name.Text = (if record.state == "Race" then tostring(record.place) .. ". " else "") .. record.name
		row.name.TextColor3 = if record.state == "Race" and record.place == 1 then Brand.Gold elseif record.id == player.UserId then Brand.Cyan else Color3.fromRGB(248, 244, 255)
		row.detail.Text = if record.state == "Race" then "Carrera" elseif record.state == "Solo" then "Solo" elseif record.state == "Finished" then "En meta" elseif record.afk then "AFK" else "Lobby"
		row.studs.Text, row.coins.Text = tostring(math.floor(record.studs)), tostring(record.coins)
	end
	for id, row in rows do
		if not roster[id] then row.item:Destroy(); rows[id] = nil end
	end
	playingHeader.Text, afkHeader.Text = "JUGANDO (" .. playingCount .. ")", "AFK (" .. idleCount .. ")"
end)
task.spawn(function()
	for _ = 1, 5 do
		if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end) then break end
		task.wait(0.3)
	end
end)

local dev = panel("DeveloperMenu", UDim2.fromOffset(246, 215), UDim2.fromOffset(12, 12))
dev.Visible = false
local devTitle = label(dev, UDim2.fromOffset(163, 28), UDim2.fromOffset(9, 0), 12)
devTitle.Text, devTitle.TextColor3 = "DEV  /menu", mint
local collapse = button(dev, "-", UDim2.fromOffset(26, 24), UDim2.fromOffset(185, 2))
local close = button(dev, "X", UDim2.fromOffset(26, 24), UDim2.fromOffset(215, 2))
local stateTab = button(dev, "ESTADO", UDim2.fromOffset(110, 25), UDim2.fromOffset(9, 33))
local worldTab = button(dev, "MUNDO", UDim2.fromOffset(110, 25), UDim2.fromOffset(127, 33))
local devText = label(dev, UDim2.new(1, -18, 1, -68), UDim2.fromOffset(9, 65), 12)
devText.Font, devText.TextYAlignment = Enum.Font.Code, Enum.TextYAlignment.Top
stateTab.Activated:Connect(function() devTab = "State" end)
worldTab.Activated:Connect(function() devTab = "World" end)
collapse.Activated:Connect(function() devCollapsed = not devCollapsed end)
close.Activated:Connect(function() devRemote:FireServer("Close") end)
devRemote.OnClientEvent:Connect(function(data) if player:GetAttribute("IsDeveloper") then devData = data end end)

local actions = {RunnerLeft = "Left", RunnerRight = "Right", RunnerJump = "Jump"}
local function action(name, state)
	if not running() then return Enum.ContextActionResult.Pass end
	if name == "RunnerCrouch" then
		if state == Enum.UserInputState.Begin and humanoid and humanoid.Health > 0 then input:FireServer("CrouchStart")
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then input:FireServer("CrouchEnd") end
	elseif state == Enum.UserInputState.Begin and humanoid and humanoid.Health > 0 then input:FireServer(actions[name]) end
	return Enum.ContextActionResult.Sink
end
local function applyControls(force)
	local active, watch = running(), watching()
	if controls then if active or watch then controls:Disable() else controls:Enable() end end
	if force or active ~= lastRunning or watch ~= lastWatching then
		lastRunning, lastWatching = active, watch
		if active then
			CAS:BindActionAtPriority("RunnerLeft", action, true, 3000, Enum.KeyCode.A, Enum.KeyCode.Left, Enum.KeyCode.DPadLeft)
			CAS:BindActionAtPriority("RunnerRight", action, true, 3000, Enum.KeyCode.D, Enum.KeyCode.Right, Enum.KeyCode.DPadRight)
			CAS:BindActionAtPriority("RunnerJump", action, true, 3000, Enum.KeyCode.Space, Enum.KeyCode.Up, Enum.KeyCode.W, Enum.KeyCode.ButtonA)
			CAS:BindActionAtPriority("RunnerCrouch", action, true, 3000, Enum.KeyCode.S, Enum.KeyCode.Down, Enum.KeyCode.DPadDown, Enum.KeyCode.ButtonB)
			for name, value in {RunnerLeft = "<", RunnerRight = ">", RunnerJump = "Saltar", RunnerCrouch = "Agacharse"} do CAS:SetTitle(name, value) end
			CAS:SetPosition("RunnerLeft", UDim2.new(0, 30, 1, -160))
			CAS:SetPosition("RunnerRight", UDim2.new(0, 110, 1, -160))
			CAS:SetPosition("RunnerJump", UDim2.new(1, -100, 1, -160))
			CAS:SetPosition("RunnerCrouch", UDim2.new(1, -190, 1, -160))
		else
			for _, name in {"RunnerLeft", "RunnerRight", "RunnerJump", "RunnerCrouch"} do CAS:UnbindAction(name) end
		end
	end
end
player:GetAttributeChangedSignal("SessionState"):Connect(function() applyControls(false) end)
player:GetAttributeChangedSignal("Spectating"):Connect(function() applyControls(false) end)
local function onCharacter(character)
	root = nil
	local nextHumanoid, nextRoot = character:WaitForChild("Humanoid"), character:WaitForChild("HumanoidRootPart")
	if player.Character ~= character then return end
	humanoid, root = nextHumanoid, nextRoot
	applyControls(true)
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter, player.Character) end
task.spawn(function()
	local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
	if not module then return end
	local ok, result = pcall(function() return require(module):GetControls() end)
	if ok then controls = result; applyControls(true) end
end)
UIS.WindowFocusReleased:Connect(function() if running() then input:FireServer("CrouchEnd") end end)
UIS.TextBoxFocused:Connect(function() if running() then input:FireServer("CrouchEnd") end end)
UIS.InputBegan:Connect(function(key, processed)
	if processed or not watching() then return end
	if key.KeyCode == Enum.KeyCode.Q then sessionAction:FireServer("SpectatePrevious")
	elseif key.KeyCode == Enum.KeyCode.E then sessionAction:FireServer("SpectateNext") end
end)
applyControls(true)

RunService:BindToRenderStep("RunnerHUDRender", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local now = workspace:GetServerTimeNow()
	local state = player:GetAttribute("SessionState") or "Lobby"
	local active, watch = running(), watching()
	local phase = workspace:GetAttribute("MatchState")
	local remaining = (workspace:GetAttribute("MatchDeadline") or now) - now
	local distance = workspace:GetAttribute("MatchDistance") or 3600
	local travelled = player:GetAttribute("RunDistance") or 0
	local stillRunning = workspace:GetAttribute("MatchRemaining") or 0
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
	local compactHUD = viewport and viewport.X < 600
	status.Size = UDim2.new(if compactHUD then 0.88 else 0.48, 0, 0, 72)
	board.Position = UDim2.new(1, -16, 0, if compactHUD then 194 else 96)
	local smallScale = if viewport and viewport.X < 400 then 0.88 else 1
	walletScale.Scale, optionsScale.Scale = smallScale, smallScale
	spectator.Position = UDim2.new(0.5, 0, 1, if viewport and viewport.X < 760 then -178 else -24)
	coinCount.Text = tostring(player:GetAttribute("Coins") or 0)
	afk.Visible, solo.Visible = not active, not active
	spectate.Visible, endSolo.Visible = not active and canWatch(), state == "Solo"
	afk.Text = if player:GetAttribute("AFK") then "AFK  ACTIVADO" else "AFK  DESACTIVADO"
	afk.BackgroundColor3 = if player:GetAttribute("AFK") then Color3.fromRGB(111, 65, 148) else Brand.Panel
	spectate.Text = if watch then "DEJAR DE ESPECTAR" else "ESPECTAR"
	spectator.Visible = watch
	progress.Visible = state == "Race"
	progressTrack.Visible = state == "Race"
	raceClock.Visible = state ~= "Solo"
	raceClock.Text = clock(remaining)
	progress.Size = UDim2.new(math.clamp(travelled / distance, 0, 1), 0, 1, 0)
	if state == "Race" then
		heading.Text = "CARRERA"
		subtitle.Text = string.format("Puesto %d/%d   |   %d / %d studs", player:GetAttribute("RacePlace") or 0, player:GetAttribute("RacePlayers") or 1, travelled, distance)
	elseif state == "Solo" then
		heading.Text, subtitle.Text = "PRACTICA", tostring(travelled) .. " studs"
	elseif state == "Finished" and phase == "Race" then
		heading.Text = "¡EN META!"
		subtitle.Text = string.format("Puesto %d  |  Quedan %d corredores", player:GetAttribute("RacePlace") or 0, stillRunning)
	elseif phase == "Race" then
		heading.Text, subtitle.Text = "EN PISTA", tostring(stillRunning) .. " corredores siguen en pista"
	else
		heading.Text = "SIGUIENTE CARRERA"
		subtitle.Text = string.format("%d disponibles  |  %d studs", workspace:GetAttribute("AvailablePlayers") or 0, distance)
	end
	local recovering = active and now < (player:GetAttribute("RecoveringUntil") or 0)
	protection.Visible = recovering
	protection.Size = UDim2.new(math.clamp(((player:GetAttribute("RecoveringUntil") or 0) - now) / math.max(0.01, Config.Crash.ProtectionDuration), 0, 1), 0, 0, 3)
	heading.TextColor3 = if state == "Race" and remaining <= 10 then Color3.fromRGB(255, 123, 102) else Brand.Gold
	local result = player:GetAttribute("MatchResult") or ""
	local showResult = now < resultUntil and result ~= ""
	local boostTime = (player:GetAttribute("BoostUntil") or 0) - now
	local boosted = active and boostTime > 0
	toast.Visible = recovering or showResult or boosted
	toast.BackgroundColor3 = if recovering then Color3.fromRGB(132, 56, 39) elseif boosted then Color3.fromRGB(35, 57, 88) else background
	toastText.Text = if recovering then string.format("CHOQUE  -%d monedas", player:GetAttribute("CoinsLost") or 0)
		elseif showResult then result else string.format("IMPULSO  +%d  |  %.1f s", player:GetAttribute("BoostBonus") or Config.SpeedRoutes.Bonus, math.max(0, boostTime))
	if watch then
		local targetId = player:GetAttribute("SpectateTarget") or 0
		local followed = if targetId ~= 0 then Players:GetPlayerByUserId(targetId) else nil
		watchedName.Text = if followed then "VIENDO  " .. followed.DisplayName .. "   [Q / E]" else "Sin jugadores activos"
	end
	fps += ((1 / math.max(dt, 0.001)) - fps) * math.min(1, dt * 3)
	dev.Visible = player:GetAttribute("IsDeveloper") == true and player:GetAttribute("DevMenuOpen") == true
	if dev.Visible then
		dev.Size = UDim2.fromOffset(246, if devCollapsed then 28 else 215)
		stateTab.Visible, worldTab.Visible, devText.Visible = not devCollapsed, not devCollapsed, not devCollapsed
		collapse.Text = if devCollapsed then "+" else "-"
		stateTab.BackgroundColor3 = if devTab == "State" then Color3.fromRGB(35, 86, 81) else Color3.fromRGB(43, 57, 79)
		worldTab.BackgroundColor3 = if devTab == "World" then Color3.fromRGB(35, 86, 81) else Color3.fromRGB(43, 57, 79)
		local data = devData
		if devTab == "State" then
			devText.Text = string.format("Estado: %s | %s\nVel. objetivo/real: %.1f / %.1f\nCarril: %d | Cambio: %.2f s\nMonedas: %d | Pickups: %d\nStuds: %d | FPS: %.0f\nRampa: %s | Agachado: %s\nProteccion: %.2f s", data.state or "...", data.mode or "", data.speed or 0, data.actual or 0, data.lane or 0, data.laneTime or 0, data.coins or 0, data.pickups or 0, data.studs or 0, fps, tostring(data.ramp or false), tostring(data.crouch or false), data.recovery or 0)
		else
			devText.Text = string.format("Fase: %s | Ronda: %d\nReloj: %s\nMundos: %d | Origen X: %d\nTramos: %d | Trenes: %d\nCorredores en pista: %d\nEspectando UserId: %d", data.phase or "...", data.round or 0, clock(data.time or 0), data.worlds or 0, data.origin or 0, data.chunks or 0, data.trains or 0, data.runners or 0, data.spectating or 0)
		end
	end
end)
