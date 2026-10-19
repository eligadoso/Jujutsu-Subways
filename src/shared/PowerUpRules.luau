local Rules = {}
function Rules.canCollect(used, id, held)
	return held == nil and not used[id]
end
function Rules.spawns(index, settings)
	return settings.Enabled and index >= settings.FirstChunk and (index - settings.FirstChunk) % settings.EveryChunks == 0
end
function Rules.choose(catalog, roll)
	if #catalog == 0 then return nil end
	return catalog[math.clamp(math.floor(roll * #catalog) + 1, 1, #catalog)]
end
function Rules.canUse(state, alive, held)
	return (state == "Race" or state == "Solo") and alive and held ~= nil
end
return Rules
