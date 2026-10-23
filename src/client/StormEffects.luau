local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local started, deadline, baseline
local grade = Instance.new("ColorCorrectionEffect", Lighting)
grade.Name, grade.Enabled = "LightningStormGrade", false
local function skyBolt()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local origin = camera.Focus.Position + camera.CFrame.LookVector * 55 + Vector3.new(0, 36, 0)
	local last = origin
	for i = 1, 7 do
		local nextPoint = origin + Vector3.new(math.sin(i * 5) * 4, -i * 5, 0)
		local p = Instance.new("Part")
		p.Name, p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = "SkyLightning", true, false, false, false
		p.Size, p.CFrame = Vector3.new(0.22, 0.22, (last-nextPoint).Magnitude), CFrame.lookAt((last+nextPoint)/2, nextPoint)
		p.Material, p.Color, p.CastShadow = Enum.Material.Neon, Color3.fromRGB(229, 238, 255), false
		p.Parent = workspace
		Debris:AddItem(p, 0.35)
		last = nextPoint
	end
end
ReplicatedStorage:WaitForChild("LightningStorm").OnClientEvent:Connect(function(time, duration)
	if workspace:GetServerTimeNow() > time + duration then return end
	if not baseline then
		baseline = {ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ExposureCompensation = Lighting.ExposureCompensation}
	end
	started, deadline = time, math.max(deadline or 0, time + duration)
	grade.Enabled = true
	skyBolt()
end)
RunService:BindToRenderStep("LightningWeather", Enum.RenderPriority.Last.Value, function()
	if not baseline then return end
	local now = workspace:GetServerTimeNow()
	if now >= deadline then
		for property, value in baseline do Lighting[property] = value end
		grade.Enabled, baseline, started, deadline = false, nil, nil, nil
		return
	end
	local fade = math.clamp((deadline-now) / 0.65, 0, 1)
	local age = now - started
	local flash = math.max(0, 1 - age / 0.12) * 0.5
	Lighting.ClockTime = baseline.ClockTime + (0.5-baseline.ClockTime) * fade
	Lighting.Brightness = baseline.Brightness * (1 - 0.7 * fade) + flash * 3
	Lighting.Ambient = baseline.Ambient:Lerp(Color3.fromRGB(42, 43, 80), fade)
	Lighting.OutdoorAmbient = baseline.OutdoorAmbient:Lerp(Color3.fromRGB(54, 62, 95), fade)
	Lighting.ExposureCompensation = baseline.ExposureCompensation - 0.45 * fade + flash
	grade.TintColor = Color3.new(1,1,1):Lerp(Color3.fromRGB(184, 200, 255), fade * 0.45)
	grade.Contrast, grade.Brightness = 0.15 * fade, flash * 0.3
end)
return true
