local Access = {}
function Access.allowed(userId, creatorType, creatorId, studio, settings)
	if studio and settings.AllowStudio then return true end
	if creatorType == "User" and creatorId > 0 and userId == creatorId then return true end
	return table.find(settings.UserIds, userId) ~= nil
end
return Access
