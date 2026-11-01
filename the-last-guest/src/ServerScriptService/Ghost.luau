-- Ghost (ModuleScript in ServerScriptService)
-- The monster. It wanders the hotel, chases anyone it sees or hears, searches where it last
-- saw you, then goes back to wandering. Break line of sight and get away to lose it, or hide in a cupboard.
--
-- Its body (dress, hair, arms) is built by the GhostModel module, which the escape cutscene shares.
-- This file decides where the ghost goes and what it does.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local GhostModel = require(ReplicatedStorage:WaitForChild("GhostModel"))

local Ghost = {}
Ghost.__index = Ghost

local HOVER = 3.5 -- height of the Root above the floor
local POSE_INTERVAL = 0.05 -- seconds between animation updates


local function turnToward(current, target, maxStep)
	local difference = (target - current + math.pi) % (math.pi * 2) - math.pi
	if math.abs(difference) <= maxStep then
		return target
	end
	return current + math.sign(difference) * maxStep
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
	self.hideCheckChance = difficulty.HideCheckChance

	self.mode = "patrol" -- "patrol", "chase" or "search"
	self.waypoints = {}
	self.index = 1
	self.idleUntil = nil
	self.computing = false
	self.stopped = false
	self.stunnedUntil = 0
	self.noticeUntil = 0 -- brief freeze when it first spots someone
	self.lastSeen = nil
	self.lastSeenAt = 0
	self.visitedAt = {} -- [patrol point index] = when it last went there

	-- Movement and pose
	self.speedNow = 0
	self.yaw = 0
	self.targetYaw = 0
	self.frenzy = 1 -- grows the longer a chase lasts
	self.lean = 0
	self.reach = 0.1
	self.headYaw = 0
	self.headPitch = 0
	self.poseClock = 0
	self.presenceClock = 0
	self.dimmedLights = {}

	-- Line-of-sight checks only look at the hotel's walls and furniture
	self.rayParams = RaycastParams.new()
	self.rayParams.FilterType = Enum.RaycastFilterType.Include
	self.rayParams.FilterDescendantsInstances = { hotel.Folder }

	local model, root, limbs = GhostModel.build(hotel.GhostSpawn + Vector3.new(0, HOVER, 0))
	self.model = model
	self.root = root
	self.limbs = limbs
	self.model:SetAttribute("Mode", self.mode) -- the music reads this on the client
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
		self:_animate(dt)
		self:_checkCatch()
	end)
end

function Ghost:Stop()
	self.stopped = true
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	for light in self.dimmedLights do
		if light.Parent then
			light.Brightness = light:GetAttribute("BaseBrightness")
		end
	end
	self.model:Destroy()
end

-- Players who are still in the night, alive and not hidden
function Ghost:_huntedPlayers()
	local result = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("InRound") and not player:GetAttribute("Hidden") then
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
		-- A dark player is harder to spot: the torch makes you easier to see
		local player = entry.Player
		local dark = player:GetAttribute("FlashlightOn") == false or (player:GetAttribute("Battery") or 100) <= 0
		local sightRange = dark and self.sightRange * Config.DarkSightScale or self.sightRange

		local noticed = false
		if distance <= self.hearRange then
			noticed = true
		elseif distance <= sightRange then
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

-- Called when a player climbs into a cupboard. If the ghost is chasing them right now, it saw them go in.
function Ghost:OnPlayerHid(player, cupboard)
	if self.mode == "chase" then
		local offset = cupboard.Center - self.root.Position
		if Vector3.new(offset.X, 0, offset.Z).Magnitude <= self.sightRange then
			cupboard.Suspected = true
			self.lastSeen = cupboard.Center
			self.lastSeenAt = os.clock()
		end
	end
end

