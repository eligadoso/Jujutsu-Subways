local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Rules = require(Shared:WaitForChild("PowerUpRules"))
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
			model.Name, model.ModelStreamingMode = "PowerUpPickup", Enum.ModelStreamingMode.Atomic
			local position = context.Origin + Vector3.new(x, height, z)
			local gem = Style.detail(model, "MysteryDiamond", Vector3.new(1.7, 1.7, 0.7), CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 4), Color3.fromRGB(167, 78, 255), Enum.Material.Neon)
			Style.detail(model, "DiamondCore", Vector3.new(1.15, 1.15, 0.75), gem.CFrame, Color3.fromRGB(91, 230, 255), Enum.Material.SmoothPlastic)
			model.PrimaryPart, model.Parent = gem, parent
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
			if not Rules.canCollect(entry.used, player.UserId, runner.powerUp) then continue end
			local t = if lengthSquared > 0 then math.clamp((entry.position - from):Dot(segment) / lengthSquared, 0, 1) else 0
			if (entry.position - (from + segment * t)).Magnitude > settings.PickupRadius then continue end
			local power = Rules.choose(settings.Catalog, random:NextNumber())
			if not power then return end
			entry.used[player.UserId] = true
			pickupRemote:FireClient(player, entry.id)
			runner.powerUp = power.Id
			player:SetAttribute("HeldPowerUp", power.Id)
			return
		end
	end
	function self.use(player, runner)
		if not Rules.canUse(player:GetAttribute("SessionState"), runner.humanoid.Health > 0, runner.powerUp) then return end
		local power = runner.powerUp
		runner.powerUp = nil
		player:SetAttribute("HeldPowerUp", "")
		-- Consumption only: no gameplay ability is executed yet.
		player:SetAttribute("LastUsedPowerUp", power)
		player:SetAttribute("PowerUpUsedAt", workspace:GetServerTimeNow())
	end
	return self
end
return Service
