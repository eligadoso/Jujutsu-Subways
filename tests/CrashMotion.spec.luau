local Motion = require("../src/shared/CrashMotion")

for _, fps in {15, 30, 60, 144} do
	local previous = 0
	for frame = 0, fps do
		local progress, bounce = Motion.sample(frame / fps, 0.5)
		assert(progress >= previous and progress <= 1, "Recoil must move toward safety without overshooting")
		assert(bounce >= 0 and bounce <= 1, "Recoil bounce must stay bounded")
		previous = progress
	end
	assert(previous == 1, "Recovery must reach its safe destination")
end
local start, startBounce = Motion.sample(0, 0.5)
local finish, finishBounce = Motion.sample(0.5, 0.5)
assert(start == 0 and startBounce == 0)
assert(finish == 1 and math.abs(finishBounce) < 0.00001)
assert(not Motion.blink(2, 1.25, 0.1), "Protection must not blink after expiry")
assert(Motion.blink(1.2, 1.25, 0.1) ~= Motion.blink(1.1, 1.25, 0.1), "Protection must alternate visibility")
print("CrashMotion: bounded recoil, safe endpoints and protection blinking passed")
