local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local settings = Config.MotionEffects
local Spring = require(game:GetService("ReplicatedStorage").Shared.MotionSpring)
local Effects = {}
Effects.__index = Effects

function Effects.new()
	return setmetatable({speed = 0, roll = 0, lift = 0, shake = 0, time = 0,
		verticalSpring = Spring.new(), lateralSpring = Spring.new(), pitchSpring = Spring.new(),
		pickupSpring = Spring.new()}, Effects)
end

function Effects:update(dt, velocity, grounded, crouching, recovery, now, coins)
	dt = math.clamp(dt, 0, 0.1)
	local intensity = if settings.Enabled then math.clamp(settings.Intensity, 0, 1) else 0
	local blend = 1 - math.exp(-9 * dt)
	local forward = math.max(0, -velocity.Z)
	local speedRatio = math.clamp((forward - Config.Speed.Base) / math.max(1, Config.Speed.Max - Config.Speed.Base), 0, 1)
	self.speed += (speedRatio - self.speed) * blend
	self.roll += (math.clamp(-velocity.X / 45, -1, 1) - self.roll) * blend
	self.lift += (math.clamp(velocity.Y / 55, -1, 1) * 0.28 - (if crouching then 0.45 else 0) - self.lift) * blend
	-- Only react to transitions observed on this subject, never initial spawn/streaming.
	local crashed = self.recovery ~= nil and recovery > self.recovery and recovery > now
	if crashed then
		self.shake = 1
		self.pitchSpring.velocity = math.rad(22)
	elseif grounded and self.grounded == false then
		local impact = math.clamp(math.abs(self.vertical or 0) / 45, 0, 1)
		self.verticalSpring.velocity -= impact * settings.LandingDip * 26
		self.pitchSpring.velocity -= math.rad(18) * impact
	elseif self.grounded == true and not grounded and velocity.Y > 8 then
		self.verticalSpring.velocity += settings.JumpLift * 18
		self.pitchSpring.velocity += math.rad(10)
	end
	if coins and self.coins and coins > self.coins and not crashed then
		self.pickupSpring.velocity = math.min(12, self.pickupSpring.velocity + 5)
	end
	self.coins = coins
	self.recovery, self.grounded, self.vertical = recovery, grounded, velocity.Y
	self.time += dt
	self.shake *= math.exp(-8 * dt)
	local shake = self.shake * settings.CrashShake
	local lateral = self.lateralSpring:step(math.clamp(-velocity.X / 45, -1, 1) * settings.LaneSway, 15, dt)
	local vertical = self.verticalSpring:step(0, 17, dt)
	local pitch = self.pitchSpring:step(if crouching then math.rad(-1.5) else 0, 15, dt)
	local pickup = self.pickupSpring:step(0, 14, dt)
	local offset = Vector3.new(lateral + math.sin(self.time * 71) * shake, self.lift + vertical + math.sin(self.time * 57) * shake, 0) * intensity
	local roll = math.rad(settings.MaxRollDegrees) * self.roll * intensity
	return CFrame.new(offset) * CFrame.Angles(pitch * intensity, 0, roll), settings.BaseFOV + (self.speed * settings.SpeedFOV + pickup) * intensity
end

return Effects
