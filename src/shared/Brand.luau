local RunService = game:GetService("RunService")
local Brand = {
	-- Set the uploaded IMAGE asset ID here for published games and other computers.
	LogoAssetId = 120809108785221,
	LogoResolution = Vector2.new(1448, 1086),
	Ink = Color3.fromRGB(15, 12, 30),
	Panel = Color3.fromRGB(29, 21, 49),
	Purple = Color3.fromRGB(175, 70, 255),
	Cyan = Color3.fromRGB(83, 224, 255),
	Gold = Color3.fromRGB(255, 204, 55),
	Muted = Color3.fromRGB(184, 174, 205),
}

function Brand.logo(parent, size, position)
	local image = Instance.new("ImageLabel")
	image.Name, image.Size, image.Position = "GameLogo", size, position
	image.BackgroundTransparency = 1
	image.ScaleType = Enum.ScaleType.Fit
	local aspect = Instance.new("UIAspectRatioConstraint", image)
	aspect.AspectRatio = Brand.LogoResolution.X / Brand.LogoResolution.Y
	aspect.AspectType = Enum.AspectType.FitWithinMaxSize
	image.Image = if Brand.LogoAssetId > 0 then "rbxassetid://" .. Brand.LogoAssetId
		elseif RunService:IsStudio() then "rbxasset://textures/JujutsuSubway/Logo.png" else ""
	image.Parent = parent
	if image.Image == "" then
		local fallback = Instance.new("TextLabel")
		fallback.Size, fallback.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		fallback.Text, fallback.TextColor3 = "JUJUTSU\nSUBWAY", Brand.Gold
		fallback.Font, fallback.TextScaled = Enum.Font.GothamBlack, true
		fallback.Parent = image
	end
	return image
end

return Brand
