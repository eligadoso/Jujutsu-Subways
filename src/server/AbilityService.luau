local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Rules = require(Shared:WaitForChild("AbilityRules"))
local Style = require(script.Parent:WaitForChild("VisualStyle"))
local feedback = Instance.new("RemoteEvent")
feedback.Name, feedback.Parent = "AbilityFeedback", ReplicatedStorage
local warning = Instance.new("RemoteEvent")
warning.Name, warning.Parent = "ProjectileWarning", ReplicatedStorage
local storm = Instance.new("RemoteEvent")
storm.Name, storm.Parent = "LightningStorm", ReplicatedStorage
local Service = {}
function Service.new(world)
	local self, objects = {}, {}
	local s = Config.Abilities
	local folder = Instance.new("Folder", world.folder)
	folder.Name = "Abilities"
	local function flash(character, color)
		local highlight = Instance.new("Highlight")
		highlight.FillColor, highlight.OutlineColor, highlight.FillTransparency = color, color, 0.35
		highlight.Adornee, highlight.Parent = character, character
		Debris:AddItem(highlight, 0.35)
	end
	local function loseCoins(player, runner, fraction)
		local coins = player.leaderstats.Coins
		local lost = Rules.coinLoss(coins.Value, fraction)
		local ratio = if coins.Value > 0 then (coins.Value - lost) / coins.Value else 1
		coins.Value -= lost
		player:SetAttribute("Coins", coins.Value)
		runner.collectedCoins = math.floor(runner.collectedCoins * ratio)
	end
	local function hit(player, runner, kind, now)
		if now < (runner.protectedUntil or 0) or now < (runner.itemProtectedUntil or 0) then return false end
		if kind == "Egg" then
			runner.eggUntil = now + s.EggDuration
			player:SetAttribute("EggUntil", runner.eggUntil)
		elseif kind == "MouseTrap" then
			runner.slowUntil = now + s.SlowDuration
			player:SetAttribute("SlowUntil", runner.slowUntil)
			player.leaderstats.Coins.Value += s.BaitCoins
			player:SetAttribute("Coins", player.leaderstats.Coins.Value)
			runner.collectedCoins += s.BaitCoins
		else
			runner.stunUntil = now + (if kind == "Lightning" then s.StunDuration else 0.45)
			runner.jumpUntil = nil
			player:SetAttribute("StunUntil", runner.stunUntil)
			loseCoins(player, runner, if kind == "Lightning" then s.LightningLoss else s.BoomerangLoss)
		end
		runner.itemProtectedUntil = now + s.HitProtection
		world.obstacles.cancelRoute(player, true)
		flash(runner.root.Parent, if kind == "Egg" then Color3.fromRGB(255, 232, 150) else Color3.fromRGB(255, 195, 65))
		feedback:FireClient(player, kind, if kind == "Egg" then s.EggDuration else 1)
		return true
	end
	local function gear(runner, kind, duration)
		if runner[kind .. "Visual"] then runner[kind .. "Visual"]:Destroy() end
		local model = Instance.new("Model", runner.root.Parent)
		model.Name = kind .. "Effect"
		runner[kind .. "Visual"] = model
		local function piece(name, base, offset, size, color)
			local p = Style.detail(model, name, size, base.CFrame * offset, color, Enum.Material.SmoothPlastic)
			p.Anchored, p.Massless = false, true
			local weld = Instance.new("WeldConstraint", p)
			weld.Part0, weld.Part1 = base, p
		end
		do
			for _, side in {"Left", "Right"} do
				local foot = runner.root.Parent:FindFirstChild(side .. "Foot") or runner.root.Parent:FindFirstChild(side .. " Leg")
				if foot then
					piece("Shoe", foot, CFrame.new(0, -foot.Size.Y / 2 + 0.2, -0.2), Vector3.new(1.05, 0.45, 1.65), Color3.fromRGB(255, 183, 52))
					piece("Sole", foot, CFrame.new(0, -foot.Size.Y / 2, -0.2), Vector3.new(1.1, 0.12, 1.7), Color3.fromRGB(90, 230, 255))
				end
			end
		end
		Debris:AddItem(model, duration)
		if runner.root:IsDescendantOf(workspace) then runner.root:SetNetworkOwner(nil) end
	end
	function self.use(player, runner, kind, direction)
		local now = workspace:GetServerTimeNow()
		if kind == "Sneakers" then
			runner.shoesUntil = now + s.SneakersDuration
			player:SetAttribute("ShoesUntil", runner.shoesUntil)
			gear(runner, kind, s.SneakersDuration)
		elseif kind == "Lightning" then
			storm:FireAllClients(workspace:GetServerTimeNow(), 2.2)
			local function boltAt(position)
				local last = position + Vector3.new(0, 55, 0)
				for i = 1, 8 do
					local nextPoint = position + Vector3.new(if i == 8 then 0 else math.sin(i * 5.7) * 4, 55 * (1 - i / 8), math.cos(i * 3.1) * 1.5)
					local frame = CFrame.lookAt((last + nextPoint) / 2, nextPoint)
					local glow = Style.detail(folder, "LightningGlow", Vector3.new(0.65, 0.65, (last-nextPoint).Magnitude), frame, Color3.fromRGB(118, 153, 255), Enum.Material.Neon)
					glow.Transparency = 0.45
					local core = Style.detail(folder, "LightningCore", Vector3.new(0.2, 0.2, (last-nextPoint).Magnitude), frame, Color3.fromRGB(245, 251, 255), Enum.Material.Neon)
					Debris:AddItem(glow, 0.5); Debris:AddItem(core, 0.5)
					last = nextPoint
				end
			end
			boltAt(runner.root.Position)
			for target, other in world.runners do
				if target ~= player and other.root.Parent and other.humanoid.Health > 0 then
					boltAt(other.root.Position)
					hit(target, other, kind, now)
				end
			end
		else
			local model = Instance.new("Model", folder)
			model.Name = kind
			local position = runner.root.Position + Vector3.new(0, 0, 3)
			if kind == "Egg" then
				Style.bubble(model, "Egg", Vector3.new(1.25, 1.65, 1.25), CFrame.new(position), Color3.fromRGB(255, 246, 219))
			elseif kind == "Boomerang" then
				for _, side in {-1, 1} do
					local frame = CFrame.new(position) * CFrame.Angles(0, side * math.rad(45), 0) * CFrame.new(0, 0, -1.1)
					Style.detail(model, "Wing", Vector3.new(0.65, 0.3, 3), frame, Color3.fromRGB(255, 194, 66))
					Style.detail(model, "WingGlow", Vector3.new(0.22, 0.34, 2.7), frame, Color3.fromRGB(128, 239, 255), Enum.Material.Neon)
				end
			elseif kind == "MouseTrap" then
				local params = RaycastParams.new()
				params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {runner.root.Parent, folder}
				local ground = workspace:Raycast(position, Vector3.new(0, -50, 0), params)
				position = if ground then ground.Position + Vector3.new(0, 0.25, 0) else position - Vector3.new(0, 3, 0)
				Style.detail(model, "TrapBoard", Vector3.new(2.8, 0.25, 3), CFrame.new(position), Color3.fromRGB(173, 113, 68))
				for _, side in {-1, 1} do Style.detail(model, "SpringJaw", Vector3.new(0.16, 0.3, 2.5), CFrame.new(position + Vector3.new(side, 0.25, 0)), Color3.fromRGB(238, 102, 119)) end
				for i = -1, 1 do
					local coin = Style.detail(model, "BaitCoin", Vector3.new(0.12, 0.65, 0.65), CFrame.new(position + Vector3.new(i * 0.65, 0.6, 0)) * CFrame.Angles(0, math.pi/2, 0), Color3.fromRGB(255, 213, 60), Enum.Material.Metal)
					coin.Shape = Enum.PartType.Cylinder
				end
			end
			model:PivotTo(CFrame.new(position))
			if kind == "Egg" or kind == "Boomerang" then
				local highlight = Instance.new("Highlight", model)
				highlight.Adornee, highlight.FillTransparency, highlight.OutlineTransparency = model, 1, 0
				highlight.OutlineColor, highlight.DepthMode = Color3.fromRGB(255, 226, 116), Enum.HighlightDepthMode.Occluded
				local main = model:FindFirstChildWhichIsA("BasePart")
				if main then
					local a, b = Instance.new("Attachment", main), Instance.new("Attachment", main)
					a.Position, b.Position = Vector3.new(-0.35, 0, 0), Vector3.new(0.35, 0, 0)
					local trail = Instance.new("Trail", main)
					trail.Attachment0, trail.Attachment1, trail.Lifetime = a, b, 0.22
					trail.Color, trail.LightEmission, trail.FaceCamera = ColorSequence.new(Color3.fromRGB(255, 220, 75), Color3.fromRGB(112, 230, 255)), 0.8, true
					trail.Transparency = NumberSequence.new(0.2, 1)
				end
				for target, other in world.runners do
					if target ~= player and other.root.Parent and other.humanoid.Health > 0 then
						local gap = other.root.Position.Z - position.Z
						if math.abs(gap) <= 240 and (kind == "Boomerang" or gap * direction >= 0) then
							warning:FireClient(target, position.X, now + (if kind == "Egg" then s.EggLifetime else 1.65))
						end
					end
				end
			end
			if #objects >= s.MaxObjects then objects[1].model:Destroy(); table.remove(objects, 1) end
			table.insert(objects, {model = model, owner = player, kind = kind, start = position, position = position, age = 0, direction = direction, hits = {}})
		end
		feedback:FireClient(player, "Used", 0.6, kind)
	end
	function self.update(dt)
		local now = workspace:GetServerTimeNow()
		for i = #objects, 1, -1 do
			local o = objects[i]
			o.age += dt
			local owner = world.runners[o.owner]
			local lifetime = if o.kind == "MouseTrap" then s.TrapLifetime elseif o.kind == "Egg" then s.EggLifetime else 1.65
			if not owner or o.age >= lifetime then o.model:Destroy(); table.remove(objects, i); continue end
			local previous = o.position
			if o.kind == "Egg" then o.position += Vector3.new(0, 0, o.direction * s.EggSpeed * dt)
			elseif o.kind == "Boomerang" then
				local z = if o.age < 0.65 then o.start.Z + 70 * o.age / 0.65 else (o.start.Z + 70) + (owner.root.Position.Z - 20 - o.start.Z - 70) * (o.age - 0.65)
				o.position = Vector3.new(o.start.X, o.start.Y, z)
			end
			if o.kind ~= "MouseTrap" then o.model:PivotTo(CFrame.new(o.position) * CFrame.Angles(0, if o.kind == "Boomerang" then o.age * 22 else 0, 0)) end
			if o.kind == "Egg" then
				local params = RaycastParams.new()
				local ignored = {folder}
				for _, runner in world.runners do if runner.root.Parent then table.insert(ignored, runner.root.Parent) end end
				params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, ignored
				if workspace:Raycast(previous, o.position - previous, params) then o.model:Destroy(); table.remove(objects, i); continue end
			end
			for target, other in world.runners do
				if target == o.owner or o.hits[target] or not other.root.Parent or other.humanoid.Health <= 0 or (o.kind == "MouseTrap" and o.age < 0.5) then continue end
				local heightOffset = if o.kind == "MouseTrap" then Vector3.new(0, -2, 0) else Vector3.zero
				if Rules.hits(previous, o.position, other.previousPosition + heightOffset, other.root.Position + heightOffset, if o.kind == "MouseTrap" then 2.7 else 2.4)
					and hit(target, other, o.kind, now) then
					o.hits[target] = true
					if o.kind ~= "Boomerang" then o.model:Destroy(); table.remove(objects, i); break end
				end
			end
		end
	end
	function self.clear(runner)
		for _, name in {"SneakersVisual"} do if runner[name] then runner[name]:Destroy(); runner[name] = nil end end
	end
	return self
end
return Service
