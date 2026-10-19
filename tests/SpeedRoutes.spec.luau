local Routes = require("../src/shared/SpeedRoutes")
local Config = require("../src/shared/GameConfig")
local Motion = require("../src/shared/RunnerMotion")
local settings, track = Config.SpeedRoutes, Config.Track
local lengths, rewards, shapes, stepCounts = {}, {}, {}, {}
local total, pairs, turns = 0, 0, 0
local function point(lane, z, y) return {X = lane * track.LaneWidth, Y = y or 4, Z = z} end
for seed = 1, 40 do
    for index = 1, 150 do
        local routes = Routes.generateSet(index, track, settings, seed * 7919)
        local repeatRoutes = Routes.generateSet(index, track, settings, seed * 7919)
        assert(#routes == #repeatRoutes, "Generation must be independent of chunk creation order")
        if #routes == 2 then
            pairs += 1
            assert(routes[1].maxLane < routes[2].minLane, "Contested routes must not cross")
            assert(routes[1].contest == routes[2].contest)
        end
        for r, route in routes do
            total += 1
            assert(route.length == repeatRoutes[r].length and route.lane == repeatRoutes[r].lane)
            lengths[route.length], rewards[route.bonus], stepCounts[route.steps] = true, true, true
            assert(route.steps >= 2 and route.steps <= 4 and #route.gates == route.steps)
            assert(route.bonus >= 14 and route.bonus <= settings.MaxBonus)
            assert(route.duration > settings.Duration and route.duration <= settings.MaxDuration)
            assert(route.minLane >= -2 and route.maxLane <= 2)
            assert(route.minLane > -2 or route.maxLane < 2, "A bypass lane must remain available")
            local previous = {lane = route.lane, z = route.entryZ}
            local signature = ""
            for _, gate in route.gates do
                assert(previous.z - gate.z >= settings.MinSpacing)
                assert(math.abs(previous.lane - gate.lane) <= 1, "Bends must be adjacent lane changes")
                assert(gate.lane >= route.minLane and gate.lane <= route.maxLane)
                if gate.lane ~= previous.lane then turns += 1 end
                previous = gate
            end
            for _, obstacle in route.obstacles do
                assert(obstacle.width == 1 and obstacle.z < route.entryZ and obstacle.z > route.padZ)
                signature ..= obstacle.kind .. obstacle.firstLane .. ":"
            end
            shapes[signature] = true
            local finalChunk = math.floor((-route.padZ + 50) / 100)
            for chunk = index, finalChunk do assert(Routes.reserved(chunk, track, settings, seed * 7919)) end
            local id = total
            local _, started = Routes.collect(route, point(route.lane, route.entryZ + 1), point(route.lane, route.entryZ - 1), 6, id)
            assert(started == "Active")
            for _, gate in route.gates do
                local won, state = Routes.collect(route, point(gate.lane, gate.z + 1), point(gate.lane, gate.z - 1), 6, id)
                assert(not won and state == "Active")
            end
            local won, state = Routes.collect(route, point(route.exitLane, route.padZ + 1), point(route.exitLane, route.padZ - 1, 9), 6, id)
            assert(won and state == "Complete")
            assert(not Routes.collect(route, point(route.exitLane, route.padZ + 1), point(route.exitLane, route.padZ - 1), 6, id))
            assert(not Routes.collect(route, point(route.exitLane, route.padZ + 1), point(route.exitLane, route.padZ - 1), 6, -id), "Exit alone must not reward shortcuts")
        end
        if #routes == 2 then
            local first = Routes.reward(routes[1], 1)
            local second = Routes.reward(routes[2], 2)
            assert(first.bonus == routes[1].bonus + 2 and second.bonus == routes[2].bonus)
        end
    end
end
local function count(items) local n = 0; for _ in items do n += 1 end; return n end
assert(total > 500 and pairs > 100 and turns > 100)
assert(count(lengths) > 30 and count(shapes) > 100 and count(rewards) >= 4 and count(stepCounts) == 3, "Generation must provide substantial variation")
local route
for index = 3, 10 do route = Routes.generate(index, track, settings, 473); if route then break end end
Routes.collect(route, point(route.lane, route.entryZ + 1), point(route.lane, route.entryZ - 1), 6, 10000)
local _, failed = Routes.collect(route, point(route.lane, route.entryZ - 1), point(8, route.entryZ - 2), 6, 10000)
assert(failed == "Failed")
assert(not Routes.crossed(route, point(route.exitLane, route.padZ - 1), point(route.exitLane, route.padZ + 1), 6))
for _, fps in {15, 30, 60, 144} do
    local speed = 42
    for _ = 1, fps * 2 do speed = Motion.approachSpeed(speed, 80, "Classic", 1 / fps, settings.MaxBonus) end
    assert(math.abs(speed - 64) < 0.00001)
    for _ = 1, fps * 4 do speed = Motion.approachSpeed(speed, 80, "Classic", 1 / fps, 0) end
    assert(math.abs(speed - 42) < 0.00001)
end
print("SpeedRoutes: procedural variation, safe spacing, reserved chunks, bends, checkpoints and contested rewards passed")