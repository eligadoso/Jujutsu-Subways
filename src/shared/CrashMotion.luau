local CrashMotion = {}

function CrashMotion.sample(elapsed, duration)
	local t = math.clamp(elapsed / math.max(duration, 0.001), 0, 1)
	-- A strong initial push that eases to rest at the safe recovery position.
	return 1 - (1 - t) ^ 3, math.sin(math.pi * t)
end

function CrashMotion.blink(now, deadline, interval)
	return deadline > now and math.floor((deadline - now) / math.max(interval, 0.01)) % 2 == 0
end

return CrashMotion
