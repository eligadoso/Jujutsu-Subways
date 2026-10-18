local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Motion = require(Shared:WaitForChild("RunnerMotion"))
local Skateboard = require(script.Parent:WaitForChild("Skateboard"))
local Crouch = require(script.Parent:WaitForChild("Crouch"))
local CoinFactory = require(script.Parent:WaitForChild("CoinService"))
local ObstacleFactory = require(script.Parent:WaitForChild("ObstacleService"))
local TrainFactory = require(script.Parent:WaitForChild("TrainService"))
local World = {}
World.__index = World

function World.new(options)
	local self = setmetatable({runners = {}, origin = Vector3.new(options.OffsetX, 0, 0), kind = options.Kind}, World)
	local world = Instance.new("Folder", workspace)
	world.Name = options.Name
	self.folder = world
	local origin = self.origin
	local context = {Origin = origin, Parent = world, Seed = options.Seed, CoinMode = options.CoinMode}
	local Obstacles = ObstacleFactory.new(context)
	context.Obstacles = Obstacles
	local Coins = CoinFactory.new(context)
	local Trains = TrainFactory.new(context)
	Obstacles.setMovingEntries(Trains.entries)
	local activeMode = options.CoinMode or Config.DefaultMode
	local CHUNK_LENGTH = Config.Track.ChunkLength
	local HALF_WIDTH = (Config.Track.LaneCount * Config.Track.LaneWidth + 4) / 2
	local chunks = {}
	local runners = self.runners
	self.obstacles, self.coins, self.trains = Obstacles, Coins, Trains
	self.coinMode = activeMode

	local function part(parent, name, size, position, color, material)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position, p.Color = name, size, position + origin, color
		p.Anchored = true
		p.Material = material or Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end

	local function createChunk(index)
		local model = Instance.new("Model")
		model.Name = "Section_" .. index
		local z = -index * CHUNK_LENGTH
		local random = Random.new(index + context.Seed)
		part(model, "TrackBed", Vector3.new(HALF_WIDTH * 2, 2, CHUNK_LENGTH), Vector3.new(0, -1, z), Color3.fromRGB(65, 70, 82), Enum.Material.Asphalt)
		for lane = Motion.MinLane, Motion.MaxLane do
			local x = lane * Motion.LaneWidth
			for _, offset in {-1.9, 1.9} do
				part(model, "Rail", Vector3.new(0.16, 0.12, CHUNK_LENGTH), Vector3.new(x + offset, 0.07, z), Color3.fromRGB(180, 190, 202), Enum.Material.Metal)
			end
			for step = -45, 45, 6 do
				part(model, "Sleeper", Vector3.new(4.7, 0.08, 0.65), Vector3.new(x, 0.04, z + step), Color3.fromRGB(105, 85, 70), Enum.Material.Wood)
			end
		end
		for _, side in {-1, 1} do
			part(model, "Sidewalk", Vector3.new(5, 1, CHUNK_LENGTH), Vector3.new(side * (HALF_WIDTH + 2.5), 0, z), Color3.fromRGB(173, 177, 185), Enum.Material.Concrete)
			for step = -40, 40, 20 do
				local height = random:NextInteger(18, 48)
				local color = Color3.fromHSV(random:NextNumber(0.04, 0.65), 0.25, random:NextNumber(0.5, 0.8))
				part(model, "Building", Vector3.new(14, height, 18), Vector3.new(side * (HALF_WIDTH + 13), height / 2, z + step), color, Enum.Material.Brick)
				for floor = 5, height - 2, 6 do
					for offset = -5, 5, 5 do
						local window = part(model, "Window", Vector3.new(0.12, 2.8, 2.4), Vector3.new(side * (HALF_WIDTH + 5.95), floor, z + step + offset), Color3.fromRGB(255, 220, 145), Enum.Material.Neon)
						window.CanCollide = false
					end
				end
			end
			for step = -25, 25, 50 do
				part(model, "LampPost", Vector3.new(0.35, 10, 0.35), Vector3.new(side * (HALF_WIDTH + 0.5), 5, z + step), Color3.fromRGB(40, 50, 65), Enum.Material.Metal)
				part(model, "Lamp", Vector3.new(2, 0.3, 1), Vector3.new(side * HALF_WIDTH, 10, z + step), Color3.fromRGB(255, 236, 175), Enum.Material.Neon)
			end
		end
		model.Parent = world
		chunks[index] = model
		if not options.Distance or math.abs(z - (25 - options.Distance)) > 80 then
			Obstacles.addChunk(index, model)
		end
		Coins.addChunk(index, model)
	end

	local function refreshWorld()
		local needed = {}
		for _, runner in runners do
			local root = runner.root
			local current = root and math.floor((-root.Position.Z + CHUNK_LENGTH / 2) / CHUNK_LENGTH) or 0
			for index = current - 2, current + 8 do needed[index] = true end
		end
		for index = -1, 2 do needed[index] = true end
		for index in needed do
			if not chunks[index] then createChunk(index) end
		end
		for index, chunk in chunks do
			if not needed[index] then
				Coins.removeChunk(index)
				Obstacles.removeChunk(index)
				chunk:Destroy()
				chunks[index] = nil
			end
		end
	end


	self.refresh = refreshWorld
	self.chunks = chunks
	refreshWorld()
	if options.Distance then
		local z = 25 - options.Distance
		local width = Config.Track.LaneCount * Config.Track.LaneWidth + 4
		for _, side in {-1, 1} do
			part(world, "FinishPost", Vector3.new(1, 24, 1), Vector3.new(side * (width / 2), 12, z), Color3.fromRGB(66, 227, 160))
		end
		local arch = part(world, "Finish", Vector3.new(width + 1, 3, 1), Vector3.new(0, 24, z), Color3.fromRGB(66, 227, 160))
		local gui = Instance.new("SurfaceGui", arch)
		gui.Face = Enum.NormalId.Back
		local label = Instance.new("TextLabel", gui)
		label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		label.Text, label.TextScaled = "META", true
		label.Font, label.TextColor3 = Enum.Font.GothamBold, Color3.fromRGB(18, 39, 42)
		for stripe = 0, Config.Track.LaneCount * 2 - 1 do
			part(world, "FinishStripe", Vector3.new(3, 0.05, 3), Vector3.new(-width / 2 + 2 + stripe * 3, 0.15, z), if stripe % 2 == 0 then Color3.new(1, 1, 1) else Color3.new(0, 0, 0))
		end
	end
	self.elapsed = 0
	return self
