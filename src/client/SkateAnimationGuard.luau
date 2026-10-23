local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local records = {}
local function clear(player)
	local record = records[player]
	if record then record.connection:Disconnect(); records[player] = nil end
end
Players.PlayerRemoving:Connect(clear)
RunService.PreSimulation:Connect(function()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local record = records[player]
		if record and (record.character ~= character or not character:GetAttribute("Skateboarding")) then clear(player); record = nil end
		if not character or not character:GetAttribute("Skateboarding") then continue end
		if not record then
			record = {character = character, joints = {}, nextCheck = 0}
			for _, joint in character:GetDescendants() do if joint:IsA("Motor6D") then table.insert(record.joints, joint) end end
			record.connection = character.DescendantAdded:Connect(function(joint)
				if joint:IsA("Motor6D") then table.insert(record.joints, joint) end
			end)
			records[player] = record
		end
		if os.clock() >= record.nextCheck then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
			if animator then for _, track in animator:GetPlayingAnimationTracks() do track:Stop(0) end end
			record.nextCheck = os.clock() + 0.15
		end
		-- Animator writes Transform locally; keep the replicated skating C0 pose on every client.
		for _, joint in record.joints do if joint.Parent then joint.Transform = CFrame.identity end end
	end
end)
return true
