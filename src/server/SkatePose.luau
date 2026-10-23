local Support = require(game:GetService("ReplicatedStorage").Shared:WaitForChild("RigSupport"))
local Pose = {}

local function rotation(x, y, z) return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z)) end

function Pose.apply(state, crouched, stride)
    state.crouched = crouched
    local frames = {[state.root] = CFrame.identity}
    for _, entry in state.joints do
        local joint = entry.joint
        if not joint.Parent then continue end
        local name = joint.Part1 and joint.Part1.Name or ""
        local angle = CFrame.identity
        if name == "UpperTorso" or name == "Torso" then angle = rotation(if crouched then -30 else -6, 0, 0)
        elseif name == "LeftUpperLeg" or name == "RightUpperLeg" then angle = rotation(if crouched then -40 else -10, 0, 0)
        elseif name == "LeftLowerLeg" or name == "RightLowerLeg" then angle = rotation(if crouched then 80 else 16, 0, 0)
        elseif name == "LeftFoot" or name == "RightFoot" then angle = rotation(if crouched then -40 else -6, 0, 0)
        elseif name == "Left Leg" or name == "Right Leg" then angle = rotation(if crouched then 30 else 6, 0, 0)
        elseif name == "LeftUpperArm" or name == "Left Arm" then angle = rotation(if crouched then -25 else -8, 0, -12)
        elseif name == "RightUpperArm" or name == "Right Arm" then angle = rotation(if crouched then -25 else -8, 0, 12) end
        if state.running and not crouched then
            local swing = math.sin(stride or 0)
            local side = if string.sub(name, 1, 4) == "Left" then 1 else -1
            if string.find(name, "UpperLeg") or name == "Left Leg" or name == "Right Leg" then angle = rotation(42 * swing * side, 0, 0)
            elseif string.find(name, "LowerLeg") then angle = rotation(15 + 35 * math.max(0, -swing * side), 0, 0)
            elseif string.find(name, "UpperArm") or name == "Left Arm" or name == "Right Arm" then angle = rotation(-38 * swing * side - 12, 0, side * -8)
            elseif string.find(name, "LowerArm") then angle = rotation(-55, 0, 0)
            elseif name == "UpperTorso" or name == "Torso" then angle = rotation(-10, 0, 0) end
        end
        joint.C0 = CFrame.new(entry.original.Position) * angle * entry.original.Rotation
        joint.Transform = CFrame.identity
    end
    -- Resolve the actual joint graph, independent of part lengths, scale and motor names.
    for _ = 1, #state.joints do
        local advanced = false
        for _, entry in state.joints do
            local joint = entry.joint
            if joint.Parent and joint.Part0 and joint.Part1 and frames[joint.Part0] and not frames[joint.Part1] then
                frames[joint.Part1] = frames[joint.Part0] * joint.C0 * joint.C1:Inverse()
                advanced = true
            end
        end
        if not advanced then break end
    end
    local sole
    for _, name in {"LeftFoot", "RightFoot", "Left Leg", "Right Leg"} do
        local foot = state.character:FindFirstChild(name)
        if foot and frames[foot] then
            local bottom = Support.soleY(frames[foot], foot.Size)
            sole = if sole then math.min(sole, bottom) else bottom
        end
    end
    local board = state.character:FindFirstChild("Skateboard")
    local deck = board and board.PrimaryPart
    local mount = deck and deck:FindFirstChild("SkateboardMount")
    if sole and mount and state.rootJoint then
        local boardTop = mount.C0.Position.Y + deck.Size.Y / 2 + 0.04
        if state.running then boardTop -= 0.65 end
        state.rootJoint.C0 = CFrame.new(0, Support.bodyOffset(boardTop, sole), 0) * state.rootJoint.C0
    end
end

function Pose.setRunning(state, active)
    if state.running == active then return end
    state.running = active
    state.character:SetAttribute("SneakersRunning", active)
    local board = state.character:FindFirstChild("Skateboard")
    if board then
        state.visibility = state.visibility or {}
        for _, object in board:GetDescendants() do
            if object:IsA("BasePart") then
                if active then state.visibility[object] = object.Transparency end
                object.Transparency = if active then 1 else state.visibility[object] or 0
            elseif object:IsA("Trail") or object:IsA("ParticleEmitter") then
                if active then state.visibility[object] = object.Enabled end
                object.Enabled = if active then false else state.visibility[object] == true
            end
        end
    end
    Pose.apply(state, state.crouched or false)
end

function Pose.start(character, humanoid)
    local state = {joints = {}, character = character, root = character:FindFirstChild("HumanoidRootPart")}
    local animate = character:FindFirstChild("Animate")
    if animate and animate:IsA("LocalScript") then
        state.animate, state.enabled = animate, animate.Enabled
        animate.Enabled = false
    end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in animator:GetPlayingAnimationTracks() do track:Stop(0) end
        state.connection = animator.AnimationPlayed:Connect(function(track)
            if character:GetAttribute("Skateboarding") then track:Stop(0) end
        end)
    end
    for _, joint in character:GetDescendants() do
        if joint:IsA("Motor6D") then
            table.insert(state.joints, {joint = joint, original = joint.C0})
            if joint.Part0 == state.root then state.rootJoint = joint end
        end
    end
    Pose.apply(state, false)
    return state
end

function Pose.stop(state)
    if not state then return end
    state.character:SetAttribute("SneakersRunning", false)
    if state.connection then state.connection:Disconnect() end
    for _, entry in state.joints do
        if entry.joint.Parent then entry.joint.C0, entry.joint.Transform = entry.original, CFrame.identity end
    end
    if state.animate and state.animate.Parent then state.animate.Enabled = state.enabled end
end
return Pose
