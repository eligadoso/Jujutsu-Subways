local Pose = require(script.Parent:WaitForChild("SkatePose"))
local Crouch = {}
function Crouch.create(character, humanoid, pose)
    character:SetAttribute("Crouching", false)
    return {character = character, humanoid = humanoid, pose = pose, active = false}
end
function Crouch.set(state, active)
    if state.active == active then return end
    state.active = active
    state.humanoid.Jump = false
    -- Only the body pose changes. HipHeight and the board mount remain fixed.
    Pose.apply(state.pose, active)
    state.character:SetAttribute("Crouching", active)
end
return Crouch