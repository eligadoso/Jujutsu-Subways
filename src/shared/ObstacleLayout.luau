local Layout = {}

local function stream(seed)
	local mixed = bit32.bxor(seed % 4294967296, 0x9E3779B9)
	mixed = bit32.bxor(mixed, bit32.rshift(mixed, 16))
	mixed = (mixed * 1664525 + 1013904223) % 4294967296
	mixed = bit32.bxor(mixed, bit32.rshift(mixed, 13))
	local state = mixed % 2147483647
	if state == 0 then state = 1 end
	for _ = 1, 6 do state = state * 16807 % 2147483647 end
	return function(n)
		state = state * 16807 % 2147483647
		return math.floor(state / 2147483647 * n)
	end
end

-- A changing escape route, rather than a permanently reserved lane.
function Layout.routeLane(row, track, settings)
	local half = (track.LaneCount - 1) / 2
	local block = math.floor(row / 4)
	local a = stream(settings.Seed + block * 104729)(track.LaneCount) - half
	local b = stream(settings.Seed + (block + 1) * 104729)(track.LaneCount) - half
	return math.round(a + (b - a) * (row % 4) / 4)
end

local function chooseKind(row, settings)
	local random = stream(settings.Seed + row * 7919 + 931)
	local roll = random(100)
	if roll < 32 then return "Truck"
	elseif roll < 60 then return "Sign"
	elseif roll < 76 then return "Barrier"
	else return "RampTruck" end
end

function Layout.generate(index, track, settings)
	if not settings.Enabled or index < settings.FirstChunk then return {} end
	local offset = index - settings.FirstChunk
	if offset % settings.RowEveryChunks ~= 0 then return {} end
	local row = offset / settings.RowEveryChunks
	local half = (track.LaneCount - 1) / 2
	local random = stream(row * 7919 + settings.Seed)
	if random(10000) / 10000 >= settings.SpawnChance then return {} end
	local kind = chooseKind(row, settings)
	-- Break most immediate repeats without imposing a repeating bag/order.
	if row > 0 and kind == chooseKind(row - 1, settings) and random(100) < 80 then
		local alternatives = {}
		for _, name in {"Truck", "Sign", "Barrier", "RampTruck"} do
			if name ~= kind then table.insert(alternatives, name) end
		end
		kind = alternatives[random(#alternatives) + 1]
	end
	local jitter = math.min(settings.PositionJitter, if kind == "RampTruck" then 6 else 24)
	local z = -index * track.ChunkLength + random(jitter * 2 + 1) - jitter
	local route = Layout.routeLane(row, track, settings)
	local result = {}
	local function add(name, lane, width, position, roofAccess)
		local item = {kind = name, firstLane = lane, width = width, z = position, roofAccess = roofAccess, paint = random(5) + 1}
		table.insert(result, item)
		return item
	end
	if kind == "Barrier" then
		add(kind, -half, track.LaneCount, z)
	elseif kind == "Sign" then
		local width = if random(10000) < settings.WideSignChance * 10000 then track.LaneCount - random(2) else 2 + random(2)
		width = math.min(width, track.LaneCount)
		add(kind, -half + random(track.LaneCount - width + 1), width, z)
		if random(10000) < settings.SignJumpChance * 10000 then
			add("Barrier", -half, track.LaneCount, z - settings.SignJumpOffset)
		end
	elseif kind == "Truck" then
		local options = {}
		for width = 1, math.min(3, settings.MaxTruckWidth, track.LaneCount - 1) do
			for lane = -half, half - width + 1 do
				if route < lane or route > lane + width - 1 then
					for _ = 1, width do table.insert(options, {lane, width}) end
				end
			end
		end
		local option = options[random(#options) + 1]
		add(kind, option[1], option[2], z)
		local extraCandidates = {}
		for lane = -half, half do
			if lane ~= route and (lane < option[1] or lane >= option[1] + option[2]) then table.insert(extraCandidates, lane) end
		end
		local extraLane
		if #extraCandidates > 0 and random(10000) < settings.ExtraTruckChance * 10000 then
			extraLane = extraCandidates[random(#extraCandidates) + 1]
			add("Truck", extraLane, 1, z)
		end
		local free = {}
		for lane = -half, half do
			if lane ~= extraLane and (lane < option[1] or lane >= option[1] + option[2]) then table.insert(free, lane) end
		end
		if random(10000) < settings.TruckSignChance * 10000 then
			local signLane = if random(100) < 80 then route else free[random(#free) + 1]
			add("Sign", signLane, 1, z + random(9) - 4)
		end
	else
		local lane = -half + random(track.LaneCount)
		add("RampTruck", lane, 1, z, true)
		local neighbors = {}
		for _, direction in {-1, 1} do
			local neighbor = lane + direction
			if neighbor >= -half and neighbor <= half and neighbor ~= route then table.insert(neighbors, neighbor) end
		end
		if #neighbors > 0 then
			add("Truck", neighbors[random(#neighbors) + 1], 1, z, true)
			-- Some convoys have a third roof, others stop at two.
			if #neighbors == 2 and random(100) < 35 then
				local other = neighbors[1]
				if other == result[2].firstLane then other = neighbors[2] end
				add("Truck", other, 1, z, true)
			end
		end
		if random(10000) < settings.RampBarrierChance * 10000 then add("Barrier", -half, track.LaneCount, z - 8) end
	end
	return result
end

function Layout.rampSurface(entry, x, z, track, settings)
	if entry.kind ~= "RampTruck" then return nil end
	local centerX = entry.firstLane * track.LaneWidth
	if math.abs(x - centerX) > (track.LaneWidth - 0.7) / 2 then return nil end
	local finish = entry.z + settings.TruckLength / 2
	local start = finish + settings.RampLength
	if z > start + 0.5 or z < finish - 2 then return nil end
	return math.clamp((start - z) / settings.RampLength, 0, 1) * settings.TruckHeight
end

function Layout.recovery(entries, hit, position, track, crash)
	local z = math.max(position.Z + crash.BacktrackDistance, (hit.rampStart or hit.box.maxZ) + crash.BacktrackDistance)
	local half = (track.LaneCount - 1) / 2
	local preferred = math.clamp(math.round(position.X / track.LaneWidth), -half, half)
	for _ = 1, 100 do
		local bestLane, bestDistance
		for lane = -half, half do
			local x = lane * track.LaneWidth
			local clear = true
			for _, entry in entries do
				local box = entry.box
				if x >= box.minX - 1 and x <= box.maxX + 1 and z >= box.minZ - 5 and z <= (entry.rampStart or box.maxZ) + 5 then
					clear = false
					break
				end
			end
			local distance = math.abs(lane - preferred)
			if clear and (not bestDistance or distance < bestDistance) then bestLane, bestDistance = lane, distance end
		end
		if bestLane then return bestLane, z end
		z += 12
	end
	return 0, 25
end

function Layout.hit(box, from, to, avatarHeight, radius)
	local enter, leave = 0, 1
	local function axis(a, b, low, high)
		local delta = b - a
		if math.abs(delta) < 0.000001 then return a >= low and a <= high end
		local t1, t2 = (low - a) / delta, (high - a) / delta
		if t1 > t2 then t1, t2 = t2, t1 end
		enter, leave = math.max(enter, t1), math.min(leave, t2)
		return enter <= leave
	end
	return axis(from.X, to.X, box.minX - radius, box.maxX + radius)
		and axis(from.Y, to.Y, box.minY - avatarHeight + 0.1, box.maxY - 0.1)
		and axis(from.Z, to.Z, box.minZ - radius, box.maxZ + radius)
end

return Layout
