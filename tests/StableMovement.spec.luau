local Motion = require("../src/shared/RunnerMotion")
for _, fps in {15, 30, 60, 144, 240} do
	for _, speed in {26, 42, 72, 144} do
		for _, duration in {0.2, 0.6} do
			local x, previous = 0, 6
			for frame = 1, fps * 4 do
				local dt = (if frame % 2 == 0 then 1.3 else 0.7) / fps
				local vx, vz = Motion.stableVelocity(1, x, dt, speed, duration)
				x += vx * dt
				assert(x <= 6.000001 and math.abs(6-x) <= previous + 0.000001, "High speed must not produce overshoot or zigzag")
				assert(vz == -speed)
				previous = math.abs(6-x)
			end
			assert(math.abs(6-x) < 0.0151)
			for _ = 1, fps * 3 do
				local vx = Motion.stableVelocity(-2, x, 1/fps, speed, duration)
				x += vx / fps
				assert(x >= -12.00001, "Direction changes must not cross the target lane")
			end
			assert(math.abs(x+12) < 0.0151)
		end
	end
end
assert(Motion.stableVelocity(0, 0.01, 1/60, 144, 0.2) == 0, "Tiny drift must not trigger alternating corrections")
for _, fps in {15, 30, 60, 144} do
	local normalX, boostedX = 0, 0
	for frame = 1, fps * 5 do
		local lane = if frame < fps * 2 then 1 else -1
		local factor = 1 + math.clamp((frame / fps - 0.5) * 3, 0, 1)
		local normal = Motion.stableVelocity(lane, normalX, 1/fps, 42, 0.2)
		local boosted = Motion.stableVelocity(lane, boostedX, 1/fps, 42 * factor, 0.2)
		normalX += normal / fps
		boostedX += boosted / fps
		assert(math.abs(normalX - boostedX) < 1e-10, "Shoes acceleration must not alter the planned lateral trajectory")
	end
end
print("StableMovement: high-speed lateral control, jittering dt, target settling and reversals passed")
