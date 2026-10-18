local Presentation = require("../src/shared/PlayerPresentation")
local Access = require("../src/shared/DevAccess")
assert(Presentation.team("Race") == "Jugando" and Presentation.team("Solo") == "Jugando")
assert(Presentation.team("Lobby") == "AFK" and Presentation.team("Finished") == "AFK")
assert(Presentation.canSpectate("Finished", false))
assert(Presentation.canSpectate("Lobby", true))
assert(not Presentation.canSpectate("Lobby", false))
assert(Presentation.canSpectate("Lobby", false, "Race"), "Any lobby player can spectate an ongoing race without enabling AFK")
assert(not Presentation.canSpectate("Lobby", false, "Intermission"))
assert(not Presentation.canSpectate("Race", false, "Race") and not Presentation.canSpectate("Solo", false, "Race"))
assert(not Presentation.canSpectate("Race", true) and not Presentation.canSpectate("Solo", true))
assert(Presentation.isTarget("Race", true) and Presentation.isTarget("Solo", true))
assert(not Presentation.isTarget("Race", false) and not Presentation.isTarget("Finished", true))
assert(Presentation.nextSpectatorIndex(0, 3, 1) == 1)
assert(Presentation.nextSpectatorIndex(0, 3, -1) == 3)
assert(Presentation.nextSpectatorIndex(3, 3, 1) == 1)
assert(Presentation.nextSpectatorIndex(1, 3, -1) == 3)
assert(Presentation.nextSpectatorIndex(0, 0, 1) == nil)
local records = {
	{id = 5, name = "Idle", team = "AFK", state = "Lobby", place = 0, studs = 9999, coins = 50},
	{id = 3, name = "Practice", team = "Jugando", state = "Solo", place = 0, studs = 9000, coins = 100},
	{id = 2, name = "Second", team = "Jugando", state = "Race", place = 2, studs = 500, coins = 3},
	{id = 1, name = "First", team = "Jugando", state = "Race", place = 1, studs = 700, coins = 0},
}
Presentation.sort(records)
assert(records[1].id == 1 and records[2].id == 2 and records[3].id == 3 and records[4].id == 5)
assert(records[1].coins == 0 and records[1].studs == 700, "Ranking must not replace progress/coin values")
local settings = {UserIds = {42}, AllowStudio = true}
assert(Access.allowed(42, "Group", 100, false, settings))
assert(Access.allowed(100, "User", 100, false, settings))
assert(not Access.allowed(100, "Group", 100, false, settings), "A group id is not a developer user id")
assert(not Access.allowed(99, "User", 100, false, settings), "Ordinary published-game players must be denied")
assert(not Access.allowed(0, "User", 0, false, settings))
assert(Access.allowed(-1, "User", 0, true, settings), "Local Studio test access")
settings.AllowStudio = false
assert(not Access.allowed(-1, "User", 0, true, settings))
print("PlayerPresentation: AFK/playing groups, position ranking, spectator access/cycling and developer authorization passed")
