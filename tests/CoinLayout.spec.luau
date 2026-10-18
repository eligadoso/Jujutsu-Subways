local Config = require("../src/shared/GameConfig")
local Layout = require("../src/shared/CoinLayout")

assert(#Layout.generate(0, Config.Track, Config.CoinModes.NoCoins) == 0)
for _, mode in {"Classic", "CoinRush"} do
	local settings = Config.CoinModes[mode]
	for index = -2, 30 do
		local coins = Layout.generate(index, Config.Track, settings)
		local repeated = Layout.generate(index, Config.Track, settings)
		assert(#coins == #repeated, "Generation must be repeatable")
		if mode == "CoinRush" then assert(#coins >= 30 and #coins <= 50, "Rush must vary line lengths while filling five lanes") end
		local seen = {}
		for i, coin in coins do
			assert(coin.x == repeated[i].x and coin.z == repeated[i].z)
			assert(math.abs(coin.x) <= 12 and coin.x % 6 == 0, "Coin outside five lanes")
			assert(math.abs(coin.z + index * 100) <= 45, "Coin outside its chunk")
			assert(coin.value == settings.Value and coin.radius == settings.PickupRadius)
			local key = string.format("%f:%f", coin.x, coin.z)
			assert(not seen[key], "Overlapping coins")
			seen[key] = true
		end
	end
end

local restricted = table.clone(Config.CoinModes.Classic)
restricted.AllowedLanes = {-2, 2, 99, -99, 2}
restricted.SpawnChance = 1
restricted.LinesPerChunk = 5
restricted.CoinsPerLine = 100
restricted.MinCoinsPerLine = nil
restricted.Spacing = 7
local coins = Layout.generate(4, Config.Track, restricted)
assert(#coins == 26, "Long lines must be clipped to chunk boundaries and invalid/duplicate lanes ignored")
for _, coin in coins do
	assert(math.abs(coin.x) == 12)
	assert(math.abs(coin.z + 400) <= 45)
end
assert(#Config.CoinModes.Classic.AllowedLanes == 5, "Generation must not modify mode settings")
print("CoinLayout: deterministic layouts, mode rules, five-lane bounds and restricted/long lines passed")
