local Routes = require("../src/shared/SpeedRoutes")
local Config = require("../src/shared/GameConfig")
local Motion = require("../src/shared/RunnerMotion")
local settings, track = Config.SpeedRoutes, Config.Track
local lanes = {}
local variants = {}
for index = -2, 600 do
	local route = Routes.generate(index, track, settings, 473)
	if route then
		lanes[route.lane] = true
		assert(route.lane >= -2 and route.lane <= 2)
		variants[route.variant] = true
		assert(route.variant >= 1 and route.variant <= 3)
		assert(route.obstacles[1].firstLane == route.lane and route.obstacles[2].width == 1, "Other lanes must remain available")
		assert(route.entryZ > route.obstacles[1].z and route.obstacles[1].z > route.obstacles[2].z and route.obstacles[2].z > route.padZ)
		assert(Routes.generate(index, track, settings, 473).lane == route.lane)
	else assert(index < settings.FirstChunk or (index - settings.FirstChunk) % settings.EveryChunks ~= 0) end
end
local count = 0
for _ in lanes do count += 1 end
assert(count == 5, "Risk routes must vary across lanes")
assert(variants[1] and variants[2] and variants[3], "All three challenge patterns must appear")
local route = Routes.generate(3, track, settings, 473)
local function point(z, lane, height) return {X = (lane or route.lane) * track.LaneWidth, Y = height or 4, Z = z} end
assert(not Routes.collect(route, point(route.padZ + 2), point(route.padZ - 2), 6, 1), "Exit alone must not reward a bypass")
assert(not Routes.collect(route, point(route.entryZ + 2), point(route.entryZ - 2), 6, 1))
for _, gate in route.gates do Routes.collect(route, point(gate.z + 2, gate.lane), point(gate.z - 2, gate.lane), 6, 1) end
assert(Routes.collect(route, point(route.padZ + 2), point(route.padZ - 2, nil, 9), 6, 1), "A successful final jump must receive the boost")
assert(not Routes.collect(route, point(route.entryZ + 2), point(route.padZ - 2), 6, 1), "A route must reward each runner once")
Routes.collect(route, point(route.entryZ + 2), point(route.entryZ - 2), 6, 2)
Routes.collect(route, point(route.entryZ - 2), point(route.entryZ - 4, route.lane + 1), 6, 2)
assert(not Routes.collect(route, point(route.padZ + 2), point(route.padZ - 2), 6, 2), "Leaving the risk lane must cancel eligibility")
assert(not Routes.crossed(route, point(route.padZ - 2), point(route.padZ + 2), 6), "Recovery backwards must not activate a pad")
local _, enteredState = Routes.collect(route, point(route.entryZ + 2), point(route.entryZ - 2), 6, 10)
assert(enteredState == "Active", "Entry must signal yellow feedback")
local _, failedState = Routes.collect(route, point(route.entryZ - 2), point(route.entryZ - 4, route.lane + 1), 6, 10)
assert(failedState == "Failed", "Leaving an active route must signal red feedback")
local _, idleState = Routes.collect(route, point(route.entryZ - 4, route.lane + 1), point(route.entryZ - 6, route.lane + 1), 6, 10)
assert(idleState == nil, "Failure feedback must only fire on transitions")
for row = 0, 8 do
	local challenge = Routes.generate(settings.FirstChunk + row * settings.EveryChunks, track, settings, 473)
	local function p(z, lane) return {X = lane * 6, Y = 4, Z = z} end
	Routes.collect(challenge, p(challenge.entryZ + 1, challenge.lane), p(challenge.entryZ - 1, challenge.lane), 6, 3)
	assert(not Routes.collect(challenge, p(challenge.padZ + 1, challenge.lane), p(challenge.padZ - 1, challenge.lane), 6, 3), "Skipping checkpoints must not reward a shortcut")
	Routes.collect(challenge, p(challenge.entryZ + 1, challenge.lane), p(challenge.entryZ - 1, challenge.lane), 6, 4)
	for _, gate in challenge.gates do
		assert(not Routes.collect(challenge, p(gate.z + 1, gate.lane), p(gate.z - 1, gate.lane), 6, 4))
	end
	local awarded, completeState = Routes.collect(challenge, p(challenge.padZ + 1, challenge.lane), p(challenge.padZ - 1, challenge.lane), 6, 4)
	assert(awarded and completeState == "Complete", "Each pattern must reward and signal a complete run")
	if challenge.variant == 3 then
		assert(challenge.bonus == settings.Bonus + 2 and challenge.duration > settings.Duration)
		assert(challenge.entryZ - challenge.gates[1].z >= 36, "First lane change must have enough approach space")
		assert(challenge.gates[2].z - challenge.padZ >= 32, "Return lane change must remain achievable")
	end
end
for _, fps in {15, 30, 60, 144} do
	local speed = 42
	for _ = 1, fps do speed = Motion.approachSpeed(speed, 80, "Classic", 1 / fps, settings.Bonus) end
	assert(math.abs(speed - 52) < 0.00001, "Bonus must be capped and independent of frame rate")
	for _ = 1, fps * 2 do speed = Motion.approachSpeed(speed, 80, "Classic", 1 / fps, 0) end
	assert(math.abs(speed - 42) < 0.00001, "Boost expiration must ease back to coin speed")
end
print("SpeedRoutes: optional lanes, risk sequence, completion rewards, replay prevention and smooth boosts passed")
