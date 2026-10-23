local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local hidden = {}
local visibility = setmetatable({}, {__mode = "k"})
ReplicatedStorage:WaitForChild("PersonalPowerPickup").OnClientEvent:Connect(function(id, deadline) hidden[id] = deadline end)
ReplicatedStorage:WaitForChild("PersonalCoinPickup").OnClientEvent:Connect(function(ids, deadline)
	for _, id in ids do hidden[id] = deadline end
end)
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then return end
	elapsed = 0
	local now = workspace:GetServerTimeNow()
	for id, deadline in hidden do if now >= deadline then hidden[id] = nil end end
	for _, tag in {"PersonalPowerPickup", "PersonalCoinPickup"} do
		for _, model in CollectionService:GetTagged(tag) do
			local invisible = hidden[model:GetAttribute("PickupId")] ~= nil
			if visibility[model] ~= invisible then
				for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.LocalTransparencyModifier = if invisible then 1 else 0 end end
				visibility[model] = invisible
			end
		end
	end
end)
return true
