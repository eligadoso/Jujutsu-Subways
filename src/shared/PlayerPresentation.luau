local Presentation = {}
function Presentation.team(state)
	return if state == "Race" or state == "Solo" then "Jugando" else "AFK"
end
function Presentation.canSpectate(state, afk, matchState)
	return state == "Finished" or (state == "Lobby" and (afk == true or matchState == "Race"))
end
function Presentation.isTarget(state, alive)
	return alive and (state == "Race" or state == "Solo")
end
function Presentation.nextSpectatorIndex(current, count, direction)
	if count == 0 then return nil end
	if current == 0 then return if direction < 0 then count else 1 end
	return (current - 1 + direction) % count + 1
end
function Presentation.sort(records)
	table.sort(records, function(a, b)
		if a.team ~= b.team then return a.team == "Jugando" end
		if a.team == "Jugando" then
			if (a.state == "Race") ~= (b.state == "Race") then return a.state == "Race" end
			if a.state == "Race" and a.place ~= b.place then return a.place < b.place end
			if a.studs ~= b.studs then return a.studs > b.studs end
		elseif a.name ~= b.name then return a.name < b.name end
		return a.id < b.id
	end)
	return records
end
return Presentation
