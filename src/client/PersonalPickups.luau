local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local hidden = {}
ReplicatedStorage:WaitForChild("PersonalPowerPickup").OnClientEvent:Connect(function(id) hidden[id] = true end)
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then return end
	elapsed = 0
	for _, model in CollectionService:GetTagged("PersonalPowerPickup") do
		if hidden[model:GetAttribute("PickupId")] then
			for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.LocalTransparencyModifier = 1 end end
		end
	end
end)
return true
