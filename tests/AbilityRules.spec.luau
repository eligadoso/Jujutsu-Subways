local Rules = require("../src/shared/AbilityRules")
local Config = require("../src/shared/GameConfig")
assert(#Config.PowerUps.Catalog == 5)
for _, power in Config.PowerUps.Catalog do assert(power.Id ~= "Backpack" and not string.find(power.Id, "Placeholder")) end
assert(Rules.coinLoss(10, 0.3) == 3 and Rules.coinLoss(0, 0.3) == 0)
assert(Rules.coinLoss(1, 0.3) == 1)
assert(Rules.speed(30, 1, 0, 0, 5, 0.6) == 60)
assert(Rules.speed(30, 1, 2, 0, 5, 0.6) == 0)
assert(Rules.speed(30, 1, 0, 5, 0, 0.6) == 18)
assert(Rules.speed(30, 8, 2, 5, 6, 0.6) == 30)
for _, fps in {15, 30, 60, 144, 240} do
	local factor = 1
	for _ = 1, fps do
		local previous = factor
		factor = Rules.shoeMultiplier(factor, true, 1/fps)
		assert(factor >= previous and factor <= 2 and factor-previous <= 3/fps+0.00001)
	end
	assert(factor == 2, "Shoes must reach x2 without compounding their multiplier")
	for _ = 1, fps do factor = Rules.shoeMultiplier(factor, false, 1/fps) end
	assert(factor == 1, "Shoes must return smoothly to normal speed")
end
local function p(x, z) return {X = x, Y = 3, Z = z} end
for _, fps in {15, 30, 60, 144, 240} do
	local speed = 42
	for _ = 1, fps * 4 do
		local previous = speed
		speed = Rules.controlledSpeed(speed, 144, 1/fps, 80, 28, 40)
		assert(speed >= previous and speed <= 80)
		assert(speed - previous <= 28/fps + 0.00001, "Shoes must limit acceleration even with another boost")
	end
	assert(speed == 80)
	for _ = 1, fps * 2 do
		local previous = speed
		speed = Rules.controlledSpeed(speed, 26, 1/fps, 80, 28, 40)
		assert(speed >= 26 and previous - speed <= 40/fps + 0.00001)
	end
	assert(speed == 26, "Expiry must brake smoothly to the normal speed without overshoot")
end
assert(Rules.hits(p(0, 20), p(0, -20), p(0, -10), p(0, 10), 2.4), "Relative sweeps must detect fast crossings")
assert(not Rules.hits(p(0, 20), p(0, -20), p(6, -10), p(6, 10), 2.4), "A lane change must dodge the projectile")
assert(Rules.hits(p(0, 0), p(0, 0), p(0, 5), p(0, -5), 2.7), "Stationary traps must detect moving runners")
print("AbilityRules: five actual items, coin penalties, double speed, expiry and swept hits passed")
