-- GameManager (Script in ServerScriptService)
-- Runs the whole game: builds the lobby, lets players vote on a difficulty, builds the hotel,
-- hands out keys, wakes the ghost, and decides who escaped.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local HotelBuilder = require(script.Parent:WaitForChild("HotelBuilder"))
local Ghost = require(script.Parent:WaitForChild("Ghost"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

Players.RespawnTime = 4

-- Messages to the players' screens ---------------------------------------------

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local JumpScare = makeRemote("JumpScare")
local Notify = makeRemote("Notify") -- Notify:FireClient(player, text, color)
local Cutscene = makeRemote("Cutscene") -- Cutscene:FireClient(player, relicText, color): the "You Escaped" cutscene
local FlashlightToggle = makeRemote("FlashlightToggle") -- the client asks to turn its torch on or off

-- The HUD reads everything about the current night from attributes on this folder.
local state = Instance.new("Folder")
state.Name = "GameState"
state.Parent = ReplicatedStorage

local function setState(values)
	for key, value in values do
		state:SetAttribute(key, value)
	end
end

setState({ Status = "Intermission", Message = "Loading...", Countdown = 0, KeysFound = 0, KeysNeeded = 0, Difficulty = "" })

FlashlightToggle.OnServerEvent:Connect(function(player, on)
	if typeof(on) ~= "boolean" then
		return
	end
	if on and (player:GetAttribute("Battery") or 0) <= 0 then
		return -- a dead torch can't be switched on
	end
	player:SetAttribute("FlashlightOn", on)
end)

-- Lighting: very dark, the flashlight and the lamps do the rest -----------------

Lighting.ClockTime = 0
Lighting.Brightness = 0
Lighting.Ambient = Color3.fromRGB(14, 14, 22)
Lighting.OutdoorAmbient = Color3.fromRGB(14, 14, 22)
Lighting.FogColor = Color3.fromRGB(8, 8, 12)
Lighting.FogStart = 20
Lighting.FogEnd = 160
Lighting.GlobalShadows = true

-- Lobby --------------------------------------------------------------------------

-- Remove the default baseplate and spawn so players only ever spawn in our lobby.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end
for _, descendant in workspace:GetDescendants() do
	if descendant:IsA("SpawnLocation") then
		descendant:Destroy()
	end
end

local function buildLobby()
	local center = Config.LobbyCenter
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = workspace

	local function part(name, size, position, color, material, transparency)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.Position = position
		p.Color = color
		p.Material = material
		p.Transparency = transparency or 0
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = folder
		return p
	end

	part("Floor", Vector3.new(70, 1, 70), center - Vector3.new(0, 0.5, 0), Color3.fromRGB(45, 32, 28), Enum.Material.WoodPlanks)

	-- Invisible walls so nobody falls off the edge
	for _, wall in {
		{ Vector3.new(70, 40, 1), Vector3.new(0, 20, -35.5) },
		{ Vector3.new(70, 40, 1), Vector3.new(0, 20, 35.5) },
		{ Vector3.new(1, 40, 72), Vector3.new(-35.5, 20, 0) },
		{ Vector3.new(1, 40, 72), Vector3.new(35.5, 20, 0) },
	} do
		part("EdgeWall", wall[1], center + wall[2], Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, 1)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = center + Vector3.new(0, 0.5, 22)
	spawn.Color = Color3.fromRGB(70, 50, 40)
	spawn.Material = Enum.Material.Wood
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = folder

	-- Title sign on the far wall (faces +Z, toward the players)
	local sign = part("TitleSign", Vector3.new(44, 12, 1), center + Vector3.new(0, 10, -34), Color3.fromRGB(20, 14, 14), Enum.Material.Wood)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back
	signGui.PixelsPerStud = 30
	signGui.Parent = sign
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.65)
	title.BackgroundTransparency = 1
	title.Text = "THE LAST GUEST"
	title.TextColor3 = Color3.fromRGB(215, 40, 40)
	title.TextScaled = true
	title.Font = Enum.Font.Creepster
	title.Parent = signGui
	local subtitle = Instance.new("TextLabel")
	subtitle.Position = UDim2.fromScale(0, 0.65)
	subtitle.Size = UDim2.fromScale(1, 0.25)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Stand on a door to vote. Find the keys. Escape the night."
	subtitle.TextColor3 = Color3.fromRGB(220, 200, 170)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.SpecialElite
	subtitle.Parent = signGui

	-- Lamps so the lobby isn't pitch black
	for _, x in { -22, 0, 22 } do
		local lamp = part("Lamp", Vector3.new(3, 0.5, 3), center + Vector3.new(x, 18, -4), Color3.fromRGB(255, 226, 170), Enum.Material.Neon)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 205, 140)
		light.Brightness = 1.5
		light.Range = 40
		light.Parent = lamp
	end

	-- Difficulty vote pads
	local pads = {}
	local labels = {}
	for index, name in Config.DifficultyOrder do
		local difficulty = Config.Difficulties[name]
		local pad = part(name .. "Pad", Vector3.new(14, 0.4, 14), center + Vector3.new((index - 2) * 22, 0.2, -12), difficulty.Color, Enum.Material.Neon)
		pads[name] = pad

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(240, 100)
		billboard.StudsOffset = Vector3.new(0, 7, 0)
		billboard.Parent = pad
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = difficulty.Color
		label.TextStrokeTransparency = 0.3
		label.TextScaled = true
		label.Font = Enum.Font.Creepster
		label.Parent = billboard
		labels[name] = label
	end

	return {
		SpawnPosition = spawn.Position + Vector3.new(0, 3, 0),
		Pads = pads,
		Labels = labels,
	}
