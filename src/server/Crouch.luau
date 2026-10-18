local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Crouch = {}

function Crouch.create(character, humanoid)
	local board = character:FindFirstChild("Skateboard")
	local mount = board and board.PrimaryPart:FindFirstChild("SkateboardMount")
	local state = {
		character = character,
		humanoid = humanoid,
		height = humanoid.HipHeight,
		drop = math.min(Config.Crouch.HeightReduction, math.max(0, humanoid.HipHeight - 0.1)),
		mount = mount,
		mountC0 = mount and mount.C0,
		joints = {},
		active = false,
	}
	local angles = {
		Waist = -30, Neck = 15,
		LeftHip = -35, RightHip = -35,
		LeftKnee = 60, RightKnee = 60,
		LeftAnkle = -25, RightAnkle = -25,
		["Left Hip"] = -30, ["Right Hip"] = -30,
		RootJoint = -20,
	}
	for _, joint in character:GetDescendants() do
		local angle = angles[joint.Name]
		if joint:IsA("Motor6D") and angle then
			table.insert(state.joints, {joint = joint, standing = joint.C0, crouched = joint.C0 * CFrame.Angles(math.rad(angle), 0, 0)})
		end
	end
	character:SetAttribute("Crouching", false)
	return state
end

function Crouch.set(state, active)
	if state.active == active then return end
	state.active = active
	state.humanoid.Jump = false
	state.humanoid.HipHeight = state.height - (if active then state.drop else 0)
	-- Keep the deck at wheel height when the rider's body moves down.
	if state.mount then
		state.mount.C0 = state.mountC0 * CFrame.new(0, if active then state.drop else 0, 0)
	end
	for _, pose in state.joints do
		if pose.joint.Parent then pose.joint.C0 = if active then pose.crouched else pose.standing end
	end
	state.character:SetAttribute("Crouching", active)
end

return Crouch
