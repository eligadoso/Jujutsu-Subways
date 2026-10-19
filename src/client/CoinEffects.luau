local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local coins = {}
local function track(model)
	if not model:IsA("Model") or coins[model] then return end
	coins[model] = {}
end
for _, model in CollectionService:GetTagged("SpinningCoin") do track(model) end
CollectionService:GetInstanceAddedSignal("SpinningCoin"):Connect(track)
CollectionService:GetInstanceRemovedSignal("SpinningCoin"):Connect(function(model) coins[model] = nil end)
local elapsed = 0
RunService:BindToRenderStep("RunnerCoinSpin", Enum.RenderPriority.Last.Value, function(dt)
	elapsed += dt
	if elapsed < 1 / 30 then return end
	elapsed = 0
	local camera = workspace.CurrentCamera
	if not camera then return end
	local focus = camera.Focus.Position
	local now = workspace:GetServerTimeNow()
	for model, coin in coins do
		if not model.Parent then coins[model] = nil; continue end
		if not coin.frame then
			if not model.PrimaryPart then continue end
			coin.frame = model:GetPivot()
			coin.phase = (coin.frame.Position.X * 0.31 + coin.frame.Position.Z * 0.13) % (2 * math.pi)
		end
		if (coin.frame.Position - focus).Magnitude > 130 then continue end
		local angle = (now * 2.4 + coin.phase) % (2 * math.pi)
		local bob = math.sin(now * 3 + coin.phase) * 0.12
		model:PivotTo(CFrame.new(0, bob, 0) * CFrame.new(coin.frame.Position) * CFrame.Angles(0, angle, 0) * coin.frame.Rotation)
	end
end)
return true