end

local lobby = buildLobby()

local function sendToLobby(player)
	local character = player.Character
	if character and character.Parent then
		character:PivotTo(CFrame.new(lobby.SpawnPosition))
	end
end

-- Voting -------------------------------------------------------------------------

local function countVotes()
	local votes = {}
	for _, name in Config.DifficultyOrder do
		votes[name] = 0
	end

	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			for name, pad in lobby.Pads do
				local offset = root.Position - pad.Position
				if math.abs(offset.X) <= pad.Size.X / 2 and math.abs(offset.Z) <= pad.Size.Z / 2 and math.abs(offset.Y) < 8 then
					votes[name] += 1
					break
				end
			end
		end
	end
	return votes
end

local function updateVoteLabels()
	local votes = countVotes()
	for _, name in Config.DifficultyOrder do
		local difficulty = Config.Difficulties[name]
		lobby.Labels[name].Text = string.format("%s\n%d keys - %d votes", string.upper(name), difficulty.Keys, votes[name])
	end
	return votes
end

local function pickDifficulty()
	local votes = updateVoteLabels()
	local best = 0
	for _, count in votes do
		best = math.max(best, count)
	end
	if best == 0 then
		return "Normal"
	end

	local tied = {}
	for _, name in Config.DifficultyOrder do
		if votes[name] == best then
			table.insert(tied, name)
		end
	end
	return tied[math.random(#tied)]
end

local function intermission()
	while true do
		while #Players:GetPlayers() < Config.MinPlayers do
			setState({ Status = "Intermission", Countdown = 0, Message = "Waiting for players..." })
			updateVoteLabels()
			task.wait(1)
		end

		local aborted = false
		for secondsLeft = Config.IntermissionTime, 1, -1 do
			if #Players:GetPlayers() < Config.MinPlayers then
				aborted = true
				break
			end
			setState({ Status = "Intermission", Countdown = secondsLeft, Message = "Stand on a door to vote for the difficulty" })
			updateVoteLabels()
			task.wait(0.5)
			updateVoteLabels()
			task.wait(0.5)
		end

		if not aborted then
			return pickDifficulty()
		end
	end
end

-- A night ---------------------------------------------------------------------------

local inRound = {} -- [Player] = true while that player is still in the hotel and alive
local hiding = {} -- [Player] = the cupboard they are hiding in

-- Lets a hiding player out: unfreezes them and swings the doors open.
local function leaveCupboard(player)
	local cupboard = hiding[player]
	if not cupboard then
		return
	end
	hiding[player] = nil
	cupboard.Occupant = nil
	cupboard.Suspected = false
	if cupboard.Prompt and cupboard.Prompt.Parent then
		cupboard.Prompt.ActionText = "Hide"
	end
	player:SetAttribute("Hidden", false)

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = false
	end

	cupboard.SetOpen(true)
	task.delay(3, function()
		if not cupboard.Occupant then
			cupboard.SetOpen(false)
		end
	end)
end

local function markOut(player)
	leaveCupboard(player)
	if inRound[player] then
		inRound[player] = nil
		player:SetAttribute("InRound", false)
	end
end

Players.PlayerRemoving:Connect(function(player)
	hiding[player] = nil
	inRound[player] = nil
end)

local function shuffledIndices(count)
	local list = {}
	for i = 1, count do
		list[i] = i
	end
	for i = count, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

local GREY = Color3.fromRGB(200, 205, 215)
local RED = Color3.fromRGB(235, 80, 80)
local GOLD = Color3.fromRGB(255, 215, 100)

local function runRound(difficultyName)
	local difficulty = Config.Difficulties[difficultyName]

	-- Who is playing: everyone alive right now
	local participants = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart") then
			table.insert(participants, player)
		end
	end
	if #participants == 0 then
		return
	end

	table.clear(inRound)
	local connections = {}
	local roundActive = true
	local ghost = nil
	local keysFound = 0
	local exitOpen = false
	local escapedCount = 0

	local hotel = HotelBuilder.build()
	hotel.Folder.Parent = workspace

	for index, player in participants do
		local character = player.Character
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		humanoid.WalkSpeed = Config.PlayerWalkSpeed

		local position = hotel.PlayerSpawns[(index - 1) % #hotel.PlayerSpawns + 1]
		character:PivotTo(CFrame.lookAt(position, position + Vector3.new(1, 0, 0)))

		inRound[player] = true
		player:SetAttribute("InRound", true)
		player:SetAttribute("Battery", 100)
		player:SetAttribute("FlashlightOn", true)
		table.insert(
			connections,
			humanoid.Died:Connect(function()
				markOut(player)
			end)
		)
	end

	setState({
		Status = "Playing",
		Difficulty = difficultyName,
		KeysFound = 0,
		KeysNeeded = difficulty.Keys,
		Countdown = difficulty.TimeLimit,
		Message = "Find the keys to unlock the exit",
	})

	local function notifyPlayers(text, color)
		for _, player in participants do
			if player.Parent then
				Notify:FireClient(player, text, color)
			end
		end
	end

	notifyPlayers("Night begins on " .. difficultyName .. ". Press F for your flashlight, but its battery drains. Cupboards are hiding spots.", GREY)

	-- Keys: old brass keys lying on tables and beds in several random rooms
	local allSpots = {}
	for _, roomSpots in hotel.KeySpots do
		for _, spot in roomSpots do
			table.insert(allSpots, spot)
		end
	end
	local spotOrder = shuffledIndices(#allSpots)
	local nextSpot = 0
	local function takeSpot() -- each spot is used by at most one key or battery
		nextSpot += 1
		return allSpots[spotOrder[nextSpot]]
	end

	for k = 1, difficulty.Keys do
		local spot = takeSpot()

		local key = HotelBuilder.newKey()
		key:PivotTo(CFrame.new(spot) * CFrame.Angles(0, math.random() * math.pi * 2, 0))

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pick up"
		prompt.ObjectText = "Old Brass Key"
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = key.PrimaryPart

		local collected = false
		prompt.Triggered:Connect(function(player)
			if collected or not inRound[player] or hiding[player] then
				return
			end
			collected = true
			key:Destroy()
			keysFound += 1
			state:SetAttribute("KeysFound", keysFound)
			notifyPlayers(player.DisplayName .. " found a key (" .. keysFound .. "/" .. difficulty.Keys .. ")", GOLD)

			if keysFound >= difficulty.Keys then
				exitOpen = true
				hotel.OpenExit()
				state:SetAttribute("Message", "The exit is open - RUN!")
				notifyPlayers("The exit door is unlocked! Get to the green light!", Color3.fromRGB(110, 255, 140))
			end
		end)
		key.Parent = hotel.Folder
	end

	-- Batteries: the torch drains while it is on, so batteries lie around the hotel too
	for _ = 1, difficulty.Batteries do
		local spot = takeSpot()
		local battery = HotelBuilder.newBattery()
		battery:PivotTo(CFrame.new(spot + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0))

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pick up"
		prompt.ObjectText = "Battery"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = battery.PrimaryPart

		local collected = false
		prompt.Triggered:Connect(function(player)
			if collected or not inRound[player] or hiding[player] then
				return
			end
			collected = true
			battery:Destroy()
			local before = player:GetAttribute("Battery") or 0
			local level = math.min(100, before + Config.BatteryPickup)
			player:SetAttribute("Battery", level)
			if before <= 0 then
				player:SetAttribute("FlashlightOn", true) -- bring a dead torch back to life
			end
			Notify:FireClient(player, string.format("Battery found! Flashlight at %d%%", math.floor(level)), GOLD)
		end)
		battery.Parent = hotel.Folder
	end

	-- Cupboards: climb in to hide. The doors shut and the ghost can't see you through them.
	-- It may still open one it passes, and it always checks the one it saw you go into.
	for _, cupboard in hotel.Cupboards do
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Hide"
		prompt.ObjectText = "Cupboard"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 7
		prompt.RequiresLineOfSight = false
		prompt.Parent = cupboard.OpenPoint
		cupboard.Prompt = prompt

		prompt.Triggered:Connect(function(player)
			if not inRound[player] then
				return
			end
			if cupboard.Occupant == player then
				leaveCupboard(player)
			elseif cupboard.Occupant then
				Notify:FireClient(player, "Someone is already hiding in here.", GREY)
			elseif not hiding[player] then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if not root then
					return
				end
				cupboard.Suspected = false
				cupboard.Occupant = player
				cupboard.NextCheck = os.clock() + 1.5
				hiding[player] = cupboard
				cupboard.SetOpen(false)
				player.Character:PivotTo(cupboard.HidePosition)
				root.AssemblyLinearVelocity = Vector3.zero
				root.Anchored = true
				player:SetAttribute("Hidden", true)
				prompt.ActionText = "Leave"
				if ghost then
					ghost:OnPlayerHid(player, cupboard)
				end
			end
		end)
	end

	-- The ghost wakes up after a short calm
	local function onCatch(player)
		if not inRound[player] then
			return
		end
		markOut(player)
		JumpScare:FireClient(player)
		notifyPlayers(player.DisplayName .. " was caught!", RED)
		task.delay(0.7, function()
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end)
	end

	task.delay(Config.GhostWakeDelay, function()
		if roundActive then
			ghost = Ghost.new(hotel, difficultyName, onCatch)
			ghost:Start()
			notifyPlayers("Something stirs in the hotel...", RED)
		end
	end)

	-- Main loop of the night
	local endTime = os.clock() + difficulty.TimeLimit
	local result
	local lastTick = os.clock()
	while true do
		task.wait(0.25)
		local dt = os.clock() - lastTick
		lastTick = os.clock()

		-- The torch drains while it is switched on (not while you are hiding)
		for _, player in participants do
			if inRound[player] and not hiding[player] and player:GetAttribute("FlashlightOn") then
				local before = player:GetAttribute("Battery") or 0
				if before > 0 then
					local after = math.max(0, math.floor((before - 100 / difficulty.BatterySeconds * dt) * 10) / 10)
					player:SetAttribute("Battery", after)
					if before > Config.LowBattery and after <= Config.LowBattery then
						Notify:FireClient(player, "Flashlight battery is low!", RED)
					end
					if after <= 0 then
						player:SetAttribute("FlashlightOn", false)
						Notify:FireClient(player, "Your flashlight died. Find a battery...", RED)
					end
				end
			end
		end

		local timeLeft = math.ceil(endTime - os.clock())
		state:SetAttribute("Countdown", math.max(timeLeft, 0))

		-- Anyone past the exit line (once the door is open) has escaped
		if exitOpen then
			for _, player in participants do
				if inRound[player] and player.Parent then
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if root and root.Position.X > hotel.ExitX then
						markOut(player)
						escapedCount += 1
						sendToLobby(player)
						PlayerData.RecordEscape(player)

						local lines = {}
						local bestColor = Config.Rarities.Common.Color
						for _ = 1, difficulty.RelicRolls do
							local relic = Config.RollRelic(difficultyName)
							if PlayerData.AwardRelic(player, relic.Id) then
								table.insert(lines, relic.Name .. " (" .. relic.Rarity .. ")")
								bestColor = Config.Rarities[relic.Rarity].Color
							end
						end
						local relicText = ""
						if #lines > 0 then
							relicText = "Relics found: " .. table.concat(lines, ", ")
						end
						-- The cutscene plays on their screen; the toast follows once it has finished
						Cutscene:FireClient(player, relicText, bestColor)
						task.delay(Config.CutsceneTime, function()
							if player.Parent then
								Notify:FireClient(player, "You escaped! " .. relicText, bestColor)
							end
						end)
					end
				end
			end
		end

		local remaining = 0
		for _, player in participants do
			if inRound[player] and player.Parent then
				remaining += 1
			end
		end

		if remaining == 0 then
			result = escapedCount > 0 and "escaped" or "wipe"
			break
		elseif timeLeft <= 0 then
			result = "timeout"
			break
		end
	end

	-- End of the night
	roundActive = false
	task.wait(1)
	if ghost then
		ghost:Stop()
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	for _, player in participants do
		leaveCupboard(player)
		player:SetAttribute("Battery", nil)
		player:SetAttribute("FlashlightOn", nil)
		if inRound[player] then
			markOut(player)
			sendToLobby(player)
		end
	end
	hotel.Folder:Destroy()

	local message
	if result == "escaped" then
		message = string.format("%d of %d escaped the hotel!", escapedCount, #participants)
	elseif result == "timeout" then
		message = "Time's up. The hotel keeps whoever is left."
	else
		message = "Nobody escaped. The hotel keeps its guests."
	end

	setState({ Status = "Ending", Message = message, KeysFound = 0, KeysNeeded = 0 })
	for secondsLeft = Config.EndScreenTime, 1, -1 do
		state:SetAttribute("Countdown", secondsLeft)
		task.wait(1)
	end
end

-- If a night crashes for any reason, clean up and carry on instead of freezing the game.
local function recoverFromError()
	local leftover = workspace:FindFirstChild("Hotel")
	if leftover then
		leftover:Destroy()
	end
	local ghost = workspace:FindFirstChild("Ghost")
	if ghost then
		ghost:Destroy()
	end
	table.clear(inRound)
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			root.Anchored = false
		end
		hiding[player] = nil
		player:SetAttribute("Battery", nil)
		player:SetAttribute("FlashlightOn", nil)
		player:SetAttribute("Hidden", false)
		player:SetAttribute("InRound", false)
		sendToLobby(player)
	end
end

while true do
	local difficultyName = intermission()
	local ok, err = pcall(runRound, difficultyName)
	if not ok then
		warn("[TheLastGuest] The night crashed: " .. tostring(err))
		recoverFromError()
		task.wait(3)
	end
end
