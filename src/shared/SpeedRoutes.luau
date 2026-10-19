local Routes = {}

function Routes.generate(index, track, settings, seed)
	if not settings.Enabled or index < settings.FirstChunk or (index - settings.FirstChunk) % settings.EveryChunks ~= 0 then return nil end
	local half = (track.LaneCount - 1) / 2
	local row = (index - settings.FirstChunk) / settings.EveryChunks
	local lane = (math.floor(seed) + row * 3) % track.LaneCount - half
	local z = -index * track.ChunkLength
	local variant = (row + math.floor(seed / track.LaneCount)) % 3 + 1
	local route = {lane = lane, entryZ = z + 44, padZ = z - 42, used = {}, entered = {},
		variant = variant, bonus = settings.Bonus, duration = settings.Duration, gates = {}, obstacles = {}}
	local function obstacle(kind, targetLane, position)
		table.insert(route.obstacles, {kind = kind, firstLane = targetLane, width = 1, z = position})
	end
	if variant == 3 then
		local neighbor = lane + (if lane == half then -1 else 1)
		route.neighbor, route.bonus, route.duration = neighbor, settings.Bonus + 2, settings.Duration + 0.5
		route.entryZ = z + 62
		obstacle("Truck", lane, z + 10)
		obstacle("Sign", neighbor, z + 2)
		table.insert(route.gates, {lane = neighbor, z = z + 26})
		table.insert(route.gates, {lane = neighbor, z = z - 10})
	else
		obstacle(if variant == 1 then "Sign" else "LaneBarrier", lane, z + 8)
		obstacle(if variant == 1 then "LaneBarrier" else "Sign", lane, z - 28)
		table.insert(route.gates, {lane = lane, z = z})
	end
	return route
end

function Routes.collect(route, from, to, laneWidth, id)
	if route.used[id] then return false end
	local previous = route.entered[id]
	if Routes.crossed(route, from, to, laneWidth, route.entryZ) then route.entered[id] = 1 end
	local low = math.min(route.lane, route.neighbor or route.lane) * laneWidth - laneWidth / 2 + 0.6
	local high = math.max(route.lane, route.neighbor or route.lane) * laneWidth + laneWidth / 2 - 0.6
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
	return math.abs(x - route.lane * laneWidth) <= laneWidth / 2 - 0.6 and y >= 1 and y <= 14
end

return Routes
