local Drafting = {}
function Drafting.inWake(follower, leader, settings)
	local gap = follower.Z - leader.Z
	return settings.Enabled and gap >= settings.MinDistance and gap <= settings.MaxDistance
		and math.abs(follower.X - leader.X) <= settings.LateralRange and math.abs(follower.Y - leader.Y) <= 4
end
function Drafting.charge(current, following, dt, settings)
	return math.clamp(current + (if following then dt else -dt * 2), 0, settings.ChargeTime)
end
return Drafting
