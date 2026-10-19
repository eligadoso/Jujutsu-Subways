local Style = {}

-- Decorative geometry never participates in obstacle queries or physical collisions.
function Style.detail(parent, name, size, frame, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, frame, color
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.CastShadow = false
	p.Material = material or Enum.Material.Metal
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Style.label(part, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face = "Marking", Enum.NormalId.Back
	gui.SizingMode, gui.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 32
	gui.LightInfluence = 0.25
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextColor3, label.TextScaled = text, color or Color3.fromRGB(236, 246, 247), true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

function Style.lighting()
	local lighting = game:GetService("Lighting")
	lighting.ClockTime, lighting.Brightness = 17.6, 2.1
	lighting.GlobalShadows, lighting.ShadowSoftness = true, 0.35
	lighting.Ambient = Color3.fromRGB(93, 80, 119)
	lighting.OutdoorAmbient = Color3.fromRGB(134, 143, 170)
	lighting.ColorShift_Top = Color3.fromRGB(255, 225, 192)
	lighting.EnvironmentDiffuseScale, lighting.EnvironmentSpecularScale = 0.65, 0.8
	local function effect(className, name)
		local existing = lighting:FindFirstChild(name)
		if existing then return existing end
		local instance = Instance.new(className)
		instance.Name, instance.Parent = name, lighting
		return instance
	end
	local atmosphere = effect("Atmosphere", "RunnerAtmosphere")
	atmosphere.Density, atmosphere.Offset = 0.18, 0.15
	atmosphere.Color, atmosphere.Decay = Color3.fromRGB(209, 216, 240), Color3.fromRGB(123, 108, 157)
	atmosphere.Glare, atmosphere.Haze = 0.08, 0.8
	local bloom = effect("BloomEffect", "RunnerBloom")
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.2, 20, 1.8
	local grade = effect("ColorCorrectionEffect", "RunnerColor")
	grade.Brightness, grade.Contrast, grade.Saturation = 0.025, 0.08, 0.05
	grade.TintColor = Color3.fromRGB(249, 246, 255)
end

return Style
