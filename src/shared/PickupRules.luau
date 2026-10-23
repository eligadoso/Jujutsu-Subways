local Rules = {}
function Rules.available(deadline, now, occupied, outside)
	return not occupied and (deadline == nil or (now >= deadline and outside))
end
return Rules
