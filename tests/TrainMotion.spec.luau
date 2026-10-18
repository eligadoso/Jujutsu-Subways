local Motion = require("../src/shared/TrainMotion")
local Config = require("../src/shared/GameConfig")
local Layout = require("../src/shared/ObstacleLayout")
local RampMotion = require("../src/shared/RampMotion")
local function close(a, b) assert(math.abs(a - b) < 0.00001) end

for _, fps in {15, 30, 60, 144} do
	local z = -260
	for _ = 1, fps * 3 do z = Motion.advance(z, Config.Trains.Speed, 1 / fps) end
	close(z, -260 + 3 * Config.Trains.Speed)
end
assert(Motion.advance(-100, Config.Trains.Speed, 1) > -100, "Train must approach against negative-Z player travel")
close(Motion.relativeTravel(-7, 3.8), -10.8)
close(Motion.relativeTravel(0, 20), -20)

local ramp = {kind = "RampTruck", firstLane = 0, z = -100}
local finish = ramp.z + Config.Obstacles.TruckLength / 2
local start = finish + Config.Obstacles.RampLength
close(Layout.rampSurface(ramp, 0, start, Config.Track, Config.Obstacles), 0)
close(Layout.rampSurface(ramp, 0, (start + finish) / 2, Config.Track, Config.Obstacles), 8)
close(Layout.rampSurface(ramp, 0, finish, Config.Track, Config.Obstacles), 16)
assert(Layout.rampSurface(ramp, 6, (start + finish) / 2, Config.Track, Config.Obstacles) == nil, "Neighbor lanes must not get ramp protection")
assert(Layout.rampSurface(ramp, 0, finish - 3, Config.Track, Config.Obstacles) == nil, "Protection must end after reaching the roof")
assert(Layout.rampSurface({kind = "Truck"}, 0, 0, Config.Track, Config.Obstacles) == nil)
local all = Motion.availableLanes({}, Config.Track, -300, 100)
assert(#all == 5, "All train lanes must be eligible")
local selected = {}
for n = 0, 99 do selected[Motion.chooseLane(all, nil, n / 100)] = true end
for lane = -2, 2 do assert(selected[lane]) end
local blocked = {
	{kind = "Truck", firstLane = -1, width = 2, box = {minZ = -150, maxZ = -100}},
	{kind = "Sign", firstLane = 2, width = 1, box = {minZ = -120, maxZ = -119}},
}
local available = Motion.availableLanes(blocked, Config.Track, -300, 100)
assert(#available == 2 and available[1] == -2 and available[2] == 1)
assert(Motion.chooseLane(available, -2, 0) == 1, "Prefer a different train lane when alternatives exist")
assert(Motion.chooseLane({}, nil, 0) == nil, "Defer a train when its path is blocked")
assert(#Motion.availableLanes(blocked, Config.Track, -500, -400) == 5, "Distant obstacles must not reserve lanes")

for _, fps in {15, 30, 60, 144} do
	local vertical = 0
	for _ = 1, fps * 2 do
		vertical = RampMotion.verticalSpeed(vertical, 70, 0, 16 / 28, 1 / fps, 196.2)
		vertical -= 196.2 / fps -- Gravity applied by the engine's next physics step.
	end
	close(vertical, 40)
end
print("TrainMotion: varied lanes, clear paths, relative sweep, ramp bounds and smooth ramp velocity at 15/30/60/144 FPS passed")
