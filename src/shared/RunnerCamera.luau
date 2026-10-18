local Camera = {}
function Camera.frame(position, originX)
	local localX = position.X - originX
	return CFrame.lookAt(position + Vector3.new(-localX * 0.65, 9, 17), position + Vector3.new(0, 2, -18))
end
return Camera
