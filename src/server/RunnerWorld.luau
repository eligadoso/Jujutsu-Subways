local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Motion = require(Shared:WaitForChild("RunnerMotion"))
local CrashMotion = require(Shared:WaitForChild("CrashMotion"))
local Drafting = require(Shared:WaitForChild("Drafting"))
local Skateboard = require(script.Parent:WaitForChild("Skateboard"))
local Crouch = require(script.Parent:WaitForChild("Crouch"))
local CoinFactory = require(script.Parent:WaitForChild("CoinService"))
local PowerUpFactory = require(script.Parent:WaitForChild("PowerUpService"))
local ObstacleFactory = require(script.Parent:WaitForChild("ObstacleService"))
local TrainFactory = require(script.Parent:WaitForChild("TrainService"))
local Style = require(script.Parent:WaitForChild("VisualStyle"))
local World = {}
World.__index = World

function World.new(options)
	local self = setmetatable({runners = {}, origin = Vector3.new(options.OffsetX, 0, 0), kind = options.Kind}, World)
	local world = Instance.new("Folder", workspace)
	world.Name = options.Name
	self.folder = world
	local origin = self.origin
	local context = {Origin = origin, Parent = world, Seed = options.Seed, CoinMode = options.CoinMode, Distance = options.Distance}
	local Obstacles = ObstacleFactory.new(context)
	context.Obstacles = Obstacles
	local Coins = CoinFactory.new(context)
	local PowerUps = PowerUpFactory.new(context)
	local Trains = TrainFactory.new(context)
	Obstacles.setMovingEntries(Trains.entries)
	local activeMode = options.CoinMode or Config.DefaultMode
	local CHUNK_LENGTH = Config.Track.ChunkLength
	local HALF_WIDTH = (Config.Track.LaneCount * Config.Track.LaneWidth + 4) / 2
	local chunks = {}
	local runners = self.runners
	self.obstacles, self.coins, self.trains = Obstacles, Coins, Trains
	self.coinMode = activeMode
	self.powerUps = PowerUps

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
		local function detail(name, size, position, color, material)
			return Style.detail(model, name, size, CFrame.new(position + origin), color, material)
		end
		part(model, "TrackBed", Vector3.new(HALF_WIDTH * 2, 2, CHUNK_LENGTH), Vector3.new(0, -1, z), Color3.fromRGB(48, 56, 66), Enum.Material.Asphalt)
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
			if index % 2 == 0 then Style.streetTree(model, origin + Vector3.new(side * (HALF_WIDTH + 2.7), 0, z), index) end
			detail("PlatformEdge", Vector3.new(0.65, 0.04, CHUNK_LENGTH), Vector3.new(side * (HALF_WIDTH + 0.5), 0.53, z), Color3.fromRGB(239, 184, 70), Enum.Material.Concrete)
			for mark = -40, 40, 20 do
				detail("PlatformJoint", Vector3.new(4.8, 0.015, 0.08), Vector3.new(side * (HALF_WIDTH + 2.5), 0.515, z + mark), Color3.fromRGB(93, 103, 117))
			end
			for step = -40, 40, 20 do
				local height = random:NextInteger(18, 48)
				local colors = {Color3.fromRGB(143, 162, 203), Color3.fromRGB(211, 157, 147), Color3.fromRGB(125, 183, 177), Color3.fromRGB(221, 199, 150)}
				local color = colors[random:NextInteger(1, #colors)]
				part(model, "Building", Vector3.new(14, height, 18), Vector3.new(side * (HALF_WIDTH + 13), height / 2, z + step), color, Enum.Material.Brick)
				detail("RoofCornice", Vector3.new(14.5, 0.5, 18.5), Vector3.new(side * (HALF_WIDTH + 13), height + 0.15, z + step), Color3.fromRGB(63, 74, 88))
				detail("ShopAwning", Vector3.new(1.5, 0.3, 12), Vector3.new(side * (HALF_WIDTH + 5.4), 4.4, z + step), if index % 2 == 0 then Color3.fromRGB(39, 157, 164) else Color3.fromRGB(187, 99, 66))
				if step == 0 then
					Style.bubble(model, "RooftopPod", Vector3.new(6, 2.5, 6), CFrame.new(origin + Vector3.new(side * (HALF_WIDTH + 13), height + 1.5, z + step)), Color3.fromRGB(178, 139, 218))
					local shopBadge = detail("ShopDiamond", Vector3.new(0.2, 2, 2), Vector3.new(side * (HALF_WIDTH + 5.8), 3, z + step), Color3.fromRGB(255, 208, 75), Enum.Material.SmoothPlastic)
					shopBadge.CFrame *= CFrame.Angles(math.pi / 4, 0, 0)
				end
				for floor = 5, height - 2, 6 do
					for offset = -5, 5, 5 do
						local lit = random:NextNumber() > 0.55
						local window = part(model, "Window", Vector3.new(0.12, 2.8, 2.4), Vector3.new(side * (HALF_WIDTH + 5.95), floor, z + step + offset), if lit then Color3.fromRGB(247, 209, 147) else Color3.fromRGB(41, 62, 82), if lit then Enum.Material.Neon else Enum.Material.Glass)
						window.CanCollide = false
					end
				end
			end
			for step = -25, 25, 50 do
				part(model, "LampPost", Vector3.new(0.35, 10, 0.35), Vector3.new(side * (HALF_WIDTH + 0.5), 5, z + step), Color3.fromRGB(40, 50, 65), Enum.Material.Metal)
				part(model, "Lamp", Vector3.new(2, 0.3, 1), Vector3.new(side * HALF_WIDTH, 10, z + step), Color3.fromRGB(255, 236, 175), Enum.Material.Neon)
			end
		end
		-- Elevated station structures leave the full obstacle/roof clearance open.
		if index % 4 == 0 then
			for _, side in {-1, 1} do
				detail("StationColumn", Vector3.new(0.8, 26, 0.8), Vector3.new(side * (HALF_WIDTH + 3.8), 13, z), Color3.fromRGB(45, 66, 85))
			end
			detail("StationGantry", Vector3.new(HALF_WIDTH * 2 + 8.4, 1.1, 1.2), Vector3.new(0, 26, z), Color3.fromRGB(45, 66, 85))
			detail("StationLight", Vector3.new(HALF_WIDTH * 2, 0.12, 0.35), Vector3.new(0, 25.4, z), Color3.fromRGB(151, 234, 228), Enum.Material.Neon)
			local sign = detail("StationName", Vector3.new(15, 2, 0.25), Vector3.new(0, 24.2, z + 0.7), Color3.fromRGB(25, 49, 66))
			Style.label(sign, if index % 8 == 0 then "CENTRAL  •  01" else "DISTRITO  •  02")
		end
		model.Parent = world
		chunks[index] = model
		if not options.Distance or math.abs(z - (25 - options.Distance)) > 80 then
			Obstacles.addChunk(index, model)
		end
		Coins.addChunk(index, model)
		if not options.Distance or math.abs(z - (25 - options.Distance)) > 80 then PowerUps.addChunk(index, model) end
	end

	local function refreshWorld()
		local needed = {}
		for _, runner in runners do
			local root = runner.root
			local current = root and math.floor((-root.Position.Z + CHUNK_LENGTH / 2) / CHUNK_LENGTH) or 0
			local behind = math.ceil((Config.SpeedRoutes.MaxSteps * Config.SpeedRoutes.MaxSpacing + 60) / CHUNK_LENGTH) + 1
			for index = current - behind, current + 8 do needed[index] = true end
		end
		for index = -1, 2 do needed[index] = true end
		local ordered = {}
		for index in needed do table.insert(ordered, index) end
		table.sort(ordered)
		for _, index in ordered do
			if not chunks[index] then createChunk(index) end
		end
		for index, chunk in chunks do
			if not needed[index] then
				Coins.removeChunk(index)
				PowerUps.removeChunk(index)
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
	player:SetAttribute("HeldPowerUp", "")
	player:SetAttribute("DraftCharge", 0)
	player:SetAttribute("DraftUntil", 0)
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
	player:SetAttribute("BoostUntil", 0)
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
	player:SetAttribute("DraftCharge", 0)
	player:SetAttribute("DraftUntil", 0)
	player:SetAttribute("HeldPowerUp", "")
	self.obstacles.cancelRoute(player)
	player:SetAttribute("BoostUntil", 0)
	player:SetAttribute("RecoveringUntil", 0)
	if runner.recoil then
		runner.root.CFrame = runner.recoil.target
		runner.root.Anchored = runner.recoil.wasAnchored
		runner.recoil = nil
	end
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
	if runner.recoil then return end
	if action == "UsePowerUp" then self.powerUps.use(player, runner)
	elseif action == "Left" then runner.lane = Motion.changeLane(runner.lane, -1)
	elseif action == "Right" then runner.lane = Motion.changeLane(runner.lane, 1)
	elseif action == "CrouchStart" then
		runner.jumpUntil = nil
		Crouch.set(runner.crouch, true)
		if humanoid.FloorMaterial == Enum.Material.Air then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			local v = runner.root.AssemblyLinearVelocity
			runner.root.AssemblyLinearVelocity = Vector3.new(v.X, Motion.verticalVelocity(v.Y, true, true), v.Z)
		end
	elseif action == "CrouchEnd" then Crouch.set(runner.crouch, false)
	elseif action == "Jump" then
		Crouch.set(runner.crouch, false)
		runner.jumpUntil = workspace:GetServerTimeNow() + Config.Crouch.JumpBuffer
	end
end

function World:physics(dt)
	for player, runner in self.runners do
		if not runner.root.Parent or runner.humanoid.Health <= 0 then continue end
		local now = workspace:GetServerTimeNow()
		if runner.recoil then
			local recoil = runner.recoil
			local progress, bounce = CrashMotion.sample(now - recoil.started, Config.Crash.PauseDuration)
			runner.root.CFrame = recoil.start:Lerp(recoil.target, progress)
				+ Vector3.new(0, Config.Crash.RecoilHeight * bounce, 0)
			runner.root.CFrame *= CFrame.Angles(math.rad(Config.Crash.RecoilTiltDegrees) * bounce, 0, 0)
			if now >= runner.pauseUntil then
				runner.root.CFrame = recoil.target
				runner.root.Anchored = recoil.wasAnchored
				runner.root.AssemblyLinearVelocity, runner.root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
				if not recoil.wasAnchored then runner.root:SetNetworkOwner(nil) end
				runner.previousPosition, runner.previousBodyCFrames = runner.root.Position, {}
				runner.recoil = nil
			end
		end
		if now < (runner.pauseUntil or 0) then
			runner.velocity.PlaneVelocity = Vector2.zero
			runner.humanoid:Move(Vector3.zero, false)
			continue
		end
		if Motion.jumpReady(now, runner.jumpUntil, runner.humanoid.FloorMaterial ~= Enum.Material.Air) then
			runner.jumpUntil = nil
			if runner.rampEntry then
				self.obstacles.clearRamp(runner)
				runner.rampJumpUntil = now + 0.4
			end
			runner.humanoid.Jump = true
		elseif runner.jumpUntil and now > runner.jumpUntil then
			runner.jumpUntil = nil
		end
		local bonus = if now < (runner.boostUntil or 0) then runner.boostBonus or Config.SpeedRoutes.Bonus else 0
		local following = false
		if self.kind == "Race" and now >= (runner.draftCooldown or 0) and now >= (runner.protectedUntil or 0) then
			for otherPlayer, other in self.runners do
				if otherPlayer ~= player and other.root.Parent and other.humanoid.Health > 0 and now >= (other.protectedUntil or 0)
					and Drafting.inWake(runner.root.Position, other.root.Position, Config.Drafting) then following = true; break end
			end
		end
		runner.draftCharge = Drafting.charge(runner.draftCharge or 0, following, dt, Config.Drafting)
		if runner.draftCharge >= Config.Drafting.ChargeTime then
			runner.draftCharge, runner.draftUntil = 0, now + Config.Drafting.Duration
			runner.draftCooldown = runner.draftUntil + Config.Drafting.Cooldown
			player:SetAttribute("DraftUntil", runner.draftUntil)
		end
		player:SetAttribute("DraftCharge", runner.draftCharge / Config.Drafting.ChargeTime)
		if now < (runner.draftUntil or 0) then bonus = math.max(bonus, Config.Drafting.Bonus) end
		local speed = Motion.approachSpeed(runner.speed, runner.collectedCoins, self.coinMode, dt, bonus)
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
	runner.draftCharge, runner.draftUntil = 0, 0
	player:SetAttribute("DraftCharge", 0)
	player:SetAttribute("DraftUntil", 0)
	self.obstacles.cancelRoute(player, true)
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
	runner.jumpUntil = nil
	runner.boostUntil = nil
	player:SetAttribute("BoostUntil", 0)
	runner.velocity.PlaneVelocity = Vector2.zero
	local target = CFrame.new(self.origin + Vector3.new(lane * Motion.LaneWidth, clearance + 0.2, z))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	runner.previousPosition, runner.previousBodyCFrames = root.Position, {}
	local now = workspace:GetServerTimeNow()
	runner.recoil = {start = root.CFrame, target = target, started = now, wasAnchored = root.Anchored}
	root.Anchored = true
	runner.pauseUntil = now + Config.Crash.PauseDuration
	runner.protectedUntil = now + math.max(Config.Crash.PauseDuration, Config.Crash.ProtectionDuration)
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
			self.powerUps.collect(player, runner)
			local route = self.obstacles.collectBoost(player, runner)
			if route then
				runner.boostUntil = workspace:GetServerTimeNow() + route.duration
				runner.boostBonus = route.bonus
				player:SetAttribute("BoostUntil", runner.boostUntil)
				player:SetAttribute("BoostBonus", runner.boostBonus)
			end
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
