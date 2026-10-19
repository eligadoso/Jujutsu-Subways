local Routes = {}

local function stream(seed)
    local state = math.floor(seed) % 2147483647
    if state <= 0 then state = 1 end
    return function(low, high)
        state = state * 16807 % 2147483647
        local unit = state / 2147483647
        if low then return low + math.floor(unit * (high - low + 1)) end
        return unit
    end
end

local function build(index, track, settings, random, minLane, maxLane)
    local lane = random(minLane, maxLane)
    local startZ = -index * track.ChunkLength + 38
    local route = {lane = lane, minLane = minLane, maxLane = maxLane,
        entryZ = startZ, used = {}, entered = {}, gates = {}, obstacles = {}}
    local steps = random(settings.MinSteps, settings.MaxSteps)
    local turns, previousKind = 0, nil
    local z = startZ
    for _ = 1, steps do
        local nextLane = math.clamp(lane + random(-1, 1), minLane, maxLane)
        local gap = random(settings.MinSpacing, settings.MaxSpacing)
        z -= gap
        if nextLane ~= lane then
            turns += 1
            table.insert(route.obstacles, {kind = "Truck", firstLane = lane, width = 1, z = z + 8, paint = random(1, 5)})
        end
        local kind = if random() < 0.5 then "Sign" else "LaneBarrier"
        if kind == previousKind and random() < 0.7 then kind = if kind == "Sign" then "LaneBarrier" else "Sign" end
        table.insert(route.obstacles, {kind = kind, firstLane = nextLane, width = 1, z = z + 8})
        table.insert(route.gates, {lane = nextLane, z = z})
        lane, previousKind = nextLane, kind
    end
    route.exitLane, route.padZ = lane, z - 22
    route.steps, route.turns, route.length = steps, turns, startZ - route.padZ
    route.bonus = math.min(settings.MaxBonus, settings.Bonus + steps * 2 + turns)
    route.duration = math.min(settings.MaxDuration, settings.Duration + steps * 0.6 + turns * 0.2)
    return route
end

function Routes.generateSet(index, track, settings, seed)
    if not settings.Enabled or index < settings.FirstChunk then return {} end
    local block = math.floor((index - settings.FirstChunk) / settings.EveryChunks)
    local random = stream(seed + block * 104729 + 719)
    local anchor = settings.FirstChunk + block * settings.EveryChunks + random(0, 1)
    if index ~= anchor then return {} end
    local half = (track.LaneCount - 1) / 2
    if random() < 0.55 then
        local contest = {}
        local first = build(index, track, settings, random, -half, -1)
        local second = build(index, track, settings, random, 1, half)
        first.contest, second.contest = contest, contest
        return {first, second}
    end
    local low, high = -half, half - 1
    if random() < 0.5 then low, high = -half + 1, half end
    return {build(index, track, settings, random, low, high)}
end

function Routes.generate(index, track, settings, seed)
    return Routes.generateSet(index, track, settings, seed)[1]
end

function Routes.reserved(index, track, settings, seed)
    if not settings.Enabled then return false end
    local lookback = math.ceil((settings.MaxSteps * settings.MaxSpacing + 60) / track.ChunkLength)
    local center = -index * track.ChunkLength
    for anchor = math.max(settings.FirstChunk, index - lookback), index + 1 do
        for _, route in Routes.generateSet(anchor, track, settings, seed) do
            if center + track.ChunkLength / 2 >= route.padZ - 24
                and center - track.ChunkLength / 2 <= route.entryZ + 24 then return true end
        end
    end
    return false
end

function Routes.reward(route, id)
    local extra = 0
    if route.contest and not route.contest.winner then route.contest.winner = id; extra = 2 end
    return {bonus = route.bonus + extra, duration = route.duration}
end

function Routes.collect(route, from, to, laneWidth, id)
	if route.used[id] then return false end
	local previous = route.entered[id]
	if Routes.crossed(route, from, to, laneWidth, route.entryZ) then route.entered[id] = 1 end
	local low = (route.minLane or route.lane) * laneWidth - laneWidth / 2 + 0.6
	local high = (route.maxLane or route.lane) * laneWidth + laneWidth / 2 - 0.6
	if to.X < low or to.X > high then route.entered[id] = nil end
	while route.entered[id] do
		local nextGate = route.entered[id]
		local gate = route.gates[nextGate]
		if gate and from.Z >= gate.z and to.Z <= gate.z and to.Z < from.Z then
			if Routes.crossed({lane = gate.lane}, from, to, laneWidth, gate.z) then route.entered[id] += 1
			else route.entered[id] = nil end
		else break end
	end
	if route.entered[id] == #route.gates + 1 and Routes.crossed(route, from, to, laneWidth) then
		route.used[id], route.entered[id] = true, nil
		return true, "Complete"
	end
	if route.entered[id] and to.Z < route.padZ then route.entered[id] = nil end
	if previous and not route.entered[id] then return false, "Failed" end
	if route.entered[id] and route.entered[id] ~= previous then return false, "Active" end
	return false, nil
end

function Routes.crossed(route, from, to, laneWidth, plane)
	local z = plane or route.padZ
	if to.Z >= from.Z or from.Z < z or to.Z > z then return false end
	local t = (z - from.Z) / (to.Z - from.Z)
	local x = from.X + (to.X - from.X) * t
	local y = from.Y + (to.Y - from.Y) * t
	local lane = if plane then route.lane else route.exitLane or route.lane
	return math.abs(x - lane * laneWidth) <= laneWidth / 2 - 0.6 and y >= 1 and y <= 14
end

return Routes
