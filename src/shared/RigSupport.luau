local Support = {}
function Support.soleY(frame, size)
	return frame.Position.Y - (math.abs(frame.RightVector.Y) * size.X + math.abs(frame.UpVector.Y) * size.Y + math.abs(frame.LookVector.Y) * size.Z) / 2
end
function Support.bodyOffset(boardTop, sole)
	return boardTop - sole
end
return Support
