local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Layout = require(Shared:WaitForChild("CoinLayout"))
local CoinModel = require(script.Parent:WaitForChild("CoinModel"))
local Module = {}
function Module.new(context)
	local Obstacles = context.Obstacles
	local origin = context.Origin
	local CoinService = {}
	local chunks = {}
	local mode = context.CoinMode or Config.DefaultMode

	function CoinService.addChunk(index, parent)
		local folder = Instance.new("Folder")
		folder.Name = "Coins"
		folder.Parent = parent
		local entries = {}
		local settings = table.clone(Config.CoinModes[mode])
		if settings.Enabled then settings.Seed = (settings.Seed + context.Seed) % 2147483647 end
		for _, data in Layout.generate(index, Config.Track, settings) do
			local height = Obstacles.coinHeight(index, data.x, data.z, data.y)
			if not height then continue end
			local model, core = CoinModel.create(origin + Vector3.new(data.x, height, data.z), data.value, folder)
			table.insert(entries, {part = core, model = model, value = data.value, radius = data.radius})
		end
		chunks[index] = {parent = parent, folder = folder, entries = entries}
	end

	function CoinService.resetPlayer(player)
		local coins = player.leaderstats.Coins
		local lost = coins.Value
		coins.Value = 0
		player:SetAttribute("Coins", 0)
		return lost
	end

	function CoinService.removeChunk(index)
		local chunk = chunks[index]
		if chunk then chunk.folder:Destroy() end
		chunks[index] = nil
	end

	function CoinService.setMode(name)
		if not Config.CoinModes[name] then
			warn("Unknown coin mode: " .. tostring(name))
			return false
		end
		mode = name
		for index, chunk in chunks do
			chunk.folder:Destroy()
			CoinService.addChunk(index, chunk.parent)
		end
		return true
	end

	function CoinService.setupPlayer(player)
		local stats = player:FindFirstChild("leaderstats")
		if not stats then
			stats = Instance.new("Folder")
			stats.Name = "leaderstats"
			stats.Parent = player
		end
		local coins = stats:FindFirstChild("Coins")
		if not coins then
			coins = Instance.new("IntValue")
			coins.Name = "Coins"
			coins.Parent = stats
		end
		player:SetAttribute("Coins", coins.Value)
	end

	-- Server-owned collection uses swept distance to avoid skipping coins at low FPS.
	function CoinService.collect(player, previous, current)
		local collected = 0
		local segment = current - previous
		local lengthSquared = segment:Dot(segment)
		for _, chunk in chunks do
			for i = #chunk.entries, 1, -1 do
				local entry = chunk.entries[i]
				local position = entry.part.Position
				local t = if lengthSquared > 0 then math.clamp((position - previous):Dot(segment) / lengthSquared, 0, 1) else 0
				if (position - (previous + segment * t)).Magnitude <= entry.radius then
					-- Remove first so a shared coin can only be awarded once.
					table.remove(chunk.entries, i)
					entry.model:Destroy()
					local coins = player.leaderstats.Coins
					coins.Value += entry.value
					player:SetAttribute("Coins", coins.Value)
					collected += 1
				end
			end
		end
		return collected
	end

	return CoinService
end
return Module
