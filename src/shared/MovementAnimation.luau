-- Angles are in the parent body's axes; joint offsets retain each avatar's scale.
local Animation = {}
local roles = {
    Torso = "torso", UpperTorso = "torso", LowerTorso = "hips", Head = "head",
    ["Left Leg"] = "leg", ["Right Leg"] = "leg",
    LeftUpperLeg = "thigh", RightUpperLeg = "thigh",
    LeftLowerLeg = "shin", RightLowerLeg = "shin",
    LeftFoot = "foot", RightFoot = "foot",
    ["Left Arm"] = "arm", ["Right Arm"] = "arm",
    LeftUpperArm = "arm", RightUpperArm = "arm",
    LeftLowerArm = "forearm", RightLowerArm = "forearm",
    LeftHand = "hand", RightHand = "hand",
}

function Animation.blend(current, active, dt)
    return current + math.clamp((if active then 1 else 0) - current, -6 * math.max(dt, 0), 6 * math.max(dt, 0))
end

local function mix(a, b, t)
    return {a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t}
end

local function sample(role, side, phase, running, crouched)
    local swing = math.sin(phase) * side
    local bounce = math.cos(phase * 2)
    local sway = math.sin(phase * 0.5)
    if running then
        -- Duck-running keeps a short, continuous stride instead of freezing the legs.
        if role == "torso" then return {if crouched then -34 + bounce * 2 else -10 + bounce * 2, swing * 2, sway * 2}
        elseif role == "hips" then return {if crouched then -8 else -2, swing * 2, 0}
        elseif role == "head" then return {if crouched then 24 else 8, -swing, 0}
        elseif role == "thigh" or role == "leg" then return {(if crouched then -24 else 0) + swing * (if crouched then 26 else 42), 0, side * 2}
        elseif role == "shin" then return {(if crouched then 58 else 15) + math.max(0, -swing) * (if crouched then 24 else 35), 0, 0}
        elseif role == "foot" then return {(if crouched then -28 else -6) - swing * 12, 0, 0}
        elseif role == "arm" then return {(if crouched then -28 else -12) - swing * (if crouched then 22 else 38), 0, -side * 8}
        elseif role == "forearm" then return {if crouched then -70 else -55, 0, 0}
        elseif role == "hand" then return {5 + swing * 3, 0, 0} end
    else
        -- Gentle balance motion remains active in both board stances.
        if role == "torso" then return {(if crouched then -30 else -6) + bounce * (if crouched then 1.5 else 1), sway * 2, sway * 3}
        elseif role == "hips" then return {0, -sway, -sway * 2}
        elseif role == "head" then return {if crouched then 22 else 4, -sway * 2, -sway * 2}
        elseif role == "thigh" then return {(if crouched then -40 else -10) - bounce * 1.5, 0, 0}
        elseif role == "shin" then return {(if crouched then 80 else 16) + bounce * 3, 0, 0}
        elseif role == "foot" then return {(if crouched then -40 else -6) - bounce * 1.5, 0, 0}
        elseif role == "leg" then return {(if crouched then 30 else 6) + bounce * 1.5, 0, 0}
        elseif role == "arm" then return {(if crouched then -25 else -8) + sway * side * 4, 0, -side * (12 + sway * 3)}
        elseif role == "forearm" then return {if crouched then -35 else -12, 0, 0}
        elseif role == "hand" then return {sway * 3, 0, 0} end
    end
    return {0, 0, 0}
end

function Animation.angles(partName, phase, running, crouched)
    local role = roles[partName]
    local side = if string.sub(partName, 1, 4) == "Left" then 1 else -1
    local board = mix(sample(role, side, phase, false, false), sample(role, side, phase, false, true), crouched)
    local run = mix(sample(role, side, phase, true, false), sample(role, side, phase, true, true), crouched)
    return mix(board, run, running)
end

return Animation