end

function World:addPlayer(player, lane)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not humanoid or humanoid.Health <= 0 then return false end
	self.coins.setupPlayer(player)
	self.coins.resetPlayer(player)
	local originalHeight = humanoid.HipHeight
	local speed = Motion.speedForCoins(0, self.coinMode)
	humanoid.WalkSpeed, humanoid.AutoRotate = speed, false
	humanoid.UseJumpPower, humanoid.JumpPower = true, 50
	root.CFrame = CFrame.new(self.origin + Vector3.new(lane * Motion.LaneWidth, 5, 25))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	Skateboard.equip(character, humanoid, root)
	root:SetNetworkOwner(nil)
	local attachment = Instance.new("Attachment", root)
	attachment.Name = "RunnerAttachment"
	local velocity = Instance.new("LinearVelocity")
	velocity.Name, velocity.Attachment0 = "RunnerVelocity", attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PrimaryTangentAxis, velocity.SecondaryTangentAxis = Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)
	velocity.ForceLimitsEnabled = false
	velocity.PlaneVelocity = Vector2.new(0, -speed)
	velocity.Parent = root
	local facing = Instance.new("AlignOrientation")
	facing.Name, facing.Mode = "RunnerFacing", Enum.OrientationAlignmentMode.OneAttachment
	facing.Attachment0, facing.CFrame, facing.RigidityEnabled = attachment, CFrame.identity, true
	facing.Parent = root
	self.runners[player] = {
		root = root, humanoid = humanoid, velocity = velocity, lane = lane,
		previousPosition = root.Position, crouch = Crouch.create(character, humanoid),
		collectedCoins = 0, speed = speed, originalHeight = originalHeight, attachment = attachment, facing = facing,
	}
	character:SetAttribute("RunnerReady", true)
	player:SetAttribute("RecoveringUntil", 0)
	player:SetAttribute("TrackOriginX", self.origin.X)
	player:SetAttribute("RunDistance", 0)
	player:SetAttribute("SessionState", self.kind)
	self.refresh()
	return true
end

function World:removePlayer(player)
	local runner = self.runners[player]
	if not runner then return end
	self.runners[player] = nil
	self.obstacles.clearRamp(runner)
	Crouch.set(runner.crouch, false)
	runner.velocity:Destroy()
	runner.facing:Destroy()
	runner.attachment:Destroy()
	local character = runner.root.Parent
	if character then
		local board = character:FindFirstChild("Skateboard")
		if board then board:Destroy() end
		character:SetAttribute("Skateboarding", false)
		character:SetAttribute("RunnerReady", false)
		runner.humanoid.HipHeight = runner.originalHeight
		runner.humanoid.AutoRotate = true
		runner.humanoid.WalkSpeed = 16
		runner.root.AssemblyLinearVelocity = Vector3.zero
		if runner.root:IsDescendantOf(workspace) then runner.root:SetNetworkOwnershipAuto() end
	end
