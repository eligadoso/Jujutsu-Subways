local Motion = {}

function Motion.advance(z, speed, dt)
	-- Player travel is -Z; trains travel +Z and never change lanes.
	return z + speed * dt
end

function Motion.relativeTravel(bodyTravel, trainTravel)
	return bodyTravel - trainTravel
end

function Motion.availableLanes(entries, track, minZ, maxZ)
	local lanes = {}
	local half = (track.LaneCount - 1) / 2
	for lane = -half, half do
		local clear = true
		for _, entry in entries do
			if entry.kind == "Barrier" then continue end
			local box = entry.box
			if box.maxZ >= minZ and box.minZ <= maxZ
				and lane >= entry.firstLane and lane < entry.firstLane + entry.width then
				clear = false
				break
			end
		end
		if clear then table.insert(lanes, lane) end
	end
	return lanes
end

function Motion.chooseLane(lanes, previous, roll)
	local candidates = {}
	for _, lane in lanes do
		if lane ~= previous or #lanes == 1 then table.insert(candidates, lane) end
	end
	if #candidates == 0 then return nil end
	return candidates[math.min(#candidates, math.floor(roll * #candidates) + 1)]
end

return Motion
