-- Ghost (ModuleScript in ServerScriptService)
-- The monster. It wanders the hotel, chases anyone it sees or hears, searches where it last
-- saw you, then goes back to wandering. Break line of sight and get far enough away to escape it.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Ghost = {}
Ghost.__index = Ghost

local HOVER = 3.5 -- height of the ghost's centre above the floor

local function addPart(model, name, shape, size, offset, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = model:GetPivot() * CFrame.new(offset)
	part.Parent = model
	return part
end

local function buildModel(position)
	local model = Instance.new("Model")
	model.Name = "Ghost"

	local pale = Color3.fromRGB(205, 220, 228)
	local root = addPart(model, "Root", Enum.PartType.Block, Vector3.new(3.2, 6, 1.8), Vector3.zero, pale, Enum.Material.SmoothPlastic, 0.3)
	model.PrimaryPart = root
	root.CFrame = CFrame.new(position)

	local head = addPart(model, "Head", Enum.PartType.Ball, Vector3.new(2.4, 2.4, 2.4), Vector3.new(0, 4.2, 0), pale, Enum.Material.SmoothPlastic, 0.2)
	addPart(model, "EyeLeft", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), Vector3.new(-0.55, 4.4, -1), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, 0)
	addPart(model, "EyeRight", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), Vector3.new(0.55, 4.4, -1), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, 0)
	addPart(model, "ArmLeft", Enum.PartType.Block, Vector3.new(0.6, 4.5, 0.6), Vector3.new(-2, 0.5, -0.4), pale, Enum.Material.SmoothPlastic, 0.4)
	addPart(model, "ArmRight", Enum.PartType.Block, Vector3.new(0.6, 4.5, 0.6), Vector3.new(2, 0.5, -0.4), pale, Enum.Material.SmoothPlastic, 0.4)

	-- A faint red glow so players see it coming
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 60, 60)
	glow.Brightness = 1.2
	glow.Range = 14
	glow.Parent = head

	return model
end

-- hotel: the table returned by HotelBuilder.build()
-- onCatch: function(player) called when the ghost catches a player
function Ghost.new(hotel, difficultyName, onCatch)
	local difficulty = Config.Difficulties[difficultyName]

	local self = setmetatable({}, Ghost)
	self.hotel = hotel
	self.onCatch = onCatch
	self.speed = difficulty.GhostSpeed
	self.sightRange = difficulty.GhostSight
	self.hearRange = difficulty.GhostHear
	self.huntChance = difficulty.HuntChance

	self.mode = "patrol" -- "patrol", "chase" or "search"
	self.waypoints = {}
	self.index = 1
	self.idleUntil = nil
	self.computing = false
	self.stopped = false
	self.stunnedUntil = 0
	self.lastSeen = nil
	self.lastSeenAt = 0
	self.lastPatrolPoint = nil

	-- Line-of-sight checks only look at the hotel's walls and furniture
	self.rayParams = RaycastParams.new()
	self.rayParams.FilterType = Enum.RaycastFilterType.Include
	self.rayParams.FilterDescendantsInstances = { hotel.Folder }

	self.model = buildModel(hotel.GhostSpawn + Vector3.new(0, HOVER, 0))
	self.model.Parent = workspace
	return self
end

function Ghost:Start()
	local sinceThink = 0
	self.connection = RunService.Heartbeat:Connect(function(dt)
		if self.stopped then
			return
		end
		sinceThink += dt
		if sinceThink >= Config.GhostThinkInterval then
			sinceThink = 0
			self:_think()
		end
		self:_move(dt)
		self:_checkCatch()
	end)
end

function Ghost:Stop()
	self.stopped = true
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	self.model:Destroy()
end

-- Players who are still in the night and alive
function Ghost:_huntedPlayers()
	local result = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("InRound") then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				table.insert(result, { Player = player, Root = root })
			end
		end
	end
	return result
end

-- Returns the position of the closest player the ghost can see or hear, or nil
function Ghost:_scan()
	local origin = self.model.Head.Position
	local closestPosition = nil
	local closestDistance = math.huge

	for _, entry in self:_huntedPlayers() do
		local target = entry.Root.Position
		local distance = (target - origin).Magnitude
		local noticed = false
		if distance <= self.hearRange then
			noticed = true
		elseif distance <= self.sightRange then
			-- Nothing in the way means a clear line of sight
			noticed = workspace:Raycast(origin, target - origin, self.rayParams) == nil
		end
		if noticed and distance < closestDistance then
			closestDistance = distance
			closestPosition = target
		end
	end
	return closestPosition
