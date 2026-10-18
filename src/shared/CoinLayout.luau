local Layout = {}

-- Pure generation: the same chunk and mode always produce the same layout.
function Layout.generate(index, track, settings)
	local result = {}
	if not settings.Enabled then return result end
	assert(settings.Spacing > 0 and settings.CoinsPerLine >= 1, "Invalid coin spacing/count")
	assert(settings.LinesPerChunk >= 0 and settings.Value > 0, "Invalid coin lines/value")
	assert(settings.SpawnChance >= 0 and settings.SpawnChance <= 1, "Invalid coin probability")
	assert(settings.PickupRadius > 0, "Invalid pickup radius")
	local halfLanes = (track.LaneCount - 1) / 2
	local lanes = {}
	for _, lane in settings.AllowedLanes do
		if lane % 1 == 0 and math.abs(lane) <= halfLanes and not table.find(lanes, lane) then
			table.insert(lanes, lane)
		end
	end
	local state = (index * 7919 + settings.Seed) % 2147483647
	if state == 0 then state = 1 end
	local function random()
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
	local margin = 5
	local maxCount = math.min(settings.CoinsPerLine, math.floor((track.ChunkLength - margin * 2) / settings.Spacing) + 1)
	for _ = 1, math.min(settings.LinesPerChunk, #lanes) do
		local lane = table.remove(lanes, math.floor(random() * #lanes) + 1)
		if random() > settings.SpawnChance then continue end
		local minCount = math.clamp(settings.MinCoinsPerLine or maxCount, 1, maxCount)
		local count = minCount + math.floor(random() * (maxCount - minCount + 1))
		local span = (count - 1) * settings.Spacing
		local start = -track.ChunkLength / 2 + margin + random() * (track.ChunkLength - margin * 2 - span)
		for n = 0, count - 1 do
			table.insert(result, {
				x = lane * track.LaneWidth,
				y = settings.Height,
				z = -index * track.ChunkLength + start + n * settings.Spacing,
				value = settings.Value,
				radius = settings.PickupRadius,
			})
		end
	end
	return result
end

return Layout
