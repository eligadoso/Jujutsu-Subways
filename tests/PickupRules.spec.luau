local Rules = require("../src/shared/PickupRules")
local used = {}
assert(Rules.available(used[1], 0, false, true))
used[1] = 6
assert(not Rules.available(used[1], 2, false, true))
assert(Rules.available(used[2], 2, false, true), "A runner behind must have an independent copy")
assert(Rules.available(used[1], 6, false, true), "The object must regenerate for its collector")
assert(not Rules.available(used[1], 6, false, false), "Camping inside a pickup must not farm it")
assert(not Rules.available(nil, 6, true, true), "A full power slot must leave the pickup available")
assert(Rules.available(nil, 6, false, false), "A never-collected pickup may be taken from inside its radius")
print("PickupRules: per-player availability, timed respawns, full slots and anti-camping passed")
