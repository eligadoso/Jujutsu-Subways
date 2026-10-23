local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Teams = game:GetService("Teams")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Rules = require(Shared:WaitForChild("MatchRules"))
local Presentation = require(Shared:WaitForChild("PlayerPresentation"))
local RunnerWorld = require(script:WaitForChild("RunnerWorld"))
local Lobby = require(script:WaitForChild("Lobby"))
local Spectators = require(script:WaitForChild("SpectatorService"))
local DeveloperFactory = require(script:WaitForChild("DeveloperService"))
local random = Random.new(workspace:GetAttribute("WorldSeed") or Random.new():NextInteger(1, 1000000000))
local rules = Rules.new(Config.Matches, workspace:GetServerTimeNow())
local worlds, sessions, soloSlots, cooldowns = {}, {}, {}, {}
local raceWorld
local Developers = DeveloperFactory.new({sessions = sessions, worlds = worlds, rules = rules})
local teamObjects = {}
for _, name in {"AFK", "Jugando"} do
	local team = Teams:FindFirstChild(name) or Instance.new("Team")
	team.Name, team.AutoAssignable = name, false
	team.TeamColor = BrickColor.new(if name == "Jugando" then "Bright green" else "Medium stone grey")
	team.Parent = Teams
	teamObjects[name] = team
end

local function remote(name)
	local event = Instance.new("RemoteEvent")
	event.Name, event.Parent = name, ReplicatedStorage
	return event
end
local input = remote("RunnerInput")
local sessionAction = remote("SessionAction")
local rosterUpdate = remote("RosterUpdate")
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end
require(script:WaitForChild("VisualStyle")).lighting()
if not PhysicsService:IsCollisionGroupRegistered("Runners") then PhysicsService:RegisterCollisionGroup("Runners") end
PhysicsService:CollisionGroupSetCollidable("Runners", "Runners", false)
Lobby.build()

local function destroyWorld(world)
	worlds[world] = nil
	if world.slot then soloSlots[world.slot] = nil end
	world:destroy()
end

local function leaveSession(player, result, finished)
	local world = sessions[player]
	sessions[player] = nil
	if world then
		world:removePlayer(player)
		if world.kind == "Solo" then destroyWorld(world) end
	end
	player:SetAttribute("SessionState", "Lobby")
	player:SetAttribute("RunDistance", if finished then (rules.entries[player.UserId] and rules.entries[player.UserId].progress or 0) else 0)
	if result then player:SetAttribute("MatchResult", result) end
	Lobby.place(player)
	Spectators.stop(player)
	if finished then
		player:SetAttribute("SessionState", "Finished")
		player:SetAttribute("FinishedRaceId", rules.roundId)
		Spectators.start(player)
	end
end

local function newWorld(name, kind, slot, mode, distance)
	local world = RunnerWorld.new({
		Name = name, Kind = kind, OffsetX = slot * 1000,
		Seed = random:NextInteger(1, 1000000000), CoinMode = mode, Distance = distance,
	})
	world.slot = if kind == "Solo" then slot else nil
	worlds[world] = true
	return world
end

