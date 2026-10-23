local Rules = {}
function Rules.controlledSpeed(current, target, dt, limit, acceleration, braking)
	target = math.clamp(target, 0, limit)
	local step = (if target > current then acceleration else braking) * math.max(dt, 0)
	return current + math.clamp(target-current, -step, step)
end
function Rules.shoeMultiplier(current, active, dt)
	local target = if active then 2 else 1
	local step = 3 * math.max(0, dt)
	return math.clamp(current + math.clamp(target-current, -step, step), 1, 2)
end
function Rules.coinLoss(coins, fraction)
	return math.min(coins, math.max(0, math.ceil(coins * fraction)))
end
function Rules.speed(base, now, stun, slow, shoes, multiplier)
	if now < (stun or 0) then return 0 end
	return base * (if now < (shoes or 0) then 2 else 1) * (if now < (slow or 0) then multiplier else 1)
end
function Rules.hits(a, b, from, to, radius)
	-- Relative sweep accounts for both the projectile and the runner moving.
	local x, y, z = a.X - from.X, a.Y - from.Y, a.Z - from.Z
	local dx, dy, dz = b.X - to.X - x, b.Y - to.Y - y, b.Z - to.Z - z
	local length = dx * dx + dy * dy + dz * dz
	local t = if length > 0 then math.clamp(-(x * dx + y * dy + z * dz) / length, 0, 1) else 0
	return (x + dx * t)^2 + (y + dy * t)^2 + (z + dz * t)^2 <= radius * radius
end
return Rules
