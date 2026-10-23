local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Rules = require(Shared:WaitForChild("PowerUpRules"))
local PickupRules = require(Shared:WaitForChild("PickupRules"))
local Style = require(script.Parent:WaitForChild("VisualStyle"))
local Service = {}
local pickupRemote = Instance.new("RemoteEvent")
pickupRemote.Name, pickupRemote.Parent = "PersonalPowerPickup", game:GetService("ReplicatedStorage")
function Service.new(context)
	local settings, entries = Config.PowerUps, {}
	local random = Random.new(context.Seed + 3191)
	local self = {}
	function self.addChunk(index, parent)
		if not Rules.spawns(index, settings) or #settings.Catalog == 0 then return end
		local first = (context.Seed + index * 3) % Config.Track.LaneCount
		local z = -index * Config.Track.ChunkLength + 35
		for attempt = 0, Config.Track.LaneCount - 1 do
			local lane = (first + attempt) % Config.Track.LaneCount - (Config.Track.LaneCount - 1) / 2
			local x = lane * Config.Track.LaneWidth
			local height = context.Obstacles.coinHeight(index, x, z, 3)
			if not height then continue end
			local model = Instance.new("Model")
			model.Name, model.ModelStreamingMode = "PowerUpBackpack", Enum.ModelStreamingMode.Atomic
			local position = context.Origin + Vector3.new(x, height, z)
			local bag = Style.detail(model, "Bag", Vector3.new(1.55, 1.9, 0.85), CFrame.new(position), Color3.fromRGB(164, 80, 238), Enum.Material.SmoothPlastic)
			Style.detail(model, "Pocket", Vector3.new(1.15, 0.85, 0.3), CFrame.new(position + Vector3.new(0, -0.25, 0.54)), Color3.fromRGB(87, 228, 247), Enum.Material.SmoothPlastic)
			Style.detail(model, "Zipper", Vector3.new(0.9, 0.08, 0.08), CFrame.new(position + Vector3.new(0, 0.1, 0.73)), Color3.fromRGB(255, 213, 65), Enum.Material.Neon)
			for _, side in {-1, 1} do
				Style.detail(model, "Strap", Vector3.new(0.2, 1.45, 0.28), CFrame.new(position + Vector3.new(side * 0.48, 0, -0.55)), Color3.fromRGB(76, 52, 130))
			end
			Style.detail(model, "Handle", Vector3.new(0.7, 0.18, 0.28), CFrame.new(position + Vector3.new(0, 1.08, 0)), Color3.fromRGB(255, 213, 65))
			model.PrimaryPart, model.Parent = bag, parent
			local id = context.Parent.Name .. ":" .. context.Seed .. ":" .. index
			model:SetAttribute("PickupId", id)
			game:GetService("CollectionService"):AddTag(model, "PersonalPowerPickup")
			entries[index] = {model = model, position = position, used = {}, id = id}
			break
		end
	end
	function self.removeChunk(index) entries[index] = nil end
	function self.collect(player, runner)
		if runner.powerUp then return end
		local from, to = runner.previousPosition, runner.root.Position
		local segment = to - from
		local lengthSquared = segment:Dot(segment)
		for index, entry in entries do
			local now = workspace:GetServerTimeNow()
			if not PickupRules.available(entry.used[player.UserId], now, runner.powerUp ~= nil, (from-entry.position).Magnitude > settings.PickupRadius) then continue end
			local t = if lengthSquared > 0 then math.clamp((entry.position - from):Dot(segment) / lengthSquared, 0, 1) else 0
			if (entry.position - (from + segment * t)).Magnitude > settings.PickupRadius then continue end
			local power = Rules.choose(settings.Catalog, random:NextNumber())
			if not power then return end
			entry.used[player.UserId] = now + settings.RespawnTime
			pickupRemote:FireClient(player, entry.id, entry.used[player.UserId])
			runner.powerUp = power.Id
			player:SetAttribute("HeldPowerUp", power.Id)
			return
		end
	end
	function self.use(player, runner, direction)
		if not Rules.canUse(player:GetAttribute("SessionState"), runner.humanoid.Health > 0, runner.powerUp) then return end
		local power = runner.powerUp
		runner.powerUp = nil
		player:SetAttribute("HeldPowerUp", "")
		context.UseAbility(player, runner, power, direction or -1)
		player:SetAttribute("LastUsedPowerUp", power)
		player:SetAttribute("PowerUpUsedAt", workspace:GetServerTimeNow())
	end
	return self
end
return Service
