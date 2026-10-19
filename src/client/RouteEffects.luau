local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Feedback = require(script.Parent:WaitForChild("PlayerFeedback"))
local colors = {
	Idle = Color3.fromRGB(169, 65, 255),
	Active = Color3.fromRGB(255, 210, 50),
	Failed = Color3.fromRGB(255, 65, 75),
	Complete = Color3.fromRGB(90, 255, 161),
}
local states, visuals = {}, {}
local function track(folder)
	if visuals[folder] then return end
	local record = {folder = folder, lines = {}}
	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "RiskLane" then table.insert(record.lines, part) end
	end
	record.connection = folder.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") and part.Name == "RiskLane" then table.insert(record.lines, part) end
	end)
	visuals[folder] = record
end
for _, folder in CollectionService:GetTagged("SpeedRouteVisual") do track(folder) end
CollectionService:GetInstanceAddedSignal("SpeedRouteVisual"):Connect(track)
CollectionService:GetInstanceRemovedSignal("SpeedRouteVisual"):Connect(function(folder)
	local record = visuals[folder]
	if record then record.connection:Disconnect(); visuals[folder] = nil end
	local id = folder:GetAttribute("RouteId")
	if id then states[id] = nil end
end)
ReplicatedStorage:WaitForChild("RouteFeedback").OnClientEvent:Connect(function(id, state, step)
	local previous = states[id]
	if state ~= "Active" or (previous and step > previous.step) then Feedback.route(state) end
	states[id] = {state = state, step = step, deadline = os.clock() + (if state == "Active" then 10 else 1.6)}
end)
RunService:BindToRenderStep("RunnerRouteFeedback", Enum.RenderPriority.Last.Value, function(dt)
	local now = os.clock()
	local session = player:GetAttribute("SessionState")
	local active = session == "Race" or session == "Solo"
	for id, state in states do if state.deadline <= now or not active then states[id] = nil end end
	local blend = 1 - math.exp(-18 * dt)
	for folder, record in visuals do
		local state = states[folder:GetAttribute("RouteId")]
		for _, line in record.lines do
			if not line.Parent then continue end
			local color = colors.Idle
			if state then
				color = colors[state.state] or colors.Idle
				if state.state == "Active" and (line:GetAttribute("RouteSegment") or 1) < state.step then color = colors.Complete end
			end
			line.Color = line.Color:Lerp(color, blend)
		end
	end
end)
return true
