local Support = require("../src/shared/RigSupport")
local function frame(y, rightY, upY, lookY)
	return {Position = {Y = y}, RightVector = {Y = rightY}, UpVector = {Y = upY}, LookVector = {Y = lookY}}
end
for _, scale in {0.5, 1, 1.5, 2} do
	local size = {X = scale, Y = scale * 2, Z = scale}
	local sole = Support.soleY(frame(-2 * scale, 0, 1, 0), size)
	assert(sole == -3 * scale)
	local crouchedSole = Support.soleY(frame(-1.4 * scale, 0, 1, 0), size)
	local correction = Support.bodyOffset(-3 * scale, crouchedSole)
	assert(math.abs(crouchedSole + correction - sole) < 0.00001, "Different body scales must keep their feet on the fixed board")
end
local tilted = Support.soleY(frame(0, 0, 0, 1), {X = 1, Y = 2, Z = 3})
assert(tilted == -1.5, "Foot rotation must affect the sole support height")
print("RigSupport: scaled body support, crouch compensation and rotated feet passed")
