-- HotelBuilder (ModuleScript in ServerScriptService)
-- Builds one floor of the haunted hotel out of parts, so you don't have to model anything.
-- A long corridor runs west -> east. Rooms sit on both sides. The locked exit is at the east end.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local HotelBuilder = {}

local WALL_COLOR = Color3.fromRGB(78, 52, 52)
local FLOOR_COLOR = Color3.fromRGB(58, 40, 30)
local CARPET_COLOR = Color3.fromRGB(95, 22, 28)
local CEILING_COLOR = Color3.fromRGB(40, 32, 30)
local WOOD_COLOR = Color3.fromRGB(88, 58, 36)

local function newPart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addLamp(parent, position, brightness, range, lights)
	local lamp = newPart(parent, "Lamp", Vector3.new(2, 0.3, 2), CFrame.new(position), Color3.fromRGB(255, 226, 170), Enum.Material.Neon)
	lamp.CanCollide = false

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 205, 140)
	light.Brightness = brightness
	light.Range = range
	light.Shadows = true
	light:SetAttribute("BaseBrightness", brightness)
	light.Parent = lamp
	table.insert(lights, light)
end

local function addLabel(part, face, text, textColor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.PixelsPerStud = 40
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.TextScaled = true
	label.Font = Enum.Font.SpecialElite
	label.Parent = gui
end

local CUPBOARD_COLOR = Color3.fromRGB(70, 44, 30)
local DOOR_COLOR = Color3.fromRGB(84, 54, 36)

-- A walk-in cupboard against a room's back wall, facing the corridor. Players hide inside it.
-- Its two doors close behind the player, with a narrow slit at eye height to peek through.
-- side: 1 = north rooms, -1 = south rooms. backZ: distance of the back wall from the corridor centre.
local function buildCupboard(parent, cx, side, backZ)
	local function panel(name, size, x, y, depth)
		return newPart(parent, name, size, CFrame.new(x, y, side * (backZ - depth)), CUPBOARD_COLOR, Enum.Material.Wood)
	end
	panel("CupboardBack", Vector3.new(6, 9, 0.3), cx, 4.5, 0.15)
	panel("CupboardSide", Vector3.new(0.3, 9, 3), cx - 2.85, 4.5, 1.5)
	panel("CupboardSide", Vector3.new(0.3, 9, 3), cx + 2.85, 4.5, 1.5)
	panel("CupboardTop", Vector3.new(6, 0.3, 3), cx, 8.85, 1.5)
	panel("CupboardBottom", Vector3.new(6, 0.3, 3), cx, 0.15, 1.5)

	-- Two doors hinged on their outer edges. Each door is two pieces with a gap (the peek slit) between them.
	local doorZ = side * (backZ - 3.13)
	local hingeY = 4.5
	local pieces = {}
	local doorSpecs = {
		{ hingeX = cx - 2.95, offset = 1.475, dir = side },
		{ hingeX = cx + 2.95, offset = -1.475, dir = -side },
	}
	local pieceSpecs = {
		{ centerY = 2.4, height = 4.4 }, -- below the slit (the slit runs from y 4.6 to 5.5, about eye height)
		{ centerY = 7.05, height = 3.1 }, -- above the slit
	}
	for _, door in doorSpecs do
		for _, piece in pieceSpecs do
			local part = newPart(
				parent,
				"CupboardDoor",
				Vector3.new(2.95, piece.height, 0.25),
				CFrame.new(door.hingeX + door.offset, piece.centerY, doorZ),
				DOOR_COLOR,
				Enum.Material.Wood
			)
			-- Put the part's pivot on the hinge, so PivotTo swings it like a real door
			part.PivotOffset = CFrame.new(-door.offset, hingeY - piece.centerY, 0)
			table.insert(pieces, { Part = part, Hinge = Vector3.new(door.hingeX, hingeY, doorZ), Dir = door.dir })
		end
	end

	-- Invisible spot in front of the doors that the "Hide" prompt attaches to
	local openPoint = newPart(parent, "OpenPoint", Vector3.new(2, 2, 0.5), CFrame.new(cx, 4.5, side * (backZ - 3.6)), CUPBOARD_COLOR, Enum.Material.Wood)
	openPoint.Transparency = 1
	openPoint.CanCollide = false
	openPoint.CanQuery = false

	local insideZ = side * (backZ - 1.7)
	local cupboard = {
		OpenPoint = openPoint,
		Center = Vector3.new(cx, 0, insideZ), -- floor position inside, used for distance checks
		HidePosition = CFrame.lookAt(Vector3.new(cx, 3.3, insideZ), Vector3.new(cx, 3.3, insideZ - side * 5)), -- where a hiding player stands, facing out
		Occupant = nil, -- the player hiding inside, if any
		Suspected = false, -- true if the ghost saw someone climb in
		NextCheck = 0, -- the ghost won't check this cupboard again before this time
		IsOpen = false,
	}

	local openAmount = 0 -- 0 = shut, 1 = wide open
	local token = 0

	local function apply(amount)
		for _, piece in pieces do
			piece.Part:PivotTo(CFrame.new(piece.Hinge) * CFrame.Angles(0, piece.Dir * math.rad(105) * amount, 0))
		end
	end

	function cupboard.SetOpen(open)
		if cupboard.IsOpen == open then
			return
		end
		cupboard.IsOpen = open
		token += 1
		local myToken = token
		task.spawn(function()
			local from = openAmount
			local to = open and 1 or 0
			local steps = 14
			for step = 1, steps do
				if myToken ~= token then
					return -- a newer open/close took over
				end
				openAmount = from + (to - from) * step / steps
				apply(openAmount)
				task.wait(0.02)
			end
		end)
	end

	return cupboard
end

-- A small old brass key lying flat: ring, collar, shaft and teeth. Place it with key:PivotTo(...).
-- The shaft is the PrimaryPart, so attach prompts to key.PrimaryPart.
function HotelBuilder.newKey()
	local model = Instance.new("Model")
	model.Name = "Key"

	local function piece(name, size, cframe)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.Size = size
		part.CFrame = cframe
		part.Material = Enum.Material.Metal
		part.Color = Color3.fromRGB(176, 141, 66)
		part.Reflectance = 0.12
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		return part
	end

	local shaft = piece("Shaft", Vector3.new(0.13, 0.13, 1.45), CFrame.new(0, 0, 0.3))
	model.PrimaryPart = shaft

	-- The round bow (finger loop), made of ten short pieces around a circle
	local segments, radius = 10, 0.32
	for i = 1, segments do
		local angle = (i / segments) * math.pi * 2
		local position = Vector3.new(math.cos(angle) * radius, 0, -0.75 + math.sin(angle) * radius)
		local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
		piece("Bow", Vector3.new(0.16, 0.13, 0.24), CFrame.lookAt(position, position + tangent))
	end

	piece("Collar", Vector3.new(0.3, 0.17, 0.12), CFrame.new(0, 0, -0.2))
	piece("BitA", Vector3.new(0.34, 0.11, 0.2), CFrame.new(0.22, 0, 0.88))
	piece("BitB", Vector3.new(0.24, 0.11, 0.16), CFrame.new(0.17, 0, 0.58))

	-- A faint warm glint so it can be spotted in the dark
	local glint = Instance.new("PointLight")
	glint.Color = Color3.fromRGB(255, 220, 140)
	glint.Brightness = 0.6
	glint.Range = 6
	glint.Parent = shaft

	return model
end

-- Builds the hotel and returns a table of useful information (see the bottom of this function).
-- The caller is responsible for parenting hotel.Folder to workspace.
function HotelBuilder.build()
	local roomsPerSide = Config.RoomsPerSide
	local rw, rd, cw, h = Config.RoomWidth, Config.RoomDepth, Config.CorridorWidth, Config.WallHeight
	local doorW, doorH = Config.DoorWidth, Config.DoorHeight
	local exitLen = Config.ExitHallLength

	local half = cw / 2
	local length = roomsPerSide * rw
	local totalDepth = 2 * (half + rd)
	local shellWidth = length + exitLen + 2
	local shellCenterX = (length + exitLen) / 2

	local folder = Instance.new("Folder")
	folder.Name = "Hotel"

	local lights = {}
	local cupboards = {}
	local keySpots = {} -- one entry per room: the places in that room a key can lie
	local patrolPoints = {}

	-- Floor, carpet and ceiling (floor top surface is at y = 0)
	newPart(folder, "Floor", Vector3.new(shellWidth, 1, totalDepth + 2), CFrame.new(shellCenterX, -0.5, 0), FLOOR_COLOR, Enum.Material.WoodPlanks)
	newPart(folder, "Carpet", Vector3.new(length, 0.1, cw - 4), CFrame.new(length / 2, 0.05, 0), CARPET_COLOR, Enum.Material.Fabric)
	newPart(folder, "Ceiling", Vector3.new(shellWidth, 1, totalDepth + 2), CFrame.new(shellCenterX, h + 0.5, 0), CEILING_COLOR, Enum.Material.Concrete)

	-- West end of the corridor
	newPart(folder, "WestWall", Vector3.new(1, h, totalDepth + 2), CFrame.new(-0.5, h / 2, 0), WALL_COLOR, Enum.Material.Fabric)

	-- Rooms on both sides of the corridor (side 1 = north, side -1 = south)
	for _, side in { 1, -1 } do
		newPart(
			folder,
			"BackWall",
			Vector3.new(length + 1.5, h, 1),
			CFrame.new((length - 0.5) / 2, h / 2, side * (half + rd + 0.5)),
			WALL_COLOR,
			Enum.Material.Fabric
		)

		for i = 1, roomsPerSide do
			local xMin = (i - 1) * rw
			local xMax = i * rw
			local cx = xMin + rw / 2
			local zFront = side * half
			local zCenter = side * (half + rd / 2)
			local sideWidth = (rw - doorW) / 2

			-- Wall between this room and the next one
			newPart(folder, "Partition", Vector3.new(1, h, rd), CFrame.new(xMax, h / 2, zCenter), WALL_COLOR, Enum.Material.Fabric)

			-- Wall facing the corridor, with a doorway in the middle
			newPart(folder, "FrontWall", Vector3.new(sideWidth, h, 1), CFrame.new(xMin + sideWidth / 2, h / 2, zFront), WALL_COLOR, Enum.Material.Fabric)
			newPart(folder, "FrontWall", Vector3.new(sideWidth, h, 1), CFrame.new(xMax - sideWidth / 2, h / 2, zFront), WALL_COLOR, Enum.Material.Fabric)
			local lintel = newPart(
				folder,
				"Lintel",
				Vector3.new(doorW, h - doorH, 1),
				CFrame.new(cx, doorH + (h - doorH) / 2, zFront),
				WALL_COLOR,
				Enum.Material.Fabric
			)
			-- The room number sign faces the corridor (Front = -Z, Back = +Z)
			local roomNumber = (side == 1 and 100 or 200) + i
			addLabel(lintel, side == 1 and Enum.NormalId.Front or Enum.NormalId.Back, tostring(roomNumber), Color3.fromRGB(220, 190, 110))

			-- Furniture: a table and a bed or couch on opposite sides of the room
			local tableOnLeft = math.random() < 0.5
			local tableX = tableOnLeft and (xMin + 3.5) or (xMax - 3.5)
			local otherX = tableOnLeft and (xMax - 3.5) or (xMin + 3.5)

			local tableDepth = rd * 0.45 + math.random() * (rd * 0.4)
			local tableProp = newPart(
				folder,
				"Table",
				Vector3.new(4, 3, 4),
				CFrame.new(tableX, 1.5, side * (half + 0.5 + tableDepth)),
				WOOD_COLOR,
				Enum.Material.Wood
			)

			local otherDepth = 10 + math.random() * 6
			local size = Vector3.new(4, 2.5, 7) -- bed
			local name = "Bed"
			if math.random() < 0.5 then
				size = Vector3.new(3, 3, 6)
				name = "Couch"
			end
			local otherProp = newPart(folder, name, size, CFrame.new(otherX, size.Y / 2, side * (half + 0.5 + otherDepth)), WOOD_COLOR, Enum.Material.Wood)

			-- A key can lie on top of the table or on top of the bed/couch
			table.insert(keySpots, {
				tableProp.Position + Vector3.new((math.random() - 0.5) * 1.4, 1.5 + 0.08, (math.random() - 0.5) * 1.4),
				otherProp.Position
					+ Vector3.new((math.random() - 0.5) * (size.X - 1.5), size.Y / 2 + 0.08, (math.random() - 0.5) * (size.Z - 3)),
			})

			-- A cupboard against the back wall that players can hide in
			table.insert(cupboards, buildCupboard(folder, cx, side, half + rd))
			table.insert(patrolPoints, Vector3.new(cx, 0, side * (half + rd - 6))) -- the ghost likes to check these

			-- A dim lamp in the middle of the room
			addLamp(folder, Vector3.new(cx, h - 0.15, zCenter), 0.8, 18, lights)

			table.insert(patrolPoints, Vector3.new(cx, 0, zCenter))
		end
	end

	-- Corridor lamps and patrol points
	for i = 1, roomsPerSide do
		local cx = (i - 1) * rw + rw / 2
		addLamp(folder, Vector3.new(cx, h - 0.15, 0), 1, 24, lights)
		table.insert(patrolPoints, Vector3.new(cx, 0, 0))
	end

	-- Exit hall at the east end, behind a locked door
	newPart(folder, "ExitWallNorth", Vector3.new(exitLen, h, 1), CFrame.new(length + exitLen / 2, h / 2, half), WALL_COLOR, Enum.Material.Fabric)
	newPart(folder, "ExitWallSouth", Vector3.new(exitLen, h, 1), CFrame.new(length + exitLen / 2, h / 2, -half), WALL_COLOR, Enum.Material.Fabric)
	newPart(folder, "ExitEndWall", Vector3.new(1, h, cw + 1), CFrame.new(length + exitLen + 0.5, h / 2, 0), WALL_COLOR, Enum.Material.Fabric)

	local exitDoor = newPart(folder, "ExitDoor", Vector3.new(1.5, h, cw), CFrame.new(length, h / 2, 0), Color3.fromRGB(110, 30, 30), Enum.Material.Metal)

	local exitSign = newPart(
		folder,
		"ExitSign",
		Vector3.new(8, 2.5, 0.3),
		CFrame.new(length + exitLen - 0.2, 9, 0),
		Color3.fromRGB(15, 60, 25),
		Enum.Material.Neon
	)
	exitSign.CanCollide = false
	addLabel(exitSign, Enum.NormalId.Left, "EXIT", Color3.fromRGB(160, 255, 180)) -- Left = -X, toward the players

	local hallLight = Instance.new("PointLight")
	hallLight.Color = Color3.fromRGB(110, 255, 140)
	hallLight.Brightness = 2
	hallLight.Range = 22
	hallLight.Enabled = false
	hallLight.Parent = exitSign

	local function openExit()
		exitDoor.CanCollide = false
		exitDoor.Transparency = 0.75
		exitDoor.Color = Color3.fromRGB(60, 200, 90)
		hallLight.Enabled = true
	end

	-- Where players start: the west end of the corridor, facing east (room for 8)
	local playerSpawns = {}
	for i = 1, 8 do
		local column = (i - 1) // 4
		local row = (i - 1) % 4
		table.insert(playerSpawns, Vector3.new(3 + column * 3, 3.5, -4.5 + row * 3))
	end

	-- The ghost starts in the room furthest from the players
	local ghostSpawn = Vector3.new(length - rw / 2, 0, half + rd / 2)

	-- Make the lights flicker now and then
	task.spawn(function()
		while folder.Parent do
			task.wait(0.2)
			local light = lights[math.random(#lights)]
			if math.random() < 0.3 and light.Parent then
				local base = light:GetAttribute("BaseBrightness")
				light.Brightness = 0
				task.wait(0.07)
				if light.Parent then
					light.Brightness = base
				end
			end
		end
	end)

	return {
		Folder = folder,
		Cupboards = cupboards, -- one per room; players can hide inside
		KeySpots = keySpots, -- list of rooms, each a list of positions a key can lie
		PatrolPoints = patrolPoints, -- floor positions the ghost wanders between
		PlayerSpawns = playerSpawns,
		GhostSpawn = ghostSpawn,
		ExitX = length + 2, -- walk past this X (once the door is open) to escape
		OpenExit = openExit,
	}
end

return HotelBuilder
