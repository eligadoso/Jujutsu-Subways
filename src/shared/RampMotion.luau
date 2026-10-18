local Motion = {}

function Motion.verticalSpeed(current, forwardSpeed, heightError, slope, dt, gravity)
	local target = forwardSpeed * slope + math.clamp(heightError * 6, -8, 8)
	-- Change velocity smoothly; physical surfaces support the rider without repositioning them.
	return current + (target - current) * (1 - math.exp(-24 * dt)) + gravity * dt
end

return Motion
