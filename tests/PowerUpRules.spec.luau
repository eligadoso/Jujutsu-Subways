local Rules = require("../src/shared/PowerUpRules")
local Config = require("../src/shared/GameConfig")
local settings = Config.PowerUps
local used = {[10] = true}
assert(not Rules.canCollect(used, 10, nil), "Same runner must not farm a previously collected diamond")
assert(Rules.canCollect(used, 20, nil), "A runner behind must retain their own copy")
assert(not Rules.canCollect(used, 20, "PlaceholderA"), "Full inventories must not consume the personal pickup")
assert(not Rules.spawns(0, settings) and not Rules.spawns(1, settings))
assert(Rules.spawns(2, settings) and Rules.spawns(6, settings))
assert(Rules.spawns(4, settings) and not Rules.spawns(3, settings))
local seen = {}
for i = 0, 99 do
	local power = Rules.choose(settings.Catalog, i / 100)
	assert(power and power.Id and power.Name)
	seen[power.Id] = true
end
for _, power in settings.Catalog do assert(seen[power.Id], "Each catalog entry must be selectable") end
assert(Rules.choose({}, 0.5) == nil)
assert(Rules.choose(settings.Catalog, 1) == settings.Catalog[#settings.Catalog])
assert(Rules.canUse("Race", true, "PlaceholderA"))
assert(Rules.canUse("Solo", true, "PlaceholderB"))
assert(not Rules.canUse("Lobby", true, "PlaceholderA"))
assert(not Rules.canUse("Finished", true, "PlaceholderA"))
assert(not Rules.canUse("Race", false, "PlaceholderA"))
assert(not Rules.canUse("Race", true, nil))
print("PowerUpRules: spawn spacing, random catalog coverage and use eligibility passed")
