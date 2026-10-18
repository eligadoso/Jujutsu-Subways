local Players = game:GetService("Players")
local Presentation = require(game:GetService("ReplicatedStorage").Shared.PlayerPresentation)
local Service = {}
local viewRemote = Instance.new("RemoteEvent")
viewRemote.Name = "SpectatorView"
viewRemote.Parent = game:GetService("ReplicatedStorage")

local function focus(viewer, target)
	local character = target and target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	viewer.ReplicationFocus = root
	return root
end

local function sendView(viewer, target)
	local root = focus(viewer, target)
	if not root then return end
	viewRemote:FireClient(viewer, {
		targetId = target.UserId, name = target.DisplayName,
		position = root.Position, velocity = root.AssemblyLinearVelocity,
		originX = target:GetAttribute("TrackOriginX") or 0,
		time = workspace:GetServerTimeNow(),
	})
end

function Service.allowed(player)
	return Presentation.canSpectate(player:GetAttribute("SessionState"), player:GetAttribute("AFK"), workspace:GetAttribute("MatchState"))
end
function Service.targets(viewer)
	local targets = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if player ~= viewer and character and character:FindFirstChild("HumanoidRootPart")
			and Presentation.isTarget(player:GetAttribute("SessionState"), humanoid and humanoid.Health > 0) then
			table.insert(targets, player)
		end
	end
	table.sort(targets, function(a, b)
		if (a:GetAttribute("SessionState") == "Race") ~= (b:GetAttribute("SessionState") == "Race") then return a:GetAttribute("SessionState") == "Race" end
		local aPlace, bPlace = a:GetAttribute("RacePlace") or 0, b:GetAttribute("RacePlace") or 0
		if aPlace ~= bPlace then return aPlace < bPlace end
		return a.UserId < b.UserId
	end)
	return targets
end
function Service.stop(player)
	player:SetAttribute("Spectating", false)
	player:SetAttribute("SpectateTarget", 0)
	focus(player, player)
end
function Service.start(player, targetId)
	if not Service.allowed(player) then return false end
	local targets = Service.targets(player)
	local target
	for _, candidate in targets do
		if candidate.UserId == targetId then target = candidate; break end
	end
	if targetId ~= nil and not target then return false end
	target = target or targets[1]
	player:SetAttribute("Spectating", true)
	player:SetAttribute("SpectateTarget", if target then target.UserId else 0)
	if target then sendView(player, target) else focus(player, player) end
	return true
end
function Service.cycle(player, direction)
	if not Service.allowed(player) then return end
	local targets = Service.targets(player)
	if #targets == 0 then Service.start(player); return end
	local index = 0
	for i, target in targets do if target.UserId == player:GetAttribute("SpectateTarget") then index = i; break end end
	local nextIndex = Presentation.nextSpectatorIndex(index, #targets, direction)
	Service.start(player, targets[nextIndex].UserId)
end
function Service.update()
	for _, player in Players:GetPlayers() do
		if not Service.allowed(player) then
			if player:GetAttribute("Spectating") then Service.stop(player) end
		elseif player:GetAttribute("Spectating") then
			local target = Players:GetPlayerByUserId(player:GetAttribute("SpectateTarget") or 0)
			local character = target and target.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not target or not character or not character:FindFirstChild("HumanoidRootPart") or not Presentation.isTarget(target:GetAttribute("SessionState"), humanoid and humanoid.Health > 0) then
				Service.start(player)
			else sendView(player, target) end
		end
	end
end
return Service
