local Spring = require("../src/shared/MotionSpring")

local expected
for _, fps in {15, 30, 60, 144} do
	local spring = Spring.new()
	local previous = 0
	for _ = 1, fps do
		local value = spring:step(0.35, 15, 1 / fps)
		assert(value >= previous and value <= 0.35, "Lane response must not overshoot")
		previous = value
	end
	if expected then assert(math.abs(spring.position - expected) < 1e-10, "Spring must be independent of frame rate") end
	expected = spring.position
	spring.position, spring.velocity = 0, -7.8
	local minimum = 0
	for _ = 1, fps do minimum = math.min(minimum, spring:step(0, 17, 1 / fps)) end
	assert(minimum < -0.1 and minimum > -0.2, "Landing response must remain bounded")
	assert(math.abs(spring.position) < 0.00001, "Landing impulse must settle")
end
local stopped = Spring.new()
stopped.velocity = 2
local value = stopped:step(0, 15, 0)
assert(value == 0 and stopped.velocity == 2, "Zero dt must preserve state")
print("MotionSpring: frame-rate independence, bounded lane response and landing settling passed")
