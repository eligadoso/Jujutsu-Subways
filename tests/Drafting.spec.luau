local Drafting = require("../src/shared/Drafting")
local Config = require("../src/shared/GameConfig")
local s = Config.Drafting
local follower = {X = 0, Y = 4, Z = 0}
assert(Drafting.inWake(follower, {X = 0, Y = 4, Z = -12}, s))
assert(not Drafting.inWake(follower, {X = 0, Y = 4, Z = 12}, s))
assert(not Drafting.inWake(follower, {X = 6, Y = 4, Z = -12}, s))
assert(not Drafting.inWake(follower, {X = 0, Y = 20, Z = -12}, s))
assert(not Drafting.inWake(follower, {X = 0, Y = 4, Z = -40}, s))
for _, fps in {15, 30, 60, 144} do
	local charge = 0
	for _ = 1, fps * 2 do charge = Drafting.charge(charge, true, 1 / fps, s) end
	assert(math.abs(charge - s.ChargeTime) < 0.00001)
	for _ = 1, fps do charge = Drafting.charge(charge, false, 1 / fps, s) end
	assert(charge == 0)
end
print("Drafting: following direction, lane/height range, charge and decay at multiple frame rates passed")
