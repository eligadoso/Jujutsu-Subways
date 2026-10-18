local Config = require("../src/shared/GameConfig")
local Layout = require("../src/shared/ObstacleLayout")
local types = {}
local populated = 0
local differentSeeds = 0
local roofGroups = 0
local coverage = {Truck = {}, Sign = {}, RampTruck = {}}
local routes = {}
local convoySizes = {}
local extraTruckRows, wideSignRows, duckJumpRows = 0, 0, 0
local alternate = table.clone(Config.Obstacles)
alternate.Seed += 827
for index = -2, 600 do
	local entries = Layout.generate(index, Config.Track, Config.Obstacles)
	local repeated = Layout.generate(index, Config.Track, Config.Obstacles)
	assert(#entries == #repeated)
	if #entries > 0 then populated += 1 end
	if entries[1] then
		local trucks, hasBarrier = 0, false
		for _, obstacle in entries do
			if obstacle.kind == "Truck" then trucks += 1 end
			if obstacle.kind == "Barrier" then hasBarrier = true end
			if obstacle.kind == "Sign" and obstacle.width >= 4 then wideSignRows += 1 end
		end
		if entries[1].kind == "Truck" and trucks > 1 then extraTruckRows += 1 end
		if entries[1].kind == "Sign" and hasBarrier then duckJumpRows += 1 end
	end
	local other = Layout.generate(index, Config.Track, alternate)
	if #entries ~= #other or (#entries > 0 and (entries[1].kind ~= other[1].kind or entries[1].z ~= other[1].z or entries[1].firstLane ~= other[1].firstLane)) then
		differentSeeds += 1
	end
	if index < 1 then assert(#entries == 0, "Spawn must be clear") end
	if entries[1] and entries[1].kind == "RampTruck" then
		local roofs = 1
		for n = 2, #entries do
			if entries[n].kind ~= "Truck" then continue end
			roofs += 1
			assert(entries[n].roofAccess)
			assert(entries[1].z == entries[n].z, "Adjacent roofs must align longitudinally")
			assert(math.abs(entries[1].firstLane - entries[n].firstLane) == 1, "Trucks must be adjacent for roof transfers")
		end
		convoySizes[roofs] = true
		if roofs > 1 then roofGroups += 1 end
	end
	for i, entry in entries do
		types[entry.kind] = true
		if coverage[entry.kind] then
			for lane = entry.firstLane, entry.firstLane + entry.width - 1 do coverage[entry.kind][lane] = true end
		end
		assert(entry.kind == repeated[i].kind and entry.firstLane == repeated[i].firstLane)
		assert(entry.firstLane >= -2 and entry.firstLane + entry.width - 1 <= 2)
		if entry.kind == "Truck" then
			assert(entry.width <= 3 and entry.width < Config.Track.LaneCount)
			local row = (index - Config.Obstacles.FirstChunk) / Config.Obstacles.RowEveryChunks
			local route = Layout.routeLane(row, Config.Track, Config.Obstacles)
			assert(route < entry.firstLane or route > entry.firstLane + entry.width - 1, "Dense truck rows must leave a route that changes across the run")
		end
		if entry.kind == "Barrier" then assert(entry.width == 5, "Jump barrier must span every lane") end
	end
end
for _, name in {"Truck", "Sign", "Barrier", "RampTruck"} do assert(types[name], "Missing " .. name) end
assert(populated > 480, "Obstacles must remain frequent")
assert(populated > 570, "Harder layout should populate almost every chunk")
assert(extraTruckRows > 40 and wideSignRows > 40 and duckJumpRows > 40, "Harder layouts must combine trucks, wide signs and duck-then-jump sequences")
assert(differentSeeds > 400, "Different runs must vary kinds, lanes and positions")
for name, lanes in coverage do
	for lane = -2, 2 do assert(lanes[lane], name .. " must be able to appear in every lane") end
end
for row = 0, 600 do
	local lane = Layout.routeLane(row, Config.Track, Config.Obstacles)
	routes[lane] = true
	assert(math.abs(lane) <= 2)
	if row > 0 then assert(math.abs(lane - Layout.routeLane(row - 1, Config.Track, Config.Obstacles)) <= 1) end
end
for lane = -2, 2 do assert(routes[lane], "No lane may be permanently reserved") end
assert(convoySizes[1] and convoySizes[2] and convoySizes[3], "Convoy sizes must vary")
assert(roofGroups > 20, "Generate enough connected roof groups")
assert(Config.Obstacles.TruckHeight > 50 * 50 / (2 * 196.2) + 0.5, "A ground jump must not bypass a high truck")
local jumpTime = 2 * 50 / 196.2
local minimumBarrierGap = Config.Track.ChunkLength - Config.Obstacles.PositionJitter * 2 - Config.Obstacles.SignJumpOffset
assert(minimumBarrierGap / 70 > jumpTime, "Adjacent barriers must allow landing before another jump")

local function point(x, y, z) return {X = x, Y = y, Z = z} end
local sign = {minX = -2.65, maxX = 2.65, minY = 3, maxY = 6.5, minZ = -0.6, maxZ = 0.6}
assert(Layout.hit(sign, point(0, 0, 4), point(0, 0, -4), 5.5, 0.65), "Standing must hit a sign")
assert(not Layout.hit(sign, point(0, 0, 4), point(0, 0, -4), 2.4, 0.65), "Crouching must clear a sign")
assert(Layout.hit(sign, point(0, 2, 4), point(0, 2, -4), 2.4, 0.65), "Airborne crouch does not bypass a sign")
assert(not Layout.hit(sign, point(6, 0, 4), point(6, 0, -4), 5.5, 0.65), "Adjacent lanes must be clear")
local barrier = {minX = -17, maxX = 17, minY = 0, maxY = Config.Obstacles.BarrierHeight, minZ = -0.325, maxZ = 0.325}
for _, x in {-12, -6, 0, 6, 12} do
	assert(Layout.hit(barrier, point(x, 0, 10), point(x, 0, -10), 5.5, 0.65), "Grounded player must hit barrier")
	assert(not Layout.hit(barrier, point(x, 3, 10), point(x, 3, -10), 5.5, 0.65), "A sufficiently high jump must clear barrier")
	assert(not Layout.hit(barrier, point(x, 6.1, 10), point(x, 6.1, -10), 5.5, 0.65), "Truck roof must clear barrier")
end
local truck = {minX = -2.65, maxX = 2.65, minY = 0.8, maxY = Config.Obstacles.TruckHeight, minZ = -14, maxZ = 14}
assert(Layout.hit(truck, point(0, 0, 24), point(0, 0, -24), 5.5, 0.65), "Swept hits must detect a truck even at low FPS")
assert(Layout.hit(truck, point(0, 14.4, 24), point(0, 14.4, -24), 5.5, 0.65), "A jump from the ramp cannot bypass a high truck")
assert(not Layout.hit(truck, point(0, 16.1, 24), point(0, 16.1, -24), 5.5, 0.65), "Every truck roof must allow movement at the common height")

local hit = {kind = "Truck", box = truck}
local blocking = {box = {minX = -2.65, maxX = 2.65, minY = 0, maxY = 16.5, minZ = 70, maxZ = 100}}
local lane, z = Layout.recovery({hit, blocking}, hit, point(0, 0, 24), Config.Track, Config.Crash)
assert(lane ~= 0 and z >= 79, "Recovery must retreat and select a free lane")
assert(not Layout.hit(blocking.box, point(lane * 6, 0, z), point(lane * 6, 0, z), 5.5, 0.65))
local across = {box = {minX = -17, maxX = 17, minY = 0, maxY = 16.5, minZ = 70, maxZ = 100}}
lane, z = Layout.recovery({hit, across}, hit, point(0, 0, 24), Config.Track, Config.Crash)
assert(z > 105, "Recovery must retreat further when all lanes are occupied")
assert(not Layout.hit(across.box, point(lane * 6, 0, z), point(lane * 6, 0, z), 5.5, 0.65))
print("ObstacleLayout: random generation, safe routes, aligned adjacent roof groups, height clearance and recovery passed")
