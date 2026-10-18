local Motion = require("../src/shared/RunnerMotion")

local function close(actual, expected)
	assert(math.abs(actual - expected) < 0.00001, string.format("Expected %f, got %f", expected, actual))
end

for _, fps in {30, 60, 144} do
	local dt = 1 / fps
	local lane, x, z = 0, 0, 0
	-- No input is required for continuous forward progress.
	for _ = 1, fps * 2 do
		local vx, vz = Motion.velocity(lane, x, dt)
		x += vx * dt
		z += vz * dt
	end
	close(x, 0)
	close(z, -52)
	-- One press, then no further input: finish at the next lane.
	lane = Motion.changeLane(lane, 1)
	for _ = 1, fps do
		local vx, vz = Motion.velocity(lane, x, dt)
		x += vx * dt
		z += vz * dt
	end
	close(x, 6)
	close(z, -78)
	assert(Motion.changeLane(lane, 1) == 2, "The fourth lane must lead to the fifth lane")
	assert(Motion.changeLane(2, 1) == 2, "Right edge must stay within the track")
	-- Two separate presses can cross from right to left without holding a key.
	lane = Motion.changeLane(Motion.changeLane(lane, -1), -1)
	for _ = 1, fps do
		local vx, vz = Motion.velocity(lane, x, dt)
		x += vx * dt
		z += vz * dt
	end
	close(x, -6)
	close(z, -104)
	assert(Motion.changeLane(lane, -1) == -2, "The second lane must lead to the first lane")
	assert(Motion.changeLane(-2, -1) == -2, "Left edge must stay within the track")
	for _, outerLane in {-2, 2} do
		local outerX = 0
		for _ = 1, fps do
			local vx, vz = Motion.velocity(outerLane, outerX, dt)
			outerX += vx * dt
			close(vz, -26)
		end
		close(outerX, outerLane * 6)
	end
end

-- More pickups require earlier lane changes while forward progress is preserved.
close(Motion.laneDurationForCoins(0), 0.2)
close(Motion.laneDurationForCoins(20), 0.3)
close(Motion.laneDurationForCoins(80), 0.6)
close(Motion.laneDurationForCoins(1000), 0.6)
close(Motion.laneDurationForCoins(-10), 0.2)
close(Motion.laneDurationForCoins(1000, "NoCoins"), 0.2)
for _, fps in {30, 60, 144} do
	local durations = {}
	for _, count in {0, 20, 80, 1000} do
		local x, steps = 0, 0
		local duration = Motion.laneDurationForCoins(count)
		local forward = Motion.speedForCoins(count)
		while math.abs(x - 6) > 0.00001 and steps < fps * 2 do
			local vx, vz = Motion.velocity(1, x, 1 / fps, forward, duration)
			x += vx / fps
			steps += 1
			assert(x <= 6.00001, "Lane transition must not overshoot")
			close(vz, -forward)
		end
		close(x, 6)
		assert(math.abs(steps / fps - duration) <= 1 / fps + 0.00001)
		table.insert(durations, steps)
	end
	assert(durations[1] < durations[2] and durations[2] < durations[3])
	assert(durations[3] == durations[4], "Difficulty must stop increasing at the cap")
end

close(Motion.speedForCoins(0, "Classic"), 26)
close(Motion.speedForCoins(1, "Classic"), 26.5)
close(Motion.speedForCoins(20, "Classic"), 36)
close(Motion.speedForCoins(1000, "Classic"), 60)
close(Motion.speedForCoins(1000, "CoinRush"), 70)
close(Motion.speedForCoins(1000, "NoCoins"), 26)
close(Motion.speedForCoins(-10, "Classic"), 26)
for _, lane in {-2, 0, 2} do
	local _, z = Motion.velocity(lane, 0, 1 / 60, Motion.speedForCoins(20, "Classic"))
	close(z, -36)
end
close(Motion.verticalVelocity(50, true, true), -65)
close(Motion.verticalVelocity(0, true, true), -65)
close(Motion.verticalVelocity(-20, true, true), -65)
close(Motion.verticalVelocity(-90, true, true), -90)
close(Motion.verticalVelocity(50, false, true), 50)
close(Motion.verticalVelocity(0, true, false), 0)
close(Motion.verticalVelocity(-65, false, true), -65)
print("RunnerMotion: movement, jump cancellation, speed progression and capped lane difficulty at 30/60/144 FPS passed")