end

function Ghost:_pathFinished()
	return self.index > #self.waypoints
end

function Ghost:_pickPatrolPoint()
	-- Sometimes it just goes to where a player is
	if math.random() < self.huntChance then
		local hunted = self:_huntedPlayers()
		if #hunted > 0 then
			return hunted[math.random(#hunted)].Root.Position
		end
	end

	local points = self.hotel.PatrolPoints
	local choice = points[math.random(#points)]
	if choice == self.lastPatrolPoint and #points > 1 then
		choice = points[math.random(#points)]
	end
	self.lastPatrolPoint = choice
	return choice
end

function Ghost:_pathTo(destination)
	self.computing = true
	task.spawn(function()
		local start = self.model:GetPivot().Position
		local path = PathfindingService:CreatePath({
			AgentRadius = 2.2,
			AgentHeight = 6,
			AgentCanJump = false,
		})
		local ok = pcall(function()
			path:ComputeAsync(Vector3.new(start.X, 1, start.Z), Vector3.new(destination.X, 1, destination.Z))
		end)
		if ok and not self.stopped and path.Status == Enum.PathStatus.Success then
			self.waypoints = path:GetWaypoints()
			self.index = math.min(2, #self.waypoints) -- waypoint 1 is where we already are
		end
		self.computing = false
	end)
end

-- Decides what the ghost wants to do. Runs a few times per second.
function Ghost:_think()
	if self.computing or os.clock() < self.stunnedUntil then
		return
	end

	local seenAt = self:_scan()
	local destination = nil

	if seenAt then
		self.mode = "chase"
		self.lastSeen = seenAt
		self.lastSeenAt = os.clock()
		destination = seenAt
	elseif self.mode == "chase" then
		-- Lost sight of them: go and look where they were
		self.mode = "search"
		destination = self.lastSeen
	elseif self.mode == "search" then
		if self:_pathFinished() or os.clock() - self.lastSeenAt > Config.GhostSearchTime then
			self.mode = "patrol"
			self.idleUntil = nil
			self.waypoints = {}
			self.index = 1
		end
	elseif self.mode == "patrol" then
		if self:_pathFinished() then
			if not self.idleUntil then
				-- Arrived somewhere: stand still for a moment
				self.idleUntil = os.clock() + 1.5 + math.random() * 2
			elseif os.clock() >= self.idleUntil then
				self.idleUntil = nil
				destination = self:_pickPatrolPoint()
			end
		end
	end

	if destination then
		self:_pathTo(destination)
	end
end

function Ghost:_move(dt)
	if os.clock() < self.stunnedUntil then
		return
	end
	local waypoint = self.waypoints[self.index]
	if not waypoint then
		return
	end

	local speed = self.speed
	if self.mode == "patrol" then
		speed *= Config.GhostPatrolSpeedScale
	elseif self.mode == "search" then
		speed *= Config.GhostSearchSpeedScale
	end

	local position = self.model:GetPivot().Position
	local target = Vector3.new(waypoint.Position.X, HOVER, waypoint.Position.Z)
	local offset = target - position
	local stepLength = speed * dt

	if offset.Magnitude <= stepLength then
		self.model:PivotTo(CFrame.new(target) * (self.model:GetPivot() - self.model:GetPivot().Position))
		self.index += 1
		return
	end

	local newPosition = position + offset.Unit * stepLength
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude > 0.01 then
		self.model:PivotTo(CFrame.lookAt(newPosition, newPosition + flat))
	else
		self.model:PivotTo(CFrame.new(newPosition) * (self.model:GetPivot() - self.model:GetPivot().Position))
	end
end

function Ghost:_checkCatch()
	if os.clock() < self.stunnedUntil then
		return
	end
	local position = self.model:GetPivot().Position
	for _, entry in self:_huntedPlayers() do
		local offset = entry.Root.Position - position
		if Vector3.new(offset.X, 0, offset.Z).Magnitude <= Config.GhostCatchRange then
			self.stunnedUntil = os.clock() + Config.GhostStunTime
			self.waypoints = {}
			self.index = 1
			self.onCatch(entry.Player)
			return
		end
	end
end

return Ghost
