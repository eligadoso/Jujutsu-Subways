local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Motion = require(Shared:WaitForChild("TrainMotion"))
local Module = {}
function Module.new(context)
	local origin = context.Origin
	local Service = {}
	Service.entries = {}
	local settings = Config.Trains
	local folder = Instance.new("Folder", context.Parent)
	folder.Name = "OncomingTrains"
	local seed = context.Seed + Config.Obstacles.Seed
	local lastLane
	local random = Random.new(seed)
	local untilSpawn = 4

	local function spawn(z, lane)
		local model = Instance.new("Model")
		model.Name = "OncomingTrain"
		local function part(name, size, position, color, material)
			local p = Instance.new("Part")
			p.Name, p.Size, p.Position, p.Color = name, size, position, color
			p.Anchored = true
			-- Contact penalties are handled by server geometry queries, without flinging the rider.
			p.CanCollide, p.CanTouch = false, false
			p.Material = material or Enum.Material.SmoothPlastic
			p.Parent = model
			return p
		end
		local half = settings.Length / 2
		local centerY = (settings.Height + 1.2) / 2
		local body = part("TrainBody", Vector3.new(5.3, settings.Height - 1.2, settings.Length), Vector3.new(0, centerY, 0), Color3.fromRGB(218, 225, 232), Enum.Material.Metal)
		model.PrimaryPart = body
		local nose = part("TrainNose", Vector3.new(5.3, 5, 2), Vector3.new(0, 3.7, half + 1), Color3.fromRGB(39, 98, 179), Enum.Material.Metal)
		part("FrontWindow", Vector3.new(4.5, 2.1, 0.12), Vector3.new(0, 7, half + 0.1), Color3.fromRGB(36, 60, 83), Enum.Material.Glass)
		for _, side in {-1, 1} do
			part("Headlight", Vector3.new(0.65, 0.65, 0.15), Vector3.new(side * 1.7, 3.5, half + 2.1), Color3.fromRGB(255, 242, 177), Enum.Material.Neon)
			part("BlueStripe", Vector3.new(0.08, 1.2, settings.Length), Vector3.new(side * 2.68, 3, 0), Color3.fromRGB(39, 98, 179))
			for step = -half + 4, half - 3, 7 do
				part("Window", Vector3.new(0.08, 2.5, 4), Vector3.new(side * 2.68, 7.5, step), Color3.fromRGB(36, 60, 83), Enum.Material.Glass)
				local wheel = part("Wheel", Vector3.new(0.4, 1.6, 1.6), Vector3.new(side * 2.2, 0.9, step), Color3.fromRGB(27, 31, 39), Enum.Material.Metal)
				wheel.Shape = Enum.PartType.Cylinder
			end
		end
		local x = lane * Config.Track.LaneWidth
		model:PivotTo(CFrame.new(origin + Vector3.new(x, centerY, z)))
		model.Parent = folder
		Service.entries[model] = {
			kind = "Train", model = model, lane = lane, firstLane = lane, width = 1,
			z = z, height = settings.Height, centerY = centerY, age = 0,
			hazards = {body, nose}, motionDelta = Vector3.zero,
			box = {minX = x - 2.65, maxX = x + 2.65, minY = 1.2, maxY = settings.Height, minZ = z - half, maxZ = z + half + 2},
		}
	end

	function Service.update(dt, runners, staticEntries)
		local front, back
		for _, runner in runners do
			if runner.root.Parent and runner.humanoid.Health > 0 then
				local z = runner.root.Position.Z
				front = if front then math.min(front, z) else z
				back = if back then math.max(back, z) else z
			end
		end
		local count = 0
		for model, entry in Service.entries do
			local z = Motion.advance(entry.z, settings.Speed, dt)
			entry.motionDelta = Vector3.new(0, 0, z - entry.z)
			entry.z, entry.age = z, entry.age + dt
			entry.box.minZ, entry.box.maxZ = z - settings.Length / 2, z + settings.Length / 2 + 2
			if not back or z - settings.Length / 2 > back + settings.DespawnDistance or entry.age > 60 then
				model:Destroy()
				Service.entries[model] = nil
			else
				model:PivotTo(CFrame.new(origin + Vector3.new(entry.lane * Config.Track.LaneWidth, entry.centerY, z)))
				count += 1
			end
		end
		if not front or not settings.Enabled then return end
		untilSpawn -= dt
		if untilSpawn <= 0 and count < settings.MaxActive then
			local distance = random:NextNumber(settings.MinSpawnDistance or settings.SpawnDistance, settings.MaxSpawnDistance or settings.SpawnDistance)
			local z = front - distance
			local lanes = Motion.availableLanes(staticEntries, Config.Track, z - settings.Length / 2, back + settings.DespawnDistance + settings.Length / 2)
			local lane = Motion.chooseLane(lanes, lastLane, random:NextNumber())
			if lane then
				spawn(z, lane)
				lastLane = lane
				untilSpawn = random:NextNumber(settings.MinInterval, settings.MaxInterval)
			else
				untilSpawn = 1
			end
		end
	end

	return Service
end
return Module