end

function World:input(player, action)
	local runner = self.runners[player]
	if not runner or not runner.root.Parent or runner.humanoid.Health <= 0 then return end
	local humanoid = runner.humanoid
	if action == "Left" then runner.lane = Motion.changeLane(runner.lane, -1)
	elseif action == "Right" then runner.lane = Motion.changeLane(runner.lane, 1)
	elseif action == "CrouchStart" then
		Crouch.set(runner.crouch, true)
		if humanoid.FloorMaterial == Enum.Material.Air then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			local v = runner.root.AssemblyLinearVelocity
			runner.root.AssemblyLinearVelocity = Vector3.new(v.X, Motion.verticalVelocity(v.Y, true, true), v.Z)
		end
	elseif action == "CrouchEnd" then Crouch.set(runner.crouch, false)
	elseif action == "Jump" and not runner.crouch.active and humanoid.FloorMaterial ~= Enum.Material.Air then
		if runner.rampEntry then
			self.obstacles.clearRamp(runner)
			runner.rampJumpUntil = workspace:GetServerTimeNow() + 0.4
		end
		humanoid.Jump = true
	end
end

function World:physics(dt)
	for player, runner in self.runners do
		if not runner.root.Parent or runner.humanoid.Health <= 0 then continue end
		if workspace:GetServerTimeNow() < (runner.pauseUntil or 0) then
			runner.velocity.PlaneVelocity = Vector2.zero
			runner.humanoid:Move(Vector3.zero, false)
			continue
		end
		local speed = Motion.speedForCoins(runner.collectedCoins, self.coinMode)
		self.obstacles.prepareRamp(runner, dt, speed)
		runner.speed = speed
		local duration = Motion.laneDurationForCoins(runner.collectedCoins, self.coinMode)
		local x, z = Motion.velocity(runner.lane, runner.root.Position.X - self.origin.X, dt, speed, duration)
		if runner.crouch.active then
			runner.humanoid.Jump = false
			local v = runner.root.AssemblyLinearVelocity
			local y = Motion.verticalVelocity(v.Y, true, runner.humanoid.FloorMaterial == Enum.Material.Air)
			if y ~= v.Y then runner.root.AssemblyLinearVelocity = Vector3.new(v.X, y, v.Z) end
		end
		runner.velocity.PlaneVelocity = Vector2.new(x, z)
		local direction = Vector3.new(x, 0, z)
		runner.humanoid.WalkSpeed = direction.Magnitude
		runner.humanoid:Move(direction.Unit, false)
	end
end

function World:recover(player, runner, hit)
	local lane, z = self.obstacles.recovery(runner, hit)
	self.obstacles.clearRamp(runner)
	Crouch.set(runner.crouch, false)
	local root, humanoid = runner.root, runner.humanoid
	local clearance = root.Size.Y / 2 + humanoid.HipHeight
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = root.Parent:FindFirstChild("Left Leg")
		clearance += if leg then leg.Size.Y else 2
	end
	runner.lane, runner.collectedCoins = lane, 0
	runner.velocity.PlaneVelocity = Vector2.zero
	root.CFrame = CFrame.new(self.origin + Vector3.new(lane * Motion.LaneWidth, clearance + 0.2, z))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	runner.previousPosition, runner.previousBodyCFrames = root.Position, {}
	local now = workspace:GetServerTimeNow()
	runner.pauseUntil, runner.protectedUntil = now + Config.Crash.PauseDuration, now + Config.Crash.ProtectionDuration
	player:SetAttribute("CoinsLost", self.coins.resetPlayer(player))
	runner.speed = Motion.speedForCoins(0, self.coinMode)
	player:SetAttribute("RecoveringUntil", runner.protectedUntil)
	root.Parent:SetAttribute("HitObstacle", hit.kind)
	self.refresh()
end

function World:heartbeat(dt)
	self.trains.update(dt, self.runners, self.obstacles.staticEntries())
	for player, runner in self.runners do
		if not runner.root.Parent or runner.humanoid.Health <= 0 then continue end
		local protected = workspace:GetServerTimeNow() < (runner.protectedUntil or 0)
		local hit = if protected then false else self.obstacles.check(runner)
		if hit then self:recover(player, runner, hit)
		elseif not protected then
			runner.collectedCoins += self.coins.collect(player, runner.previousPosition, runner.root.Position)
		end
		runner.previousPosition = runner.root.Position
	end
	self.elapsed += dt
	if self.elapsed >= 0.5 then self.elapsed = 0; self.refresh() end
end

function World:destroy()
	local players = {}
	for player in self.runners do table.insert(players, player) end
	for _, player in players do self:removePlayer(player) end
	self.folder:Destroy()
end

return World
