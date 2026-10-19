local Motion = {}
local Config = require(if script then script.Parent.GameConfig else "./GameConfig")

Motion.ForwardSpeed = Config.Speed.Base
Motion.LaneWidth = Config.Track.LaneWidth
Motion.MinLane = -(Config.Track.LaneCount - 1) / 2
Motion.MaxLane = (Config.Track.LaneCount - 1) / 2
Motion.LateralSpeed = Motion.LaneWidth / Config.LaneChange.BaseDuration

function Motion.changeLane(lane, direction)
	return math.clamp(lane + direction, Motion.MinLane, Motion.MaxLane)
end

function Motion.speedForCoins(count, modeName)
	local mode = Config.CoinModes[modeName or Config.DefaultMode]
	local settings = (mode and mode.Speed) or Config.Speed
	return math.min(settings.Max, settings.Base + math.max(0, count) * settings.PerCoin)
end

function Motion.laneDurationForCoins(count, modeName)
	local mode = Config.CoinModes[modeName or Config.DefaultMode]
	local settings = (mode and mode.LaneChange) or Config.LaneChange
	return math.min(settings.MaxDuration, settings.BaseDuration + math.max(0, count) * settings.SecondsPerCoin)
end

function Motion.approachSpeed(current, count, modeName, dt, bonus)
	local mode = Config.CoinModes[modeName or Config.DefaultMode]
	local settings = (mode and mode.Speed) or Config.Speed
	local target = Motion.speedForCoins(count, modeName) + (bonus or 0)
	local acceleration = if bonus and bonus > 0 then Config.SpeedRoutes.Acceleration else settings.Acceleration or Config.Speed.Acceleration
	local step = acceleration * math.max(dt, 0)
	return current + math.clamp(target - current, -step, step)
end

function Motion.jumpReady(now, deadline, grounded)
	return deadline ~= nil and now <= deadline and grounded
end

function Motion.velocity(lane, x, dt, speed, laneDuration)
	local offset = lane * Motion.LaneWidth - x
	local lateralSpeed = if laneDuration then Motion.LaneWidth / math.max(laneDuration, 0.001) else Motion.LateralSpeed
	local lateral = math.clamp(offset / math.max(dt, 0.001), -lateralSpeed, lateralSpeed)
	return lateral, -(speed or Motion.ForwardSpeed)
end

function Motion.verticalVelocity(y, crouching, airborne)
	if crouching and airborne then
		return math.min(y, -Config.Crouch.FastFallSpeed)
	end
	return y
end

return Motion
