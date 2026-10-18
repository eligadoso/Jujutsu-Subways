local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Layout = require(Shared:WaitForChild("ObstacleLayout"))
local TrainMotion = require(Shared:WaitForChild("TrainMotion"))
local RampMotion = require(Shared:WaitForChild("RampMotion"))
local Module = {}
function Module.new(context)
	local origin = context.Origin
	local Service = {}
	local chunks = {}
	local settings = table.clone(Config.Obstacles)
	local worldSeed = context.Seed
	settings.Seed = (settings.Seed + worldSeed) % 2147483647

	local function part(parent, name, size, position, color, solid)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position, p.Color = name, size, position + origin, color
		p.Anchored = true
		p.CanCollide = solid or false
		p.CanTouch = false
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end

	function Service.addChunk(index, parent)
		local folder = Instance.new("Folder", parent)
		folder.Name = "Obstacles"
		local entries = {}
		for _, data in Layout.generate(index, Config.Track, settings) do
			local width = data.width * Config.Track.LaneWidth - 0.7
			local x = (data.firstLane + (data.width - 1) / 2) * Config.Track.LaneWidth
			local z = data.z
			local model = Instance.new("Model", folder)
			model.Name = data.kind
			local box = {minX = x - width / 2, maxX = x + width / 2}
			data.hazards = {}
			local function hazard(p)
				table.insert(data.hazards, p)
				return p
			end
			if data.kind == "Truck" or data.kind == "RampTruck" then
				local climbable = data.kind == "RampTruck"
				local height = settings.TruckHeight
				local length = settings.TruckLength
				data.height = height
				local palette = {Color3.fromRGB(219, 84, 57), Color3.fromRGB(55, 111, 183), Color3.fromRGB(231, 170, 47), Color3.fromRGB(118, 77, 169), Color3.fromRGB(46, 151, 137)}
				local color = palette[data.paint or 1]
				hazard(part(model, "Cargo", Vector3.new(width, height - 0.8, length), Vector3.new(x, (height + 0.8) / 2, z), color, true))
				-- Flush roofs meet at lane boundaries, so the rider can cross without falling into a gap.
				part(model, "WalkableRoof", Vector3.new(data.width * Config.Track.LaneWidth, 0.2, length), Vector3.new(x, height, z), Color3.fromRGB(212, 223, 229), true)
				hazard(part(model, "Cab", Vector3.new(width, 4.5, 5), Vector3.new(x, 2.8, z - length / 2 - 2.5), color, true))
				part(model, "Windshield", Vector3.new(width - 0.5, 1.5, 0.15), Vector3.new(x, 4, z - length / 2 - 5.1), Color3.fromRGB(67, 133, 170))
				for _, side in {-1, 1} do
					for _, offset in {-length / 2 + 4, length / 2 - 4} do
						local wheel = part(model, "Wheel", Vector3.new(0.5, 1.5, 1.5), Vector3.new(x + side * width / 2, 0.8, z + offset), Color3.fromRGB(24, 29, 36))
						wheel.Shape = Enum.PartType.Cylinder
					end
				end
				box.minY, box.maxY = 0.8, height
				box.minZ, box.maxZ = z - length / 2 - 5, z + length / 2
				if data.kind == "RampTruck" then
					local run = settings.RampLength
					local rampZ = z + length / 2 + run / 2
					local ramp = part(model, "ClimbableRamp", Vector3.new(width, 0.3, math.sqrt(run * run + height * height)), Vector3.new(x, height / 2 - 0.15, rampZ), Color3.fromRGB(239, 192, 59), true)
					ramp.CFrame *= CFrame.Angles(math.atan(height / run), 0, 0)
					-- Transverse strips make the climb read as a loading ladder/ramp.
					for step = 2, run - 2, 3 do
						local strip = part(model, "RampStep", Vector3.new(width, 0.06, 0.3), Vector3.zero, Color3.fromRGB(49, 57, 64))
						strip.CFrame = ramp.CFrame * CFrame.new(0, 0.18, step - run / 2)
					end
					data.rampStart, data.rampEnd = z + length / 2 + run, z + length / 2
				end
			elseif data.kind == "Sign" then
				hazard(part(model, "OverheadSign", Vector3.new(width, settings.SignTop - settings.SignBottom, 1.2), Vector3.new(x, (settings.SignBottom + settings.SignTop) / 2, z), Color3.fromRGB(244, 166, 40)))
				for _, side in {-1, 1} do
					hazard(part(model, "Post", Vector3.new(0.22, settings.SignTop, 0.4), Vector3.new(x + side * width / 2, settings.SignTop / 2, z), Color3.fromRGB(62, 69, 79)))
				end
				box.minY, box.maxY = settings.SignBottom, settings.SignTop
				box.minZ, box.maxZ = z - 0.6, z + 0.6
			else
				-- Logical hit detection allows a clean jump without physical snagging.
				width = Config.Track.LaneCount * Config.Track.LaneWidth + 4
				box.minX, box.maxX = -width / 2, width / 2
				hazard(part(model, "JumpBarrier", Vector3.new(width, settings.BarrierHeight, 0.65), Vector3.new(0, settings.BarrierHeight / 2, z), Color3.fromRGB(241, 105, 52)))
				for stripe = -width / 2 + 1, width / 2 - 1, 2 do
					part(model, "Stripe", Vector3.new(0.7, settings.BarrierHeight, 0.05), Vector3.new(stripe, settings.BarrierHeight / 2, z + 0.35), Color3.fromRGB(255, 238, 151))
				end
				box.minY, box.maxY = 0, settings.BarrierHeight
				box.minZ, box.maxZ = z - 0.325, z + 0.325
			end
			data.box = box
			table.insert(entries, data)
		end
		chunks[index] = {folder = folder, entries = entries}
	end

	function Service.removeChunk(index)
		if chunks[index] then chunks[index].folder:Destroy() end
		chunks[index] = nil
	end

	function Service.setMovingEntries(entries)
		chunks.Moving = {entries = entries}
	end

	function Service.staticEntries()
		local entries = {}
		for key, chunk in chunks do
			if key == "Moving" then continue end
			for _, entry in chunk.entries do table.insert(entries, entry) end
		end
		return entries
	end

	function Service.clearRamp(runner)
		for _, constraint in runner.rampConstraints or {} do constraint:Destroy() end
		runner.rampConstraints = nil
		runner.rampEntry = nil
		if runner.root.Parent then runner.root.Parent:SetAttribute("OnRamp", false) end
	end

	local function footDistance(runner)
		local root, humanoid = runner.root, runner.humanoid
		local distance = root.Size.Y / 2 + humanoid.HipHeight
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			local leg = root.Parent:FindFirstChild("Left Leg")
			distance += if leg then leg.Size.Y else 2
		end
		return distance
	end

	function Service.prepareRamp(runner, dt, speed)
		if workspace:GetServerTimeNow() < (runner.rampJumpUntil or 0) then return end
		local root = runner.root
		local distance = footDistance(runner)
		local floorY = root.Position.Y - distance
		local entry = runner.rampEntry
		if entry and Layout.rampSurface(entry, root.Position.X - origin.X, root.Position.Z, Config.Track, settings) == nil then
			if root.Position.Z < entry.rampEnd - 2 and floorY >= entry.height - 0.5 then
				local v = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(v.X, math.min(v.Y, 0), v.Z)
			end
			Service.clearRamp(runner)
			entry = nil
		end
		if not entry then
			for _, chunk in chunks do
				for _, candidate in chunk.entries do
					local surface = Layout.rampSurface(candidate, root.Position.X - origin.X, root.Position.Z, Config.Track, settings)
					local enteredFromBehind = candidate.rampStart and runner.previousPosition.Z >= candidate.rampStart - 0.5
					if surface == nil and enteredFromBehind
						and math.abs(root.Position.X - origin.X - candidate.firstLane * Config.Track.LaneWidth) <= (Config.Track.LaneWidth - 0.7) / 2
						and root.Position.Z <= candidate.rampStart and root.Position.Z >= candidate.z - settings.TruckLength / 2 then
						surface = candidate.height
					end
					if surface and (floorY >= surface - 2 or enteredFromBehind) then
						entry = candidate
						break
					end
				end
				if entry then break end
			end
			if not entry then return end
			runner.rampEntry = entry
			runner.rampConstraints = {}
			-- Ignore only the supporting convoy's chassis, retaining solid ramp and roof surfaces.
			for _, chunk in chunks do
				for _, truck in chunk.entries do
					if truck.roofAccess and truck.z == entry.z then
						for _, chassis in truck.hazards do
							for _, body in root.Parent:GetChildren() do
								if body:IsA("BasePart") then
									local constraint = Instance.new("NoCollisionConstraint")
									constraint.Part0, constraint.Part1 = body, chassis
									constraint.Parent = root
									table.insert(runner.rampConstraints, constraint)
								end
							end
						end
					end
				end
			end
			root.Parent:SetAttribute("OnRamp", true)
		end
		local surface = math.clamp((entry.rampStart - root.Position.Z) / settings.RampLength, 0, 1) * entry.height
		if floorY > surface + 1 then return end
		local velocity = root.AssemblyLinearVelocity
		local onSlope = root.Position.Z > entry.rampEnd
		local slope = if onSlope then entry.height / settings.RampLength else 0
		local vertical = RampMotion.verticalSpeed(velocity.Y, if onSlope then speed else 0, surface - floorY, slope, dt, workspace.Gravity)
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, vertical, velocity.Z)
	end

	function Service.coinHeight(index, x, z, height)
		local chunk = chunks[index]
		if not chunk then return height end
		local raised = height
		for _, entry in chunk.entries do
			local box = entry.box
			if x < box.minX - 1 or x > box.maxX + 1 then continue end
			if entry.kind == "Truck" or entry.kind == "RampTruck" then
				if z >= box.minZ - 1 and z <= box.maxZ + 1 then
					if entry.kind == "Truck" and not entry.roofAccess then return nil end
					if z < entry.z - settings.TruckLength / 2 then return nil end
					raised = math.max(raised, entry.height + height + 0.1)
				elseif entry.rampStart and z >= entry.rampEnd and z <= entry.rampStart then
					raised = math.max(raised, height + (entry.rampStart - z) / settings.RampLength * entry.height)
				end
			elseif z >= box.minZ - 3 and z <= box.maxZ + 3 then
				-- Don't lure the rider into a sign or a ground-level jump barrier.
				return nil
			end
		end
		return raised
	end

	function Service.check(runner)
		local root, humanoid = runner.root, runner.humanoid
		local floorY = root.Position.Y - footDistance(runner)
		local hazards, staticHazards, moving, owners = {}, {}, {}, {}
		local margin = math.max(root.Size.X, root.Size.Y, root.Size.Z) * 2 + 4
		local nearMinZ = math.min(root.Position.Z, runner.previousPosition.Z) - margin
		local nearMaxZ = math.max(root.Position.Z, runner.previousPosition.Z) + margin
		for _, chunk in chunks do
			for _, entry in chunk.entries do
				if runner.rampEntry and entry.roofAccess and entry.z == runner.rampEntry.z then continue end
				if entry.height and floorY >= entry.height - 0.2 then continue end
				local movingIncluded = false
				for _, obstaclePart in entry.hazards do
					local deltaZ = if entry.motionDelta then entry.motionDelta.Z else 0
					if math.max(obstaclePart.Position.Z, obstaclePart.Position.Z - deltaZ) + obstaclePart.Size.Z / 2 < nearMinZ
						or math.min(obstaclePart.Position.Z, obstaclePart.Position.Z - deltaZ) - obstaclePart.Size.Z / 2 > nearMaxZ then continue end
					if obstaclePart.Name == "OverheadSign" and runner.crouch.active and floorY < 0.8 then continue end
					table.insert(hazards, obstaclePart)
					owners[obstaclePart] = entry
					if entry.motionDelta then movingIncluded = true else table.insert(staticHazards, obstaclePart) end
				end
				if movingIncluded then table.insert(moving, entry) end
			end
		end
		if #hazards == 0 then
			runner.previousBodyCFrames = {}
			return false
		end
		local overlaps = OverlapParams.new()
		overlaps.FilterType = Enum.RaycastFilterType.Include
		overlaps.FilterDescendantsInstances = hazards
		overlaps.MaxParts = 1
		local casts = RaycastParams.new()
		casts.FilterType = Enum.RaycastFilterType.Include
		casts.FilterDescendantsInstances = staticHazards
		casts.IgnoreWater = true
		runner.previousBodyCFrames = runner.previousBodyCFrames or {}
		local rootDelta = root.Position - runner.previousPosition
		for _, body in root.Parent:GetChildren() do
			-- Accessories and the long skateboard are visual, not early-impact hitboxes.
			if not body:IsA("BasePart") or body == root then continue end
			local previous = runner.previousBodyCFrames[body] or (body.CFrame - rootDelta)
			runner.previousBodyCFrames[body] = body.CFrame
			-- Query actual body geometry against the visible cargo/cab/sign/beam parts.
			local touching = workspace:GetPartsInPart(body, overlaps)
			if touching[1] then return owners[touching[1]] end
			local travel = body.Position - previous.Position
			-- A tiny contact tolerance also detects a character stopped flush by physics.
			local direction = travel + humanoid.MoveDirection * 0.025
			if #staticHazards > 0 and direction.Magnitude > 0.0001 then
				local hit = workspace:Blockcast(previous, body.Size, direction, casts)
				if hit and hit.Normal.Y < 0.5 then return owners[hit.Instance] end
			end
			for _, train in moving do
				casts.FilterDescendantsInstances = train.hazards
				local relative = TrainMotion.relativeTravel(travel, train.motionDelta)
				if relative.Magnitude > 0.0001 then
					local hit = workspace:Blockcast(previous + train.motionDelta, body.Size, relative, casts)
					if hit then return train end
				end
			end
			casts.FilterDescendantsInstances = staticHazards
		end
		return false
	end

	function Service.recovery(runner, hit)
		local entries = {}
		for _, chunk in chunks do
			for _, entry in chunk.entries do table.insert(entries, entry) end
		end
		return Layout.recovery(entries, hit, runner.root.Position - origin, Config.Track, Config.Crash)
	end

	return Service
end
return Module