local function ready(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart") ~= nil and player:GetAttribute("LobbyReady") == true
end

local function eligiblePlayers()
	local result = {}
	for _, player in Players:GetPlayers() do
		if Rules.eligible(player:GetAttribute("SessionState"), player:GetAttribute("AFK") == true, ready(player)) then table.insert(result, player) end
	end
	table.sort(result, function(a, b) return a.UserId < b.UserId end)
	return result
end

local function startRace()
	local candidates = eligiblePlayers()
	if #candidates == 0 then
		rules.deadline = workspace:GetServerTimeNow() + Config.Matches.Intermission
		return
	end
	local modeName = if #candidates >= 2 and rules.roundId % 2 == 1 then "Elimination" else Config.Matches.DefaultMode
	local mode = Config.Matches.Modes[modeName]
	raceWorld = newWorld("Race_" .. (rules.roundId + 1), "Race", 0, mode.CoinMode, if mode.CaptureInterval then nil else mode.Distance)
	local ids, participants = {}, {}
	for i, player in candidates do
		Spectators.stop(player)
		if raceWorld:addPlayer(player, (i - 1) % Config.Track.LaneCount - (Config.Track.LaneCount - 1) / 2) then
			sessions[player] = raceWorld
			table.insert(ids, player.UserId)
			table.insert(participants, player)
		end
	end
	if #ids == 0 then
		destroyWorld(raceWorld)
		raceWorld = nil
		rules.deadline = workspace:GetServerTimeNow() + Config.Matches.Intermission
		return
	end
	rules:begin(workspace:GetServerTimeNow(), ids, modeName)
	for _, player in participants do
		local entry = rules.entries[player.UserId]
		entry.name = player.DisplayName
		player:SetAttribute("MatchResult", "")
		player:SetAttribute("RaceId", rules.roundId)
		player:SetAttribute("RaceDistance", mode.Distance)
		player:SetAttribute("RaceDeadline", rules.deadline)
		player:SetAttribute("RacePlace", 0)
		player:SetAttribute("FinishedRaceId", 0)
		player:SetAttribute("RaceStatus", "Running")
	end
end

sessionAction.OnServerEvent:Connect(function(player, action, targetId)
	local now = workspace:GetServerTimeNow()
	if now < (cooldowns[player] or 0) then return end
	cooldowns[player] = now + 0.35
	local state = player:GetAttribute("SessionState")
	if action == "ToggleAFK" and (state == "Lobby" or state == "Finished") then
		player:SetAttribute("AFK", not player:GetAttribute("AFK"))
		if not Spectators.allowed(player) then Spectators.stop(player) end
	elseif action == "StartSolo" and (state == "Lobby" or state == "Finished") and ready(player) then
		Spectators.stop(player)
		local slot = 1
		while soloSlots[slot] do slot += 1 end
		soloSlots[slot] = true
		local world = newWorld("Solo_" .. player.UserId, "Solo", slot, Config.DefaultMode)
		if world:addPlayer(player, 0) then
			sessions[player] = world
			player:SetAttribute("MatchResult", "")
			player:SetAttribute("FinishedRaceId", 0)
			player:SetAttribute("RaceId", 0)
			player:SetAttribute("RaceStatus", "None")
		else destroyWorld(world) end
	elseif action == "EndSolo" and state == "Solo" then
		leaveSession(player, "Practica terminada")
	elseif action == "Spectate" then Spectators.start(player, targetId)
	elseif action == "SpectateNext" then Spectators.cycle(player, 1)
	elseif action == "SpectatePrevious" then Spectators.cycle(player, -1)
	elseif action == "StopSpectate" then Spectators.stop(player)
	end
end)

input.OnServerEvent:Connect(function(player, action)
	local world = sessions[player]
	if world and (player:GetAttribute("SessionState") == "Solo" or player:GetAttribute("SessionState") == "Race") then world:input(player, action) end
end)

local function setupPlayer(player)
	player:SetAttribute("SessionState", "Lobby")
	player:SetAttribute("AFK", false)
	player:SetAttribute("LobbyReady", false)
	player:SetAttribute("Coins", 0)
	player:SetAttribute("MatchResult", "")
	player:SetAttribute("RaceStatus", "None")
	Spectators.stop(player)
	Developers.setupPlayer(player)
	local stats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	stats.Name, stats.Parent = "leaderstats", player
	local coins = stats:FindFirstChild("Coins") or Instance.new("IntValue")
	coins.Name, coins.Parent = "Coins", stats
	local function characterAdded(character)
		player:SetAttribute("LobbyReady", false)
		if sessions[player] then
			rules:withdraw(player.UserId)
			leaveSession(player, "Carrera interrumpida")
		end
		local humanoid = character:WaitForChild("Humanoid")
		local root = character:WaitForChild("HumanoidRootPart")
		if player.Character ~= character then return end
		local function group(item)
			if item:IsA("BasePart") then item.CollisionGroup = "Runners" end
		end
		for _, item in character:GetDescendants() do group(item) end
		character.DescendantAdded:Connect(group)
		humanoid.UseJumpPower, humanoid.JumpPower = true, 50
		root.AssemblyLinearVelocity = Vector3.zero
		Lobby.place(player)
		player:SetAttribute("LobbyReady", true)
	end
	player.CharacterAdded:Connect(characterAdded)
	player.CharacterRemoving:Connect(function()
		player:SetAttribute("LobbyReady", false)
		if sessions[player] then
			rules:withdraw(player.UserId)
			leaveSession(player, "Carrera interrumpida")
		end
	end)
	if player.Character then task.spawn(characterAdded, player.Character) end
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do setupPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
	rules:withdraw(player.UserId)
	leaveSession(player)
	Developers.removePlayer(player)
	cooldowns[player] = nil
end)

