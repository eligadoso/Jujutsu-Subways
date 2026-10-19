local Spring = {}
Spring.__index = Spring

function Spring.new()
	return setmetatable({position = 0, velocity = 0}, Spring)
end

-- Exact critically damped integration; consistent at different frame rates.
function Spring:step(target, frequency, dt)
	local offset = self.position - target
	local decay = math.exp(-frequency * dt)
	local momentum = self.velocity + frequency * offset
	self.position = target + (offset + momentum * dt) * decay
	self.velocity = (self.velocity - frequency * momentum * dt) * decay
	return self.position
end

return Spring
