local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rig = require(Shared:WaitForChild("RunnerCamera"))
local View = require(Shared:WaitForChild("SpectatorView"))
local player = Players.LocalPlayer
local snapshot, lastSubject, ownedCamera
local requestedTarget

ReplicatedStorage:WaitForChild("SpectatorView").OnClientEvent:Connect(function(data)
	snapshot = data
	if player:GetAttribute("Spectating") and requestedTarget ~= data.targetId then
		requestedTarget = data.targetId
		task.spawn(function()
			-- Request missing distant track geometry; camera tracking does not depend on its arrival.
			pcall(function() player:RequestStreamAroundAsync(data.position, 3) end)
		end)
	end
end)

RunService:BindToRenderStep("RunnerPerspective", Enum.RenderPriority.Camera.Value + 20, function(dt)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local state = player:GetAttribute("SessionState")
	local watching = player:GetAttribute("Spectating") == true
	local active = state == "Race" or state == "Solo"
	local targetId = if watching then player:GetAttribute("SpectateTarget") or 0 else player.UserId
	local subject = if watching then Players:GetPlayerByUserId(targetId) else player
	local character = subject and subject.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hasRoot = root ~= nil and humanoid ~= nil and humanoid.Health > 0
	if active or watching then
		local now = workspace:GetServerTimeNow()
		if watching and hasRoot and View.valid(snapshot, targetId, now) and (root.Position - snapshot.position).Magnitude > 64 then hasRoot = false end
		local source = View.source(watching, targetId, hasRoot, snapshot, now)
		local position, originX
		if hasRoot then
			position, originX = root.Position, subject:GetAttribute("TrackOriginX") or 0
		elseif source == "Snapshot" then
			local ahead = math.clamp(now - snapshot.time, 0, 0.2)
			position, originX = snapshot.position + snapshot.velocity * ahead, snapshot.originX
		end
		-- Never switch to the lobby avatar while the observed character is streaming in.
		camera.CameraType, camera.FieldOfView = Enum.CameraType.Scriptable, 75
		ownedCamera = true
		if position then
			local frame = Rig.frame(position, originX)
			if lastSubject ~= targetId then camera.CFrame = frame
			else camera.CFrame = camera.CFrame:Lerp(frame, 1 - math.exp(-10 * dt)) end
			camera.Focus = CFrame.new(position)
			if humanoid then camera.CameraSubject = humanoid end
			lastSubject = targetId
		end
	elseif ownedCamera then
		local ownHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		camera.CameraType, camera.FieldOfView = Enum.CameraType.Custom, 70
		if ownHumanoid then camera.CameraSubject = ownHumanoid end
		lastSubject, requestedTarget, ownedCamera = nil, nil, false
	end
end)
return true
