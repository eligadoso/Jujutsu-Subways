local View = {}
function View.valid(snapshot, targetId, now)
	return snapshot ~= nil and snapshot.targetId == targetId and now - snapshot.time <= 1.5
end
function View.source(watching, targetId, hasTargetRoot, snapshot, now)
	if not watching then return "Self" end
	if hasTargetRoot then return "Target" end
	if View.valid(snapshot, targetId, now) then return "Snapshot" end
	return "Waiting"
end
return View
