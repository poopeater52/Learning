-- Ghost (ModuleScript in ServerScriptService)
-- The monster. It wanders the hotel, chases anyone it sees or hears, searches where it last
-- saw you, then goes back to wandering. Break line of sight and get away to lose it, or hide in a cupboard.
--
-- Looks: a gaunt figure in a tattered pale dress with long black hair and too-long arms.
-- Only the invisible Root part is moved. Every visible part hangs off it on a Motor6D, which is
-- re-aimed ~20 times a second to make the dress flutter, the hair sway and the arms reach.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Ghost = {}
Ghost.__index = Ghost

local HOVER = 3.5 -- height of the Root above the floor
local NECK = CFrame.new(0, 3.0, 0) -- where the head joins the body, relative to Root
local POSE_INTERVAL = 0.05 -- seconds between animation updates

local DRESS = Color3.fromRGB(226, 230, 236)
local SKIN = Color3.fromRGB(205, 214, 220)
local HAIR = Color3.fromRGB(12, 10, 12)

local function turnToward(current, target, maxStep)
	local difference = (target - current + math.pi) % (math.pi * 2) - math.pi
	if math.abs(difference) <= maxStep then
		return target
	end
	return current + math.sign(difference) * maxStep
end

local function buildModel(position)
	local model = Instance.new("Model")
	model.Name = "Ghost"

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.new(position)
	root.Parent = model
	model.PrimaryPart = root

	local limbs = {}

	-- Adds one visible part joined to Root by a Motor6D.
	-- attach: the joint position (relative to the body, or to the neck when group is "head")
	-- localOffset: where the part sits relative to the joint
	-- kind: "static", "flutter" (hem and hair sway) or "arm"; param: sway size, or arm side (-1/1)
	local function limb(name, shape, size, attach, localOffset, color, material, transparency, kind, group, param)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = shape
		part.Size = size
		part.Color = color
		part.Material = material
		part.Transparency = transparency
		part.Anchored = false
		part.Massless = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.CFrame = root.CFrame * attach * localOffset
		part.Parent = model

		local motor = Instance.new("Motor6D")
		motor.Part0 = root
		motor.Part1 = part
		motor.C0 = attach * localOffset
		motor.Parent = part

		table.insert(limbs, {
			Motor = motor,
			Attach = attach,
			Local = localOffset,
			Kind = kind,
			Group = group or "body",
			Phase = math.random() * math.pi * 2,
			Param = param or 0,
		})
		return part
	end

	local BLOCK, BALL, CYLINDER = Enum.PartType.Block, Enum.PartType.Ball, Enum.PartType.Cylinder
	local PLASTIC = Enum.Material.SmoothPlastic
	local NONE = CFrame.new()

	-- The dress: three stacked cylinders (a cylinder's axis is X, so turn it upright)
	local function dressPart(name, y, height, diameter, transparency)
		limb(name, CYLINDER, Vector3.new(height, diameter, diameter), NONE, CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), DRESS, PLASTIC, transparency, "static")
	end
	dressPart("Skirt", -1.0, 2.2, 3.4, 0.4)
	dressPart("Waist", 1.0, 1.8, 1.9, 0.35)
	dressPart("Chest", 2.3, 1.0, 2.3, 0.35)

	-- Ragged strips hanging from the hem, fluttering as it moves
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local position2 = Vector3.new(math.cos(angle) * 1.62, -2.0, math.sin(angle) * 1.62)
		local attach = CFrame.lookAt(position2, position2 + Vector3.new(math.cos(angle), 0, math.sin(angle)))
		local length = 1.0 + 0.35 * math.random()
		limb("Hem", BLOCK, Vector3.new(0.5, length, 0.06), attach, CFrame.new(0, -length / 2, 0), DRESS, PLASTIC, 0.5, "flutter", "body", 0.18)
	end

	-- Long, thin arms with a hand and three fingers each
	for _, side in { -1, 1 } do
		local shoulder = CFrame.new(side * 1.3, 2.5, 0)
		limb("Arm", BLOCK, Vector3.new(0.3, 4.4, 0.3), shoulder, CFrame.new(0, -2.2, 0), SKIN, PLASTIC, 0.2, "arm", "body", side)
		limb("Hand", BLOCK, Vector3.new(0.5, 0.7, 0.28), shoulder, CFrame.new(0, -4.7, 0), SKIN, PLASTIC, 0.2, "arm", "body", side)
		for finger = -1, 1 do
			limb("Finger", BLOCK, Vector3.new(0.07, 0.9, 0.07), shoulder, CFrame.new(finger * 0.16, -5.4, 0) * CFrame.Angles(0, 0, -finger * 0.12), SKIN, PLASTIC, 0.15, "arm", "body", side)
		end
	end

	-- Head (turns and tilts on its own). Everything in the "head" group is positioned from the neck.
	local head = limb("Head", BALL, Vector3.new(1.5, 1.5, 1.5), NONE, CFrame.new(0, 0.85, 0), SKIN, PLASTIC, 0.15, "static", "head")
	limb("EyeSocketLeft", BALL, Vector3.new(0.42, 0.42, 0.42), NONE, CFrame.new(-0.3, 1.0, -0.55), Color3.fromRGB(5, 3, 4), PLASTIC, 0, "static", "head")
	limb("EyeSocketRight", BALL, Vector3.new(0.42, 0.42, 0.42), NONE, CFrame.new(0.3, 1.0, -0.55), Color3.fromRGB(5, 3, 4), PLASTIC, 0, "static", "head")
	limb("EyeLeft", BALL, Vector3.new(0.16, 0.16, 0.16), NONE, CFrame.new(-0.3, 1.0, -0.66), Color3.fromRGB(255, 40, 30), Enum.Material.Neon, 0, "static", "head")
	limb("EyeRight", BALL, Vector3.new(0.16, 0.16, 0.16), NONE, CFrame.new(0.3, 1.0, -0.66), Color3.fromRGB(255, 40, 30), Enum.Material.Neon, 0, "static", "head")
	limb("Mouth", BLOCK, Vector3.new(0.5, 0.09, 0.1), NONE, CFrame.new(0, 0.45, -0.62), Color3.fromRGB(5, 3, 4), PLASTIC, 0, "static", "head")

	-- Hair: a cap over the back and top of the head, and long strands that leave the face clear
	limb("HairCap", BALL, Vector3.new(1.7, 1.7, 1.7), NONE, CFrame.new(0, 0.95, 0.2), HAIR, PLASTIC, 0, "static", "head")
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local fromFront = math.abs((angle + math.pi / 2 + math.pi) % (math.pi * 2) - math.pi) -- front is -Z
		if fromFront > 0.9 then
			local position2 = Vector3.new(math.cos(angle) * 0.85, 1.2, math.sin(angle) * 0.85)
			local attach = CFrame.lookAt(position2, position2 + Vector3.new(math.cos(angle), 0, math.sin(angle))) * CFrame.Angles(0.12, 0, 0)
			local length = 3.8 + math.random() * 2
			limb("Hair", BLOCK, Vector3.new(0.3, length, 0.05), attach, CFrame.new(0, -length / 2, 0), HAIR, PLASTIC, 0.05, "flutter", "head", 0.1)
		end
	end

	-- A faint red glow from the head so players see it coming, and a cold pale glow around the body
	local redGlow = Instance.new("PointLight")
	redGlow.Color = Color3.fromRGB(255, 60, 60)
	redGlow.Brightness = 1.0
	redGlow.Range = 12
	redGlow.Parent = head

	local coldGlow = Instance.new("PointLight")
	coldGlow.Color = Color3.fromRGB(170, 200, 255)
	coldGlow.Brightness = 0.5
	coldGlow.Range = 10
	coldGlow.Parent = root

	-- Cold mist trailing behind it
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Rate = 14
	mist.Lifetime = NumberRange.new(1.6, 2.6)
	mist.Speed = NumberRange.new(0.2, 0.8)
	mist.Drag = 1
	mist.Acceleration = Vector3.new(0, 0.4, 0)
	mist.LightEmission = 0.15
	mist.Color = ColorSequence.new(Color3.fromRGB(190, 205, 225))
	mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5) })
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.82),
		NumberSequenceKeypoint.new(1, 1),
	})
	mist.Parent = root

	return model, root, limbs
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

	local model, root, limbs = buildModel(hotel.GhostSpawn + Vector3.new(0, HOVER, 0))
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
	local bodyBase = CFrame.Angles(self.lean, 0, 0)
	local headBase = bodyBase * NECK * CFrame.Angles(self.headPitch, self.headYaw, math.sin(now * 0.7) * 0.05)
	local flutterScale = 1 + self.speedNow * 0.1

	for _, limb in self.limbs do
		local base = limb.Group == "head" and headBase or bodyBase
		local rotation = CFrame.new()
		if limb.Kind == "flutter" then
			rotation = CFrame.Angles(
				math.sin(now * 1.9 + limb.Phase) * limb.Param * flutterScale,
				0,
				math.cos(now * 1.4 + limb.Phase) * limb.Param * 0.5 * flutterScale
			)
		elseif limb.Kind == "arm" then
			rotation = CFrame.Angles(
				self.reach * 1.3 + math.sin(now * 1.1 + limb.Phase) * 0.06,
				0,
				limb.Param * (0.14 + math.sin(now * 0.9 + limb.Phase) * 0.04)
			)
		end
		limb.Motor.C0 = base * limb.Attach * rotation * limb.Local
	end
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