local function updateRace(now)
	if rules.state ~= "Race" then return end
	local finished = {}
	for id, entry in rules.entries do
		if entry.status ~= "Running" then continue end
		local player = Players:GetPlayerByUserId(id)
		local runner = player and raceWorld and raceWorld.runners[player]
		if not runner or not runner.root.Parent or runner.humanoid.Health <= 0 then
			rules:withdraw(id)
			if player and sessions[player] then leaveSession(player, "Carrera interrumpida") end
			continue
		end
		local progress = math.max(0, 25 - runner.root.Position.Z)
		local time = if rules.mode.CaptureInterval then nil else Rules.crossingTime(entry.progress, progress, entry.checked, now, rules.mode.Distance)
		entry.progress, entry.checked = progress, now
		if time then table.insert(finished, {player = player, time = time}) end
	end
	if rules.mode.CaptureInterval then
		local result = rules:capture(now)
		if result and result.captured then
			local player = Players:GetPlayerByUserId(result.captured)
			if player then leaveSession(player, "¡Te atraparon!", true) end
		end
		if result and result.winner then
			local player = Players:GetPlayerByUserId(result.winner)
			if player then leaveSession(player, "¡Ultimo superviviente!", true) end
		end
	end
	table.sort(finished, function(a, b)
		if a.time ~= b.time then return a.time < b.time end
		return a.player.UserId < b.player.UserId
	end)
	for _, arrival in finished do
		local player = arrival.player
		if rules:finish(player.UserId, arrival.time) then
			local place
			for i, entry in rules:standings() do if entry.id == player.UserId then place = i; break end end
			player:SetAttribute("RacePlace", place)
			player:SetAttribute("RaceStatus", "Finished")
			leaveSession(player, string.format("Puesto %d | %.1f s", place, rules.entries[player.UserId].elapsed), true)
		end
	end
end

local function publish()
	workspace:SetAttribute("MatchState", rules.state)
	workspace:SetAttribute("MatchMode", rules.modeName or "Race")
	workspace:SetAttribute("CaptureDeadline", rules.nextCapture or 0)
	workspace:SetAttribute("MatchDeadline", rules.deadline)
	workspace:SetAttribute("MatchDuration", if rules.state == "Race" and rules.started then rules.deadline - rules.started else Config.Matches.Intermission)
	workspace:SetAttribute("MatchName", if rules.mode then rules.mode.DisplayName else Config.Matches.Modes[Config.Matches.DefaultMode].DisplayName)
	workspace:SetAttribute("MatchDistance", if rules.mode then rules.mode.Distance else Config.Matches.Modes[Config.Matches.DefaultMode].Distance)
	workspace:SetAttribute("AvailablePlayers", #eligiblePlayers())
	local standings = rules:standings()
	local total = #standings
	local remaining, completed = 0, 0
	for i, entry in standings do
		if entry.status == "Running" then remaining += 1 elseif entry.status == "Finished" then completed += 1 end
		local player = Players:GetPlayerByUserId(entry.id)
		if player and player:GetAttribute("RaceId") == rules.roundId then
			player:SetAttribute("RacePlace", i)
			player:SetAttribute("RacePlayers", total)
			player:SetAttribute("RaceStatus", entry.status)
		end
	end
	workspace:SetAttribute("MatchRemaining", remaining)
	workspace:SetAttribute("MatchFinished", completed)
	workspace:SetAttribute("MatchParticipants", total)
	for player, world in sessions do
		local runner = world.runners[player]
		if runner and runner.root.Parent then player:SetAttribute("RunDistance", math.max(0, math.floor(25 - runner.root.Position.Z))) end
	end
	Spectators.update()
	local roster = {}
	for _, player in Players:GetPlayers() do
		local state = player:GetAttribute("SessionState") or "Lobby"
		local group = Presentation.team(state)
		player.Team, player.Neutral = teamObjects[group], false
		table.insert(roster, {
			id = player.UserId, name = player.DisplayName, username = player.Name,
			team = group, state = state, afk = player:GetAttribute("AFK") == true,
			studs = player:GetAttribute("RunDistance") or 0, coins = player:GetAttribute("Coins") or 0,
			place = player:GetAttribute("RacePlace") or 0,
		})
	end
	rosterUpdate:FireAllClients(Presentation.sort(roster))
	Developers.update()
end

RunService.PreSimulation:Connect(function(dt)
	for world in worlds do world:physics(dt) end
end)
local publishElapsed = 0
RunService.Heartbeat:Connect(function(dt)
	for world in worlds do world:heartbeat(dt) end
	local now = workspace:GetServerTimeNow()
	updateRace(now)
	local event = rules:tick(now)
	if event == "Ended" then
		for id, entry in rules.entries do
			local player = Players:GetPlayerByUserId(id)
			if player and sessions[player] == raceWorld then
				leaveSession(player, if entry.status == "TimedOut" then "Tiempo agotado: no llegaste a la meta" else "Carrera terminada")
			end
			if player and player:GetAttribute("SessionState") == "Finished" and player:GetAttribute("FinishedRaceId") == rules.roundId then
				player:SetAttribute("SessionState", "Lobby")
				if not player:GetAttribute("AFK") then Spectators.stop(player) end
			end
		end
		if raceWorld then destroyWorld(raceWorld); raceWorld = nil end
	elseif event == "Start" then startRace() end
	publishElapsed += dt
	if publishElapsed >= 0.1 then publishElapsed = 0; publish() end
end)
publish()
