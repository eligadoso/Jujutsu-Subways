local Rules = {}
Rules.__index = Rules

function Rules.new(settings, now)
	return setmetatable({settings = settings, state = "Intermission", deadline = now + settings.Intermission, roundId = 0, entries = {}}, Rules)
end

function Rules.eligible(state, afk, ready)
	return state == "Lobby" and not afk and ready
end

function Rules:begin(now, ids, modeName)
	if self.state ~= "Intermission" or #ids == 0 then return false end
	local mode = assert(self.settings.Modes[modeName], "Unknown match mode")
	self.roundId += 1
	self.modeName, self.mode = modeName, mode
	self.state, self.started, self.deadline = "Race", now, now + mode.Duration
	self.nextCapture = if mode.CaptureInterval then now + mode.CaptureInterval else nil
	if mode.CaptureInterval then self.deadline = now + mode.CaptureInterval * math.max(1, #ids - 1) + 5 end
	self.entries = {}
	for _, id in ids do self.entries[id] = {id = id, status = "Running", progress = 0, checked = now} end
	return true
end

function Rules.crossingTime(previous, current, previousTime, now, distance)
	if current < distance then return nil end
	if current <= previous then return now end
	return previousTime + (now - previousTime) * math.clamp((distance - previous) / (current - previous), 0, 1)
end

function Rules:finish(id, time)
	local entry = self.entries[id]
	if self.state ~= "Race" or not entry or entry.status ~= "Running" or time > self.deadline then return false end
	entry.status, entry.elapsed = "Finished", math.max(0, time - self.started)
	if not self.mode.CaptureInterval then entry.progress = self.mode.Distance end
	return true
end

function Rules:capture(now)
	if self.state ~= "Race" or not self.mode.CaptureInterval then return nil end
	local active = {}
	for _, entry in self.entries do if entry.status == "Running" then table.insert(active, entry) end end
	table.sort(active, function(a, b)
		if a.progress ~= b.progress then return a.progress < b.progress end
		return a.id > b.id
	end)
	local captured
	if #active > 1 and now >= self.nextCapture then
		captured = table.remove(active, 1)
		captured.status, captured.capturedAt = "Captured", now
		self.nextCapture = now + self.mode.CaptureInterval
	end
	local winner = if #active == 1 then active[1] else nil
	if winner then self:finish(winner.id, now) end
	return {captured = captured and captured.id, winner = winner and winner.id}
end

function Rules:withdraw(id)
	local entry = self.entries[id]
	if entry and entry.status == "Running" then entry.status = "Withdrawn" end
end

function Rules:standings()
	local result = {}
	for _, entry in self.entries do table.insert(result, entry) end
	table.sort(result, function(a, b)
		local priority = {Finished = 0, Running = 1, Captured = 2, TimedOut = 3, Withdrawn = 4}
		if priority[a.status] ~= priority[b.status] then return priority[a.status] < priority[b.status] end
		if a.status == "Finished" and a.elapsed ~= b.elapsed then return a.elapsed < b.elapsed end
		if a.status == "Captured" and a.capturedAt ~= b.capturedAt then return a.capturedAt > b.capturedAt end
		if a.progress ~= b.progress then return a.progress > b.progress end
		return a.id < b.id
	end)
	return result
end

function Rules:tick(now)
	if self.state == "Intermission" then
		if now >= self.deadline then return "Start" end
		return nil
	end
	local remaining = 0
	for _, entry in self.entries do
		if entry.status == "Running" then remaining += 1 end
	end
	if remaining == 0 or now >= self.deadline then
		for _, entry in self.entries do
			if entry.status == "Running" then entry.status = "TimedOut" end
		end
		self.state, self.deadline = "Intermission", now + self.settings.Intermission
		return "Ended"
	end
	return nil
end

return Rules
