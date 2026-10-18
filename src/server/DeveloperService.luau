local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Access = require(Shared:WaitForChild("DevAccess"))
local Motion = require(Shared:WaitForChild("RunnerMotion"))
local Module = {}

function Module.new(context)
	local service = {}
	local authorized, lastCommand = {}, {}
	local telemetry = Instance.new("RemoteEvent", ReplicatedStorage)
	telemetry.Name = "DevTelemetry"
	local function toggle(player)
		if not authorized[player] then return end
		local now = workspace:GetServerTimeNow()
		if now - (lastCommand[player] or 0) < 0.4 then return end
		lastCommand[player] = now
		player:SetAttribute("DevMenuOpen", not player:GetAttribute("DevMenuOpen"))
	end
	telemetry.OnServerEvent:Connect(function(player, action)
		if authorized[player] and action == "Close" then player:SetAttribute("DevMenuOpen", false) end
	end)
	local command = Instance.new("TextChatCommand")
	command.Name, command.PrimaryAlias = "DevMenuCommand", "/menu"
	command.Parent = TextChatService
	command.Triggered:Connect(function(source)
		local player = source and Players:GetPlayerByUserId(source.UserId)
		if player then toggle(player) end
	end)
	function service.setupPlayer(player)
		local creatorType = if game.CreatorType == Enum.CreatorType.User then "User" else "Group"
		authorized[player] = Access.allowed(player.UserId, creatorType, game.CreatorId, RunService:IsStudio(), Config.Developers)
		player:SetAttribute("IsDeveloper", authorized[player])
		player:SetAttribute("DevMenuOpen", false)
		player.Chatted:Connect(function(message)
			if message:lower():match("^%s*/menu%s*$") then toggle(player) end
		end)
	end
	function service.removePlayer(player)
		authorized[player], lastCommand[player] = nil, nil
	end
	local function count(items)
		local n = 0
		for _ in items do n += 1 end
		return n
	end
	function service.update()
		local now = workspace:GetServerTimeNow()
		for player, allowed in authorized do
			if not allowed or not player:GetAttribute("DevMenuOpen") then continue end
			local world = context.sessions[player]
			local runner = world and world.runners[player]
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			telemetry:FireClient(player, {
				state = player:GetAttribute("SessionState"), phase = context.rules.state,
				mode = if world then world.coinMode else "Lobby",
				speed = if runner then runner.speed else (humanoid and humanoid.WalkSpeed or 0),
				actual = if root then -root.AssemblyLinearVelocity.Z else 0,
				lane = runner and runner.lane or 0,
				laneTime = if runner then Motion.laneDurationForCoins(runner.collectedCoins, world.coinMode) else 0,
				coins = player:GetAttribute("Coins") or 0, pickups = runner and runner.collectedCoins or 0,
				studs = player:GetAttribute("RunDistance") or 0,
				ramp = runner and runner.rampEntry ~= nil or false,
				crouch = runner and runner.crouch.active or false,
				recovery = if runner then math.max(0, (runner.protectedUntil or 0) - now) else 0,
				origin = world and world.origin.X or 0,
				worlds = count(context.worlds), chunks = world and count(world.chunks) or 0,
				trains = world and count(world.trains.entries) or 0,
				runners = world and count(world.runners) or 0,
				spectating = player:GetAttribute("SpectateTarget") or 0,
				round = context.rules.roundId, time = math.max(0, context.rules.deadline - now),
			})
		end
	end
	return service
end
return Module
