local Animation = require("../src/shared/MovementAnimation")
local rigs = {
    {"Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    {"LowerTorso", "UpperTorso", "Head", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
        "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"},
}
for _, parts in rigs do
    for _, running in {0, 1} do
        for _, crouched in {0, 1} do
            for _, name in parts do
                local min, max = {math.huge, math.huge, math.huge}, {-math.huge, -math.huge, -math.huge}
                for frame = 0, 120 do
                    local angles = Animation.angles(name, frame / 120 * math.pi * 4, running, crouched)
                    for axis = 1, 3 do
                        assert(angles[axis] == angles[axis] and math.abs(angles[axis]) <= 120, "Joint motion must remain finite and bounded")
                        min[axis], max[axis] = math.min(min[axis], angles[axis]), math.max(max[axis], angles[axis])
                    end
                end
                -- Forearms hold a bent pose; the other segments keep moving in all four states.
                if not string.find(name, "LowerArm") then
                    assert(max[1] - min[1] + max[2] - min[2] + max[3] - min[3] > 0.1, name .. " must animate in every movement state")
                end
            end
        end
    end
end
for _, fps in {15, 30, 60, 144, 240} do
    local blend = 0
    for _ = 1, fps do
        local previous = blend
        blend = Animation.blend(blend, true, 1 / fps)
        assert(blend >= previous and blend <= 1 and blend - previous <= 6 / fps + 1e-9)
    end
    assert(blend == 1)
    for _ = 1, fps do blend = Animation.blend(blend, false, 1 / fps) end
    assert(blend == 0, "Releasing crouch or expiring sneakers must restore the board stance")
end
for _, crouched in {0, 1} do
    local left = Animation.angles("LeftUpperLeg", math.pi / 2, 1, crouched)
    local right = Animation.angles("RightUpperLeg", math.pi / 2, 1, crouched)
    assert(left[1] - right[1] > 40, "Standing and crouched running must alternate legs")
end
local unknown = Animation.angles("CustomDecoration", 1, 1, 1)
assert(unknown[1] == 0 and unknown[2] == 0 and unknown[3] == 0, "Unrecognized accessory joints must retain their pose")
print("MovementAnimation: four moving stances for R6/R15, alternating crouched strides, bounded joints and smooth transitions passed")