-- If the ghost is near a cupboard with someone inside, it may open it. It always opens the one
-- it saw you climb into; any other has only a chance (HideCheckChance) each time it passes.
function Ghost:_checkCupboards()
	local position = self.root.Position
	for _, cupboard in self.hotel.Cupboards do
		local occupant = cupboard.Occupant
		if occupant and os.clock() >= cupboard.NextCheck then
			local offset = cupboard.Center - position
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= Config.HideCheckRadius then
				cupboard.NextCheck = os.clock() + Config.HideCheckCooldown
				if cupboard.Suspected or math.random() < self.hideCheckChance then
					cupboard.SetOpen(true)
					self.stunnedUntil = os.clock() + Config.GhostStunTime
					self.waypoints = {}
					self.index = 1
					self.onCatch(occupant)
					return true
				end
			end
		end
	end
	return false
end

function Ghost:_pathFinished()
	return self.index > #self.waypoints
end

-- Chooses where to wander next. It prefers places it hasn't been for a while, so it covers the
-- whole hotel instead of looping around the same few rooms.
function Ghost:_pickPatrolPoint()
	-- Sometimes it just goes to where a player is
	if math.random() < self.huntChance then
		local hunted = self:_huntedPlayers()
		if #hunted > 0 then
			return hunted[math.random(#hunted)].Root.Position
		end
	end

	local points = self.hotel.PatrolPoints
	local keys = {}
	local order = {}
	for i = 1, #points do
		keys[i] = (self.visitedAt[i] or 0) + math.random() * 8 -- a little randomness so ties break differently each time
		order[i] = i
	end
	table.sort(order, function(a, b)
		return keys[a] < keys[b]
	end)

	local choice = order[math.random(math.min(4, #order))]
	self.visitedAt[choice] = os.clock()
	return points[choice]
end

function Ghost:_pathTo(destination)
	self.computing = true
	task.spawn(function()
		local start = self.root.Position
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

-- It has just spotted someone: stop, turn to face them and reach out for a moment before the chase.
function Ghost:_notice(position)
	self.noticeUntil = os.clock() + Config.GhostNoticeTime
	self.waypoints = {}
	self.index = 1
	self.frenzy = 1
	local offset = position - self.root.Position
	self.targetYaw = math.atan2(-offset.X, -offset.Z)
end

-- Decides what the ghost wants to do. Runs a few times per second.
function Ghost:_think()
	if self.computing or os.clock() < self.stunnedUntil then
		return
	end
	if self:_checkCupboards() then
		return
	end

	local seenAt = self:_scan()
	local destination = nil

	if seenAt then
		if self.mode ~= "chase" then
			self:_notice(seenAt)
		end
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
				-- Arrived somewhere: stand still and listen for a moment
				self.idleUntil = os.clock() + 1.5 + math.random() * 2
			elseif os.clock() >= self.idleUntil then
				self.idleUntil = nil
				destination = self:_pickPatrolPoint()
			end
		end
	end

	self.model:SetAttribute("Mode", self.mode)

	if destination then
		self:_pathTo(destination)
	end
end

function Ghost:_move(dt)
	local now = os.clock()
	local frozen = now < self.stunnedUntil or now < self.noticeUntil
	local waypoint = self.waypoints[self.index]

	-- How fast it wants to go
	local target = 0
	if waypoint and not frozen then
		target = self.speed
		if self.mode == "patrol" then
			target *= Config.GhostPatrolSpeedScale
		elseif self.mode == "search" then
			target *= Config.GhostSearchSpeedScale
		else
			target *= self.frenzy
		end
	end

	-- Speed up gradually, slow down faster
	local rate = (target > self.speedNow and Config.GhostAcceleration or Config.GhostAcceleration * 2) * dt
	if math.abs(target - self.speedNow) <= rate then
		self.speedNow = target
	else
		self.speedNow += math.sign(target - self.speedNow) * rate
	end

	-- Chasing makes it frantic: faster and faster the longer it stays on you
	if self.mode == "chase" and not frozen then
		self.frenzy = math.min(Config.GhostFrenzyMax, self.frenzy + Config.GhostFrenzyRate * dt)
	elseif self.mode ~= "chase" then
		self.frenzy = 1
	end

	local position = self.root.Position
	local flat = Vector3.new(position.X, 0, position.Z)

	if waypoint and self.speedNow > 0.01 then
		local goal = Vector3.new(waypoint.Position.X, 0, waypoint.Position.Z)
		local offset = goal - flat
		local step = self.speedNow * dt
		if offset.Magnitude <= step then
			flat = goal
			self.index += 1
		else
			flat += offset.Unit * step
			self.targetYaw = math.atan2(-offset.X, -offset.Z) -- -Z is "forward"
		end
	end

	-- Turn smoothly instead of snapping round
	local turnRate = (self.mode == "chase") and 7 or 2.2
	self.yaw = turnToward(self.yaw, self.targetYaw, turnRate * dt)

	local bob = 0.18 * math.sin(now * 2.3)
	self.root.CFrame = CFrame.new(flat.X, HOVER + bob, flat.Z) * CFrame.Angles(0, self.yaw, 0)
end

-- Body language, and the lights that go dim when it is near
function Ghost:_animate(dt)
	local now = os.clock()
	local chasing = self.mode == "chase"
	local noticing = now < self.noticeUntil

	local targetLean, targetReach
	if noticing then
		targetLean, targetReach = -0.05, 1.0 -- rears up and reaches
	elseif chasing then
		targetLean, targetReach = -0.32, 0.85
	elseif self.mode == "search" then
		targetLean, targetReach = -0.14, 0.35
	else
		targetLean, targetReach = -0.04, 0.12
	end
	local blend = math.min(1, dt * 4)
	self.lean += (targetLean - self.lean) * blend
	self.reach += (targetReach - self.reach) * blend

	-- Head: slowly scans left and right when standing still, locks on when hunting
	local targetHeadYaw, targetHeadPitch = 0, 0
	if not chasing and not noticing and self.speedNow < 0.5 then
		targetHeadYaw = math.sin(now * 0.6) * 0.9
		targetHeadPitch = 0.1
	elseif noticing then
		targetHeadPitch = -0.2
	end
	self.headYaw += (targetHeadYaw - self.headYaw) * blend
	self.headPitch += (targetHeadPitch - self.headPitch) * blend

	self.poseClock += dt
	if self.poseClock >= POSE_INTERVAL then
		self.poseClock = 0
		self:_pose(now)
	end

	self.presenceClock += dt
	if self.presenceClock >= 0.1 then
		self.presenceClock = 0
		self:_flickerNearbyLights()
	end
end

function Ghost:_pose(now)
	GhostModel.pose(self.limbs, {
		Lean = self.lean,
		Reach = self.reach,
		HeadYaw = self.headYaw,
		HeadPitch = self.headPitch,
		Speed = self.speedNow,
		Wave = 0,
	}, now)
end

-- Lamps near the ghost stutter and dim: a warning you can see before you see it
function Ghost:_flickerNearbyLights()
	local position = self.root.Position
	for _, light in self.hotel.Lights do
		local lamp = light.Parent
		if lamp then
			local distance = (lamp.Position - position).Magnitude
			local base = light:GetAttribute("BaseBrightness")
			if distance < Config.GhostPresenceRadius then
				local closeness = 1 - distance / Config.GhostPresenceRadius
				if math.random() < 0.4 * closeness then
					light.Brightness = base * math.random() * 0.25
				else
					light.Brightness = base * (1 - 0.5 * closeness)
				end
				self.dimmedLights[light] = true
			elseif self.dimmedLights[light] then
				light.Brightness = base
				self.dimmedLights[light] = nil
			end
		end
	end
end

function Ghost:_checkCatch()
	if os.clock() < self.stunnedUntil then
		return
	end
	local position = self.root.Position
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
