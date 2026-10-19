local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Motion = require(Shared:WaitForChild("TrainMotion"))
local Style = require(script.Parent:WaitForChild("VisualStyle"))
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
		local function detail(name, size, position, color, material)
			return Style.detail(model, name, size, CFrame.new(position), color, material)
		end
		detail("RoofVent", Vector3.new(3.8, 0.18, 12), Vector3.new(0, settings.Height + 0.12, -4), Color3.fromRGB(75, 87, 103))
		local destination = detail("Destination", Vector3.new(4.2, 0.9, 0.08), Vector3.new(0, 9.5, half + 0.1), Color3.fromRGB(20, 31, 44))
		Style.label(destination, "01  CENTRAL", Color3.fromRGB(137, 255, 219))
		detail("FrontBumper", Vector3.new(4.8, 0.45, 0.12), Vector3.new(0, 1.7, half + 2.05), Color3.fromRGB(44, 53, 66))
		local nose = part("TrainNose", Vector3.new(5.3, 5, 2), Vector3.new(0, 3.7, half + 1), Color3.fromRGB(39, 98, 179), Enum.Material.Metal)
		detail("LowerChassis", Vector3.new(4.5, 0.65, settings.Length - 1), Vector3.new(0, 1.2, 0), Color3.fromRGB(36, 34, 49))
		for vent = -5, 5, 1.25 do
			detail("VentSlat", Vector3.new(3.4, 0.03, 0.15), Vector3.new(0, settings.Height + 0.22, -4 + vent), Color3.fromRGB(35, 38, 52))
		end
		for _, endZ in {-half + 0.15, half - 0.15} do
			detail("EndRoofBand", Vector3.new(5.35, 0.3, 0.18), Vector3.new(0, settings.Height - 0.3, endZ), Color3.fromRGB(118, 67, 178))
		end
		detail("FrontDivider", Vector3.new(0.1, 2.1, 0.08), Vector3.new(0, 7, half + 0.21), Color3.fromRGB(162, 177, 194))
		detail("FrontWiper", Vector3.new(1.6, 0.06, 0.08), Vector3.new(-1.15, 6.25, half + 0.24), Color3.fromRGB(21, 25, 34))
		part("FrontWindow", Vector3.new(4.5, 2.1, 0.12), Vector3.new(0, 7, half + 0.1), Color3.fromRGB(36, 60, 83), Enum.Material.Glass)
		for _, side in {-1, 1} do
			detail("FrontLightBar", Vector3.new(0.12, 2.7, 0.1), Vector3.new(side * 2.4, 3.8, half + 2.12), Color3.fromRGB(126, 235, 255), Enum.Material.Neon)
			detail("TailLight", Vector3.new(0.5, 0.4, 0.08), Vector3.new(side * 1.8, 3.5, -half - 0.06), Color3.fromRGB(255, 80, 114), Enum.Material.Neon)
			for _, doorZ in {-half + 12, half - 12} do
				detail("Door", Vector3.new(0.07, 6.8, 3.6), Vector3.new(side * 2.73, 5, doorZ), Color3.fromRGB(152, 170, 188))
				detail("DoorGlass", Vector3.new(0.08, 2.6, 2.8), Vector3.new(side * 2.78, 6.7, doorZ), Color3.fromRGB(35, 64, 83), Enum.Material.Glass)
				detail("DoorSeam", Vector3.new(0.09, 6.8, 0.08), Vector3.new(side * 2.8, 5, doorZ), Color3.fromRGB(53, 66, 80))
			end
			detail("RoofTrim", Vector3.new(0.08, 0.18, settings.Length), Vector3.new(side * 2.69, settings.Height - 0.6, 0), Color3.fromRGB(114, 213, 222))
			local headlight = part("Headlight", Vector3.new(0.65, 0.65, 0.15), Vector3.new(side * 1.7, 3.5, half + 2.1), Color3.fromRGB(255, 242, 177), Enum.Material.Neon)
			local beam = Instance.new("SpotLight")
			beam.Face, beam.Angle, beam.Range = Enum.NormalId.Back, 65, 28
			beam.Brightness, beam.Color, beam.Shadows = 1.2, Color3.fromRGB(227, 244, 255), false
			beam.Parent = headlight
			part("BlueStripe", Vector3.new(0.08, 1.2, settings.Length), Vector3.new(side * 2.68, 3, 0), Color3.fromRGB(39, 98, 179))
			for step = -half + 4, half - 3, 7 do
				if math.abs(step - (-half + 12)) > 4 and math.abs(step - (half - 12)) > 4 then
					part("Window", Vector3.new(0.08, 2.5, 4), Vector3.new(side * 2.68, 7.5, step), Color3.fromRGB(36, 60, 83), Enum.Material.Glass)
				end
				local wheel = part("Wheel", Vector3.new(0.4, 1.6, 1.6), Vector3.new(side * 2.2, 0.9, step), Color3.fromRGB(27, 31, 39), Enum.Material.Metal)
				wheel.Shape = Enum.PartType.Cylinder
				local hub = detail("WheelHub", Vector3.new(0.08, 0.8, 0.8), Vector3.new(side * 2.44, 0.9, step), Color3.fromRGB(128, 144, 164))
				hub.Shape = Enum.PartType.Cylinder
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
