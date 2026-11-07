-- Decor (ModuleScript in ServerScriptService)
-- Spooky furniture and props for the hotel and the lobby, all built from plain parts.
-- None of it blocks anyone: every prop has CanCollide, CanQuery and CanTouch turned off, so it never
-- gets in the way of players, the ghost's path-finding, or the ghost's line of sight.
--
-- Position convention: most props take a "base" CFrame whose +Z axis points AWAY from the wall (or the way
-- the prop faces) and whose +Y axis is up. Decor.place(position, facing) makes one.

local Decor = {}

local WOOD = Color3.fromRGB(62, 40, 28)
local DARK_WOOD = Color3.fromRGB(38, 25, 20)
local BRASS = Color3.fromRGB(150, 118, 52)
local BLOOD = Color3.fromRGB(118, 8, 12)
local WEB = Color3.fromRGB(228, 228, 234)
local BONE = Color3.fromRGB(226, 218, 196)
local WAX = Color3.fromRGB(230, 222, 200)

local PLASTIC = Enum.Material.SmoothPlastic
local BALL = Enum.PartType.Ball
local CYLINDER = Enum.PartType.Cylinder

local function range(low, high)
	return low + math.random() * (high - low)
end

-- A CFrame at `position` that faces along `facing` (its +Z axis points that way)
function Decor.place(position, facing)
	return CFrame.lookAt(position, position - facing)
end

local function prop(parent, name, size, cframe, color, material, transparency, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.CFrame = typeof(cframe) == "CFrame" and cframe or CFrame.new(cframe)
	part.Color = color
	part.Material = material or PLASTIC
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

-- A thin straight part between two points (used for webs, cracks, cords and spider legs)
local function beam(parent, name, a, b, thickness, color, transparency)
	local length = (b - a).Magnitude
	if length < 0.01 then
		return nil
	end
	return prop(parent, name, Vector3.new(thickness, thickness, length), CFrame.lookAt((a + b) / 2, b), color, PLASTIC, transparency)
end

local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- stands a cylinder up (its long axis is X)
local FACING = CFrame.Angles(0, math.pi / 2, 0) -- points a cylinder's axis along Z (a round disc on a wall)

-- Cobwebs -------------------------------------------------------------------------------------

-- A web in the top corner of a wall: `corner` is the top corner point, `along` a unit vector running
-- along the top edge of the wall. The web spreads from the corner between that edge and straight down.
function Decor.cobweb(parent, corner, along, length)
	local down = Vector3.new(0, -1, 0)
	local strands = 5
	local directions = {}
	for i = 1, strands do
		local angle = (i - 1) / (strands - 1) * (math.pi / 2)
		directions[i] = along * math.cos(angle) + down * math.sin(angle)
		beam(parent, "Web", corner, corner + directions[i] * length, 0.05, WEB, 0.45)
	end
	for _, ring in { 0.4, 0.7, 1.0 } do
		for i = 1, strands - 1 do
			beam(parent, "Web", corner + directions[i] * length * ring, corner + directions[i + 1] * length * ring, 0.04, WEB, 0.5)
		end
	end
end

-- Candles, pumpkins, skulls ------------------------------------------------------------------------

-- A candle standing at `position`. flames is a list the caller animates with Decor.animate.
function Decor.candle(parent, position, flames, height, noLight)
	height = height or 0.9
	prop(parent, "Candle", Vector3.new(height, 0.42, 0.42), CFrame.new(position + Vector3.new(0, height / 2, 0)) * UPRIGHT, WAX, PLASTIC, 0, CYLINDER)
	prop(parent, "Drip", Vector3.new(height * 0.45, 0.16, 0.16), CFrame.new(position + Vector3.new(0.19, height * 0.72, 0)) * UPRIGHT, WAX, PLASTIC, 0, CYLINDER)
	local flame = prop(parent, "Flame", Vector3.new(0.26, 0.26, 0.26), CFrame.new(position + Vector3.new(0, height + 0.18, 0)), Color3.fromRGB(255, 190, 80), Enum.Material.Neon, 0, BALL)
	if not noLight then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 170, 80)
		light.Brightness = 0.5
		light.Range = 9
		light.Parent = flame
		table.insert(flames, { Light = light, Base = 0.5 })
	end
end

function Decor.skull(parent, base)
	prop(parent, "Skull", Vector3.new(0.9, 0.9, 0.9), base * CFrame.new(0, 0.5, 0), BONE, PLASTIC, 0, BALL)
	prop(parent, "Jaw", Vector3.new(0.55, 0.25, 0.5), base * CFrame.new(0, 0.12, 0.12), BONE, PLASTIC)
	prop(parent, "Teeth", Vector3.new(0.45, 0.08, 0.05), base * CFrame.new(0, 0.24, 0.36), Color3.fromRGB(245, 238, 215), PLASTIC)
	for _, side in { -1, 1 } do
		prop(parent, "EyeHole", Vector3.new(0.22, 0.22, 0.22), base * CFrame.new(side * 0.2, 0.56, 0.36), Color3.fromRGB(8, 6, 6), PLASTIC, 0, BALL)
	end
	prop(parent, "Nose", Vector3.new(0.1, 0.14, 0.1), base * CFrame.new(0, 0.38, 0.43), Color3.fromRGB(20, 14, 12), PLASTIC)
end

-- A glowing jack-o'-lantern facing +Z
function Decor.pumpkin(parent, base, flames, scale)
	local s = scale or 1
	prop(parent, "Pumpkin", Vector3.new(2.4 * s, 2.4 * s, 2.4 * s), base * CFrame.new(0, 1.2 * s, 0), Color3.fromRGB(226, 104, 18), PLASTIC, 0, BALL)
	prop(parent, "Stem", Vector3.new(0.35 * s, 0.7 * s, 0.35 * s), base * CFrame.new(0, 2.5 * s, 0), Color3.fromRGB(60, 70, 30), PLASTIC)
	local glow = Color3.fromRGB(255, 190, 60)
	for _, side in { -1, 1 } do
		prop(parent, "PumpkinEye", Vector3.new(0.45 * s, 0.5 * s, 0.2 * s), base * CFrame.new(side * 0.6 * s, 1.5 * s, 1.1 * s), glow, Enum.Material.Neon)
	end
	prop(parent, "PumpkinNose", Vector3.new(0.3 * s, 0.3 * s, 0.2 * s), base * CFrame.new(0, 1.2 * s, 1.15 * s), glow, Enum.Material.Neon)
	for i = -2, 2 do
		prop(parent, "PumpkinMouth", Vector3.new(0.32 * s, 0.26 * s, 0.2 * s), base * CFrame.new(i * 0.4 * s, (0.8 + 0.1 * (i * i % 2)) * s, 1.08 * s), glow, Enum.Material.Neon)
	end
	local core = prop(parent, "PumpkinLight", Vector3.new(0.4, 0.4, 0.4), base * CFrame.new(0, 1.2 * s, 0), Color3.new(0, 0, 0), PLASTIC, 1)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 50)
	light.Brightness = 0.9
	light.Range = 12
	light.Parent = core
	table.insert(flames, { Light = light, Base = 0.9 })
end

-- Wall decoration ---------------------------------------------------------------------------------------

-- A framed painting. style: "face" (a pale face with dark eyes), "eyes" (just two eyes in the dark)
-- or "scratched" (a face that has been clawed).
function Decor.portrait(parent, base, style, width, height)
	width = width or 3
	height = height or 4.2
	local t = 0.35
	prop(parent, "FrameTop", Vector3.new(width + 2 * t, t, 0.3), base * CFrame.new(0, height / 2 + t / 2, 0.15), BRASS, Enum.Material.Wood)
	prop(parent, "FrameBottom", Vector3.new(width + 2 * t, t, 0.3), base * CFrame.new(0, -height / 2 - t / 2, 0.15), BRASS, Enum.Material.Wood)
	prop(parent, "FrameLeft", Vector3.new(t, height, 0.3), base * CFrame.new(-width / 2 - t / 2, 0, 0.15), BRASS, Enum.Material.Wood)
	prop(parent, "FrameRight", Vector3.new(t, height, 0.3), base * CFrame.new(width / 2 + t / 2, 0, 0.15), BRASS, Enum.Material.Wood)
	prop(parent, "Canvas", Vector3.new(width, height, 0.12), base * CFrame.new(0, 0, 0.08), Color3.fromRGB(24, 18, 16), PLASTIC)

	if style == "eyes" then
		for _, side in { -1, 1 } do
			prop(parent, "PaintedEye", Vector3.new(0.34, 0.34, 0.1), base * CFrame.new(side * width * 0.16, height * 0.08, 0.16), Color3.fromRGB(225, 225, 195), Enum.Material.Neon, 0.1, BALL)
			prop(parent, "PaintedPupil", Vector3.new(0.14, 0.14, 0.1), base * CFrame.new(side * width * 0.16, height * 0.08, 0.2), Color3.fromRGB(190, 12, 12), Enum.Material.Neon, 0, BALL)
		end
		return
	end

	-- A figure: dark clothes, a pale face, dark hair, hollow eyes
	prop(parent, "PaintedBody", Vector3.new(width * 0.8, height * 0.34, 0.05), base * CFrame.new(0, -height * 0.3, 0.16), Color3.fromRGB(20, 24, 40), PLASTIC)
	prop(parent, "PaintedFace", Vector3.new(0.06, height * 0.34, width * 0.36), base * CFrame.new(0, height * 0.08, 0.17) * FACING, Color3.fromRGB(190, 180, 165), PLASTIC, 0, CYLINDER)
	prop(parent, "PaintedHair", Vector3.new(width * 0.42, height * 0.12, 0.05), base * CFrame.new(0, height * 0.27, 0.17), Color3.fromRGB(16, 12, 12), PLASTIC)
	for _, side in { -1, 1 } do
		prop(parent, "PaintedSocket", Vector3.new(0.2, 0.28, 0.05), base * CFrame.new(side * width * 0.1, height * 0.11, 0.21), Color3.fromRGB(10, 8, 8), PLASTIC)
	end
	if style == "scratched" then
		for i = 1, 5 do
			local x = range(-width * 0.4, width * 0.4)
			beam(parent, "Scratch", base * Vector3.new(x, height * 0.42, 0.22), base * Vector3.new(x + range(-0.8, 0.8), -height * 0.42, 0.22), 0.05, Color3.fromRGB(205, 195, 170), 0.1)
		end
	end
end

-- Blood-red writing on a wall
function Decor.writing(parent, base, text, width, height)
	local pane = prop(parent, "Writing", Vector3.new(width, height, 0.1), base * CFrame.new(0, 0, 0.06), BLOOD, PLASTIC, 1)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- +Z is the side facing the room
	gui.PixelsPerStud = 50
	gui.Parent = pane
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(150, 10, 14)
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.Creepster
	label.Rotation = math.random(-4, 4)
	label.Parent = gui
end

function Decor.handprint(parent, base)
	prop(parent, "Palm", Vector3.new(0.8, 0.9, 0.05), base * CFrame.new(0, 0, 0.03), BLOOD, PLASTIC, 0.08)
	for i = 1, 4 do
		local tilt = (2.5 - i) * 0.12
		prop(parent, "Finger", Vector3.new(0.16, 0.7, 0.05), base * CFrame.new((i - 2.5) * 0.2, 0.75, 0.03) * CFrame.Angles(0, 0, tilt), BLOOD, PLASTIC, 0.08)
	end
	prop(parent, "Thumb", Vector3.new(0.16, 0.5, 0.05), base * CFrame.new(0.52, 0.1, 0.03) * CFrame.Angles(0, 0, -0.9), BLOOD, PLASTIC, 0.08)
	for _, x in { -0.25, 0.05, 0.3 } do
		local drip = range(0.8, 2.2)
		prop(parent, "Drip", Vector3.new(0.08, drip, 0.04), base * CFrame.new(x, -0.45 - drip / 2, 0.03), BLOOD, PLASTIC, 0.1)
	end
end

-- A framed window with moonlight coming in and torn curtains. width/height are the glass size.
function Decor.window(parent, base, width, height)
	local wood = DARK_WOOD
	local t = 0.3
	prop(parent, "WindowTop", Vector3.new(width + 2 * t, t, 0.5), base * CFrame.new(0, height / 2 + t / 2, 0.25), wood, Enum.Material.Wood)
	prop(parent, "WindowSill", Vector3.new(width + 1.2, t, 0.9), base * CFrame.new(0, -height / 2 - t / 2, 0.45), wood, Enum.Material.Wood)
	prop(parent, "WindowLeft", Vector3.new(t, height, 0.5), base * CFrame.new(-width / 2 - t / 2, 0, 0.25), wood, Enum.Material.Wood)
	prop(parent, "WindowRight", Vector3.new(t, height, 0.5), base * CFrame.new(width / 2 + t / 2, 0, 0.25), wood, Enum.Material.Wood)
	prop(parent, "Moonlit", Vector3.new(width, height, 0.1), base * CFrame.new(0, 0, 0.06), Color3.fromRGB(70, 90, 140), Enum.Material.Neon, 0.3)
	prop(parent, "Bar", Vector3.new(0.18, height, 0.2), base * CFrame.new(0, 0, 0.2), wood, Enum.Material.Wood)
	prop(parent, "Bar", Vector3.new(width, 0.18, 0.2), base * CFrame.new(0, 0, 0.2), wood, Enum.Material.Wood)

	local curtain = Color3.fromRGB(96, 14, 24)
	for _, side in { -1, 1 } do
		prop(parent, "Curtain", Vector3.new(width * 0.3, height * 1.2, 0.35), base * CFrame.new(side * (width / 2 + 0.55), -height * 0.03, 0.4) * CFrame.Angles(0, 0, side * 0.04), curtain, Enum.Material.Fabric)
	end
	beam(parent, "CurtainRod", base * Vector3.new(-width / 2 - 1.3, height * 0.58, 0.45), base * Vector3.new(width / 2 + 1.3, height * 0.58, 0.45), 0.12, BRASS, 0)

	local source = prop(parent, "Moonbeam", Vector3.new(0.3, 0.3, 0.3), base * CFrame.new(0, 0, 1.6), Color3.new(0, 0, 0), PLASTIC, 1)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(140, 160, 255)
	light.Brightness = 0.35
	light.Range = 16
	light.Parent = source
end

-- A grandfather clock that stopped at a quarter to midnight
function Decor.clock(parent, base)
	prop(parent, "ClockBody", Vector3.new(2.4, 9, 1.6), base * CFrame.new(0, 4.5, 0.8), WOOD, Enum.Material.Wood)
	prop(parent, "ClockTop", Vector3.new(2.8, 0.5, 1.9), base * CFrame.new(0, 9.2, 0.85), DARK_WOOD, Enum.Material.Wood)
	prop(parent, "ClockFace", Vector3.new(0.12, 1.9, 1.9), base * CFrame.new(0, 7.3, 1.65) * FACING, Color3.fromRGB(225, 215, 185), PLASTIC, 0, CYLINDER)
	prop(parent, "MinuteHand", Vector3.new(0.1, 0.8, 0.05), base * CFrame.new(0, 7.65, 1.72), Color3.fromRGB(15, 12, 10), PLASTIC)
	prop(parent, "HourHand", Vector3.new(0.1, 0.55, 0.05), base * CFrame.new(-0.12, 7.55, 1.72) * CFrame.Angles(0, 0, 0.35), Color3.fromRGB(15, 12, 10), PLASTIC)
	prop(parent, "ClockGlass", Vector3.new(1.5, 3.4, 0.1), base * CFrame.new(0, 3.3, 1.62), Color3.fromRGB(150, 170, 180), Enum.Material.Glass, 0.65)
	prop(parent, "Pendulum", Vector3.new(0.1, 2.6, 0.06), base * CFrame.new(0.2, 3.5, 1.5) * CFrame.Angles(0, 0, 0.1), BRASS, Enum.Material.Metal)
	prop(parent, "PendulumBob", Vector3.new(0.12, 0.7, 0.7), base * CFrame.new(0.45, 2.3, 1.5) * FACING, BRASS, Enum.Material.Metal, 0, CYLINDER)
end

-- A cracked mirror
function Decor.mirror(parent, base, width, height)
	local t = 0.3
	prop(parent, "MirrorFrame", Vector3.new(width + 2 * t, height + 2 * t, 0.25), base * CFrame.new(0, 0, 0.125), BRASS, Enum.Material.Metal)
	local glass = prop(parent, "MirrorGlass", Vector3.new(width, height, 0.1), base * CFrame.new(0, 0, 0.27), Color3.fromRGB(190, 205, 225), Enum.Material.Glass, 0.1)
	glass.Reflectance = 0.5
	local centre = Vector3.new(width * 0.15, height * 0.1, 0.34)
	for i = 1, 7 do
		local angle = i / 7 * math.pi * 2
		local reach = range(0.35, 0.6) * math.min(width, height)
		beam(parent, "Crack", base * centre, base * (centre + Vector3.new(math.cos(angle) * reach, math.sin(angle) * reach, 0)), 0.03, Color3.fromRGB(30, 30, 36), 0)
	end
end

-- A bookshelf full of old books (some leaning, a few missing)
function Decor.bookshelf(parent, base, width, height)
	local depth = 1.1
	prop(parent, "ShelfBack", Vector3.new(width, height, 0.15), base * CFrame.new(0, height / 2, 0.075), DARK_WOOD, Enum.Material.Wood)
	for _, side in { -1, 1 } do
		prop(parent, "ShelfSide", Vector3.new(0.2, height, depth), base * CFrame.new(side * (width / 2 - 0.1), height / 2, depth / 2), WOOD, Enum.Material.Wood)
	end
	local rows = 4
	local gap = height / rows
	for row = 0, rows do
		prop(parent, "Shelf", Vector3.new(width, 0.2, depth), base * CFrame.new(0, row * gap + 0.1, depth / 2), WOOD, Enum.Material.Wood)
	end
	for row = 0, rows - 1 do
		local x = -width / 2 + 0.5
		while x < width / 2 - 0.5 do
			local step = range(0.28, 0.45)
			if math.random() > 0.12 then
				local bookHeight = range(0.9, math.min(1.7, gap - 0.4))
				local tilt = (math.random() < 0.1) and range(-0.4, 0.4) or 0
				local shade = range(0.5, 1)
				prop(
					parent,
					"Book",
					Vector3.new(step * 0.85, bookHeight, 0.7),
					base * CFrame.new(x, row * gap + 0.2 + bookHeight / 2, depth / 2) * CFrame.Angles(0, 0, tilt),
					Color3.fromRGB(math.floor(90 * shade), math.floor(28 * shade * math.random()), math.floor(30 * shade * math.random())),
					Enum.Material.Fabric
				)
			end
			x += step
		end
	end
end

-- A porcelain doll sitting, facing +Z, head tilted a little too far
function Decor.doll(parent, base)
	local dress = Color3.fromRGB(205, 198, 208)
	local skin = Color3.fromRGB(234, 222, 212)
	prop(parent, "DollSkirt", Vector3.new(0.8, 1.2, 1.2), base * CFrame.new(0, 0.45, 0) * UPRIGHT, dress, Enum.Material.Fabric, 0, CYLINDER)
	prop(parent, "DollTorso", Vector3.new(0.8, 0.9, 0.5), base * CFrame.new(0, 1.2, 0), dress, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		prop(parent, "DollArm", Vector3.new(0.2, 0.75, 0.2), base * CFrame.new(side * 0.55, 1.15, 0.1) * CFrame.Angles(0.2, 0, side * 0.25), skin, PLASTIC)
		prop(parent, "DollLeg", Vector3.new(0.28, 0.28, 0.9), base * CFrame.new(side * 0.25, 0.3, 0.7), skin, PLASTIC)
		prop(parent, "DollShoe", Vector3.new(0.32, 0.3, 0.3), base * CFrame.new(side * 0.25, 0.3, 1.2), Color3.fromRGB(14, 12, 12), PLASTIC)
	end

	local head = base * CFrame.new(0, 1.65, 0) * CFrame.Angles(0.05, range(-0.35, 0.35), range(-0.3, 0.3))
	prop(parent, "DollHead", Vector3.new(0.95, 0.95, 0.95), head * CFrame.new(0, 0.45, 0), skin, PLASTIC, 0, BALL)
	prop(parent, "DollHair", Vector3.new(1.02, 1.02, 1.02), head * CFrame.new(0, 0.58, -0.07), Color3.fromRGB(70, 45, 30), PLASTIC, 0, BALL)
	for _, side in { -1, 1 } do
		prop(parent, "DollTuft", Vector3.new(0.2, 0.8, 0.2), head * CFrame.new(side * 0.5, 0.15, 0), Color3.fromRGB(70, 45, 30), PLASTIC)
		prop(parent, "DollEyeWhite", Vector3.new(0.26, 0.26, 0.26), head * CFrame.new(side * 0.2, 0.55, 0.38), Color3.fromRGB(240, 238, 230), PLASTIC, 0, BALL)
		prop(parent, "DollPupil", Vector3.new(0.13, 0.13, 0.13), head * CFrame.new(side * 0.2, 0.55, 0.49), Color3.fromRGB(8, 8, 8), PLASTIC, 0, BALL)
	end
	prop(parent, "DollMouth", Vector3.new(0.3, 0.05, 0.04), head * CFrame.new(0, 0.25, 0.44), Color3.fromRGB(110, 16, 20), PLASTIC)
	prop(parent, "DollCrack", Vector3.new(0.03, 0.4, 0.03), head * CFrame.new(0.18, 0.52, 0.45) * CFrame.Angles(0, 0, 0.4), Color3.fromRGB(40, 36, 36), PLASTIC)
end

-- A spider hanging on a thread from the ceiling. `position` is the spider; the thread goes `thread` studs up.
function Decor.spider(parent, position, thread)
	local black = Color3.fromRGB(10, 10, 12)
	beam(parent, "Thread", position, position + Vector3.new(0, thread, 0), 0.03, WEB, 0.3)
	prop(parent, "SpiderBody", Vector3.new(0.45, 0.45, 0.45), CFrame.new(position), black, PLASTIC, 0, BALL)
	prop(parent, "SpiderAbdomen", Vector3.new(0.65, 0.65, 0.65), CFrame.new(position + Vector3.new(0, -0.1, -0.45)), black, PLASTIC, 0, BALL)
	for _, side in { -1, 1 } do
		for i = 1, 4 do
			local z = (i - 2.5) * 0.3
			local knee = position + Vector3.new(side * 0.55, 0.3, z * 1.4)
			local foot = position + Vector3.new(side * 0.95, -0.55, z * 2.2)
			beam(parent, "SpiderLeg", position, knee, 0.04, black, 0)
			beam(parent, "SpiderLeg", knee, foot, 0.04, black, 0)
		end
	end
end

-- Blood ------------------------------------------------------------------------------------------------------

function Decor.bloodPool(parent, position, radius)
	local pool = prop(
		parent,
		"Blood",
		Vector3.new(0.05, radius * 2, radius * 2 * range(0.7, 1)),
		CFrame.new(position + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, math.pi / 2),
		BLOOD,
		PLASTIC,
		0.05,
		CYLINDER
	)
	pool.Reflectance = 0.25
	for i = 1, 4 do
		local offset = Vector3.new(range(-radius * 1.6, radius * 1.6), 0.08, range(-radius * 1.6, radius * 1.6))
		local size = range(0.2, 0.5)
		prop(parent, "BloodDrop", Vector3.new(0.05, size, size), CFrame.new(position + offset) * CFrame.Angles(0, 0, math.pi / 2), BLOOD, PLASTIC, 0.05, CYLINDER)
	end
end

-- Streaks on the floor, as if something was dragged from `from` to `to`
function Decor.dragMarks(parent, from, to)
	local direction = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if direction.Magnitude < 0.5 then
		return
	end
	local side = Vector3.new(-direction.Z, 0, direction.X).Unit
	for k = -1, 1 do
		local a = from + side * (0.5 * k) + Vector3.new(0, 0.07, 0)
		local b = to + side * (0.5 * k + range(-0.2, 0.2)) + Vector3.new(0, 0.07, 0)
		local mid = (a + b) / 2
		local length = (b - a).Magnitude
		prop(parent, "DragMark", Vector3.new(range(0.2, 0.35), 0.05, length), CFrame.lookAt(mid, b), BLOOD, PLASTIC, 0.12)
	end
end

-- Furniture ---------------------------------------------------------------------------------------------------------

function Decor.chair(parent, base)
	prop(parent, "ChairSeat", Vector3.new(2, 0.25, 2), base * CFrame.new(0, 1.4, 0), WOOD, Enum.Material.Wood)
	prop(parent, "ChairBack", Vector3.new(2, 2.2, 0.22), base * CFrame.new(0, 2.6, -0.9), WOOD, Enum.Material.Wood)
	for _, x in { -0.85, 0.85 } do
		for _, z in { -0.85, 0.85 } do
			prop(parent, "ChairLeg", Vector3.new(0.22, 1.4, 0.22), base * CFrame.new(x, 0.7, z), WOOD, Enum.Material.Wood)
		end
	end
end

-- A chair under a dust sheet
function Decor.coveredChair(parent, base)
	local sheet = Color3.fromRGB(225, 222, 212)
	prop(parent, "SheetSeat", Vector3.new(3, 2.4, 3), base * CFrame.new(0, 1.2, 0), sheet, Enum.Material.Fabric, 0.03)
	prop(parent, "SheetBack", Vector3.new(3, 3.6, 1), base * CFrame.new(0, 1.8, -1), sheet, Enum.Material.Fabric, 0.03)
	for _, side in { -1, 1 } do
		prop(parent, "SheetFold", Vector3.new(0.12, 1.7, 2.7), base * CFrame.new(side * 1.58, 0.85, 0.1) * CFrame.Angles(0, 0, side * 0.12), sheet, Enum.Material.Fabric, 0.05)
	end
	prop(parent, "SheetFold", Vector3.new(2.7, 1.5, 0.12), base * CFrame.new(0, 0.75, 1.55) * CFrame.Angles(-0.12, 0, 0), sheet, Enum.Material.Fabric, 0.05)
end

-- A candle holder on the wall
function Decor.sconce(parent, base, flames)
	prop(parent, "SconcePlate", Vector3.new(0.7, 1.4, 0.15), base * CFrame.new(0, 0, 0.075), BRASS, Enum.Material.Metal)
	prop(parent, "SconceArm", Vector3.new(0.18, 0.18, 0.6), base * CFrame.new(0, -0.4, 0.4), BRASS, Enum.Material.Metal)
	prop(parent, "SconceCup", Vector3.new(0.2, 0.6, 0.6), base * CFrame.new(0, -0.35, 0.68) * UPRIGHT, BRASS, Enum.Material.Metal, 0, CYLINDER)
	Decor.candle(parent, base * Vector3.new(0, -0.25, 0.68), flames, 0.8)
end

-- A key hanging on a hook (for the lobby key board)
local function hangingKey(parent, base)
	local brass = Color3.fromRGB(176, 141, 66)
	prop(parent, "KeyRing", Vector3.new(0.06, 0.36, 0.36), base * CFrame.new(0, -0.1, 0.1) * FACING, brass, Enum.Material.Metal, 0, CYLINDER)
	prop(parent, "KeyShaft", Vector3.new(0.1, 0.9, 0.06), base * CFrame.new(0, -0.7, 0.1), brass, Enum.Material.Metal)
	prop(parent, "KeyTeeth", Vector3.new(0.22, 0.1, 0.06), base * CFrame.new(0.12, -1.05, 0.1), brass, Enum.Material.Metal)
end

-- Atmosphere ---------------------------------------------------------------------------------------------------------------

-- Dust that drifts and glints in the air inside a box of the given size
function Decor.dust(parent, position, size, rate)
	local holder = prop(parent, "Dust", size, CFrame.new(position), Color3.new(0, 0, 0), PLASTIC, 1)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(6, 10)
	emitter.Speed = NumberRange.new(0.05, 0.3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.14)
	emitter.LightEmission = 0.25
	emitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 215))
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.55),
		NumberSequenceKeypoint.new(0.8, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = holder
end

-- Low mist creeping along the floor
function Decor.mist(parent, position, size, rate)
	local holder = prop(parent, "Mist", size, CFrame.new(position), Color3.new(0, 0, 0), PLASTIC, 1)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(6, 9)
	emitter.Speed = NumberRange.new(0.2, 0.6)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 10) })
	emitter.Color = ColorSequence.new(Color3.fromRGB(170, 180, 200))
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.93),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = holder
end

-- Makes every candle and fire in `flames` flicker for as long as `root` exists
function Decor.animate(root, flames)
	task.spawn(function()
		while root.Parent do
			for _, flame in flames do
				if flame.Light.Parent then
					flame.Light.Brightness = flame.Base * (0.65 + 0.35 * math.random())
				end
			end
			task.wait(0.12)
		end
	end)
end

-- One room of the hotel ---------------------------------------------------------------------------------------------------------------

-- room: { Cx, XMin, XMax, Side (1 north, -1 south), Half, Depth, Height, TableProp, OtherProp, Flames }
function Decor.roomProps(parent, room)
	local side, half, rd, h = room.Side, room.Half, room.Depth, room.Height
	local backZ = half + rd
	local toDoor = Vector3.new(0, 0, -side) -- the way out, toward the corridor
	local flames = room.Flames

	-- A candle (and sometimes a skull) on the table
	local tableTop = Vector3.new(room.TableProp.Position.X, room.TableProp.Position.Y + room.TableProp.Size.Y / 2, room.TableProp.Position.Z)
	Decor.candle(parent, tableTop + Vector3.new(1.35, 0, 1.35), flames, 0.9)
	if math.random() < 0.3 then
		Decor.skull(parent, Decor.place(tableTop + Vector3.new(-1.3, 0, -1.3), Vector3.new(range(-1, 1), 0, range(-1, 1))))
	end

	-- A doll on the bed or couch, staring at the door
	if math.random() < 0.5 then
		local other = room.OtherProp
		local seat = Vector3.new(other.Position.X, other.Position.Y + other.Size.Y / 2, other.Position.Z + side * (other.Size.Z / 2 - 0.8))
		Decor.doll(parent, Decor.place(seat, toDoor + Vector3.new(range(-0.4, 0.4), 0, 0)))
	end

	-- A window with moonlight on the back wall, to one side of the cupboard
	local windowX = room.Cx + (math.random() < 0.5 and -8.2 or 8.2)
	Decor.window(parent, Decor.place(Vector3.new(windowX, 7.2, side * (backZ - 0.05)), toDoor), 3.4, 5.2)

	-- Cobwebs in the back corners
	if math.random() < 0.85 then
		Decor.cobweb(parent, Vector3.new(room.XMin + 0.6, h - 0.1, side * (backZ - 0.15)), Vector3.new(1, 0, 0), range(2.6, 3.6))
	end
	if math.random() < 0.85 then
		Decor.cobweb(parent, Vector3.new(room.XMax - 0.6, h - 0.1, side * (backZ - 0.15)), Vector3.new(-1, 0, 0), range(2.6, 3.6))
	end

	-- A portrait, or a bookshelf, on a side wall near the door
	local onLeft = math.random() < 0.5
	local wallX = onLeft and (room.XMin + 0.5) or (room.XMax - 0.5)
	local wallFacing = Vector3.new(onLeft and 1 or -1, 0, 0)
	local decorZ = side * (half + 0.5 + 6.5)
	if math.random() < 0.35 then
		Decor.bookshelf(parent, Decor.place(Vector3.new(wallX, 0, decorZ), wallFacing), 5, 9)
	elseif math.random() < 0.8 then
		local styles = { "face", "eyes", "scratched" }
		Decor.portrait(parent, Decor.place(Vector3.new(wallX, 7.5, decorZ), wallFacing), styles[math.random(#styles)], 3, 4.2)
	end

	-- Writing on the other wall, high up
	if math.random() < 0.2 then
		local words = { "GET OUT", "HE IS WATCHING", "DO NOT SLEEP", "SHE NEVER LEFT", "HIDE" }
		local otherX = onLeft and (room.XMax - 0.5) or (room.XMin + 0.5)
		Decor.writing(parent, Decor.place(Vector3.new(otherX, 10.5, side * (half + 0.5 + 12)), Vector3.new(onLeft and -1 or 1, 0, 0)), words[math.random(#words)], 6, 1.6)
	end

	-- Blood in front of the cupboard, as if someone was dragged to it
	if math.random() < 0.2 then
		local poolAt = Vector3.new(room.Cx + range(-2, 2), 0, side * (backZ - 6))
		Decor.bloodPool(parent, poolAt, range(1.2, 2))
		Decor.dragMarks(parent, poolAt + Vector3.new(range(-3, 3), 0, -side * 4), Vector3.new(room.Cx, 0, side * (backZ - 3.4)))
	end

	-- A chair under a dust sheet in a corner by the door
	if math.random() < 0.3 then
		local cornerX = math.random() < 0.5 and (room.XMin + 2.5) or (room.XMax - 2.5)
		Decor.coveredChair(parent, Decor.place(Vector3.new(cornerX, 0, side * (half + 3)), toDoor + Vector3.new(range(-0.5, 0.5), 0, 0)))
	end
end

-- The corridor ---------------------------------------------------------------------------------------------------------------------------

-- ctx: { Rooms, RoomWidth, RoomDepth, CorridorWidth, Height, ExitHallLength, DoorWidth, Flames }
function Decor.corridor(parent, ctx)
	local half = ctx.CorridorWidth / 2
	local rw = ctx.RoomWidth
	local length = ctx.Rooms * rw
	local h = ctx.Height
	local flames = ctx.Flames

	-- Portraits and candle sconces on the walls either side of every doorway
	local styles = { "face", "eyes", "scratched" }
	for _, side in { 1, -1 } do
		local wallZ = side * (half - 0.5) -- the corridor face of the wall
		local facing = Vector3.new(0, 0, -side)
		for i = 1, ctx.Rooms do
			local xMin = (i - 1) * rw
			local xMax = i * rw
			for _, centre in { xMin + 4, xMax - 4 } do
				if math.random() < 0.6 then
					Decor.portrait(parent, Decor.place(Vector3.new(centre, 7.2, wallZ), facing), styles[math.random(#styles)], 3, 4.2)
				end
			end
			for _, x in { xMin + 1.2, xMax - 1.2 } do
				if math.random() < 0.45 then
					Decor.sconce(parent, Decor.place(Vector3.new(x, 7.6, wallZ), facing), flames)
				end
			end
		end
	end

	-- The west end: a stopped clock, a warning, cobwebs
	local west = Vector3.new(1, 0, 0)
	Decor.clock(parent, Decor.place(Vector3.new(0, 0, 0), west))
	Decor.writing(parent, Decor.place(Vector3.new(0, 11, 0), west), "TURN BACK", 8, 2)
	Decor.cobweb(parent, Vector3.new(0.6, h - 0.1, half - 0.6), Vector3.new(0, 0, -1), 3.4)
	Decor.cobweb(parent, Vector3.new(0.6, h - 0.1, -half + 0.6), Vector3.new(0, 0, 1), 3.4)

	-- The east end: a message behind the exit door, seen once it opens
	Decor.writing(parent, Decor.place(Vector3.new(length + ctx.ExitHallLength, 7, 0), Vector3.new(-1, 0, 0)), "THE LAST GUEST NEVER LEFT", 10, 1.8)

	-- A couple of warnings on the long walls
	local words = { "HE IS BEHIND YOU", "DO NOT LOOK", "RUN", "SHE CAN HEAR YOU" }
	for _ = 1, 2 do
		local side = math.random() < 0.5 and 1 or -1
		Decor.writing(parent, Decor.place(Vector3.new(range(14, length - 14), 11, side * (half - 0.5)), Vector3.new(0, 0, -side)), words[math.random(#words)], 7, 1.6)
	end

	-- Spiders hanging from the ceiling
	for _ = 1, 6 do
		local thread = range(1.5, 4.5)
		Decor.spider(parent, Vector3.new(range(4, length - 4), h - thread, range(-half + 1, half - 1)), thread)
	end

	-- Things left behind: overturned chairs, blood, a drag trail from a doorway
	for _ = 1, 2 do
		local at = Vector3.new(range(8, length - 8), 1.0, range(-3.5, 3.5))
		Decor.chair(parent, CFrame.new(at) * CFrame.Angles(0, math.random() * math.pi * 2, math.pi / 2 + range(-0.2, 0.2)))
	end
	for _ = 1, 3 do
		Decor.bloodPool(parent, Vector3.new(range(6, length - 6), 0, range(-3, 3)), range(1, 1.8))
	end
	local doorSide = math.random() < 0.5 and 1 or -1
	local doorX = (math.random(ctx.Rooms) - 0.5) * rw
	Decor.dragMarks(parent, Vector3.new(doorX, 0, doorSide * (half + 3)), Vector3.new(doorX + range(-14, 14), 0, 0))

	-- Dust in the air and mist along the floor
	Decor.dust(parent, Vector3.new(length / 2, h / 2, 0), Vector3.new(length, h - 2, ctx.CorridorWidth - 1), 45)
	Decor.mist(parent, Vector3.new(length / 2, 1.2, 0), Vector3.new(length, 1.5, ctx.CorridorWidth - 2), 5)
end

-- The lobby --------------------------------------------------------------------------------------------------------------------------------

-- Dresses the lobby room: a 70 x 70 floor whose top is at center.Y, with walls 35 studs out.
function Decor.lobby(parent, center, flames)
	local function P(x, y, z)
		return center + Vector3.new(x, y, z)
	end
	local north = Vector3.new(0, 0, 1) -- facing +Z: for decorations on the north wall
	local south = Vector3.new(0, 0, -1)
	local west = Vector3.new(1, 0, 0) -- facing +X: for the west wall
	local east = Vector3.new(-1, 0, 0)

	-- Wooden panelling and a moulding strip around the bottom of the walls
	local panelling = Color3.fromRGB(84, 54, 36)
	for _, wall in {
		{ Vector3.new(70, 4.4, 0.15), P(0, 2.2, -34.925) },
		{ Vector3.new(70, 4.4, 0.15), P(0, 2.2, 34.925) },
		{ Vector3.new(0.15, 4.4, 70), P(-34.925, 2.2, 0) },
		{ Vector3.new(0.15, 4.4, 70), P(34.925, 2.2, 0) },
	} do
		prop(parent, "Panelling", wall[1], CFrame.new(wall[2]), panelling, Enum.Material.Wood)
	end
	for _, wall in {
		{ Vector3.new(70, 0.3, 0.3), P(0, 4.55, -34.85) },
		{ Vector3.new(70, 0.3, 0.3), P(0, 4.55, 34.85) },
		{ Vector3.new(0.3, 0.3, 70), P(-34.85, 4.55, 0) },
		{ Vector3.new(0.3, 0.3, 70), P(34.85, 4.55, 0) },
	} do
		prop(parent, "Moulding", wall[1], CFrame.new(wall[2]), BRASS, Enum.Material.Wood)
	end

	-- Ceiling with dark beams, and cords that the lamps hang from
	prop(parent, "LobbyCeiling", Vector3.new(72, 1, 72), CFrame.new(P(0, 28.5, 0)), Color3.fromRGB(34, 28, 26), Enum.Material.Concrete)
	for _, z in { -24, -8, 8, 24 } do
		prop(parent, "CeilingBeam", Vector3.new(72, 1.4, 2), CFrame.new(P(0, 27.6, z)), DARK_WOOD, Enum.Material.Wood)
	end
	for _, x in { -22, 0, 22 } do
		beam(parent, "LampCord", P(x, 18.3, -4), P(x, 28, -4), 0.12, Color3.fromRGB(20, 16, 16), 0)
	end

	-- A chandelier of candles
	local hub = P(0, 21, 8)
	beam(parent, "ChandelierChain", hub + Vector3.new(0, 0.3, 0), P(0, 28, 8), 0.15, BRASS, 0)
	prop(parent, "ChandelierHub", Vector3.new(0.9, 0.9, 0.9), CFrame.new(hub), BRASS, Enum.Material.Metal, 0, BALL)
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local rim = hub + Vector3.new(math.cos(angle) * 3.5, -0.4, math.sin(angle) * 3.5)
		beam(parent, "ChandelierArm", hub, rim, 0.12, BRASS, 0)
		local nextAngle = ((i + 1) / 8) * math.pi * 2
		beam(parent, "ChandelierRing", rim, hub + Vector3.new(math.cos(nextAngle) * 3.5, -0.4, math.sin(nextAngle) * 3.5), 0.12, BRASS, 0)
		Decor.candle(parent, rim, flames, 0.7, i % 2 == 0)
	end

	-- Fireplace on the west wall, with a fire, a portrait, a skull and candles on the mantel
	local fire = Decor.place(P(-35, 0, -4), west)
	local stone = Color3.fromRGB(70, 66, 64)
	for _, x in { -3.4, 3.4 } do
		prop(parent, "FireplaceSide", Vector3.new(1.6, 9, 2.2), fire * CFrame.new(x, 4.5, 1.1), stone, Enum.Material.Slate)
	end
	prop(parent, "FireplaceLintel", Vector3.new(8.4, 2, 2.4), fire * CFrame.new(0, 8, 1.2), stone, Enum.Material.Slate)
	prop(parent, "Mantel", Vector3.new(9.4, 0.5, 2.8), fire * CFrame.new(0, 9.3, 1.3), DARK_WOOD, Enum.Material.Wood)
	prop(parent, "Firebox", Vector3.new(5.2, 6, 0.3), fire * CFrame.new(0, 3, 0.15), Color3.fromRGB(14, 12, 12), PLASTIC)
	prop(parent, "Hearth", Vector3.new(8, 0.4, 3.2), fire * CFrame.new(0, 0.2, 1.6), stone, Enum.Material.Slate)
	for i = -1, 1 do
		prop(parent, "Log", Vector3.new(3.4, 0.6, 0.6), fire * CFrame.new(0, 0.7 + (i == 0 and 0.5 or 0), 1.0 + i * 0.35) * CFrame.Angles(0, range(-0.15, 0.15), 0), Color3.fromRGB(40, 26, 18), Enum.Material.Wood, 0, CYLINDER)
	end
	local fireColors = { Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 170, 40), Color3.fromRGB(255, 90, 20) }
	for i, x in { -0.9, 0, 0.9 } do
		prop(parent, "Flame", Vector3.new(0.9, 1.8 + i * 0.4, 0.9), fire * CFrame.new(x, 1.7 + i * 0.1, 1.1) * CFrame.Angles(0, 0, x * 0.15), fireColors[i], Enum.Material.Neon, 0.1)
	end
	local fireGlow = prop(parent, "FireLight", Vector3.new(0.5, 0.5, 0.5), fire * CFrame.new(0, 2.5, 1.7), Color3.new(0, 0, 0), PLASTIC, 1)
	local fireLight = Instance.new("PointLight")
	fireLight.Color = Color3.fromRGB(255, 140, 60)
	fireLight.Brightness = 1.8
	fireLight.Range = 38
	fireLight.Parent = fireGlow
	table.insert(flames, { Light = fireLight, Base = 1.8 })
	Decor.skull(parent, fire * CFrame.new(-2.8, 9.55, 1.3) * CFrame.Angles(0, 0.3, 0))
	Decor.candle(parent, fire * Vector3.new(2.2, 9.55, 1.2), flames, 0.9)
	Decor.candle(parent, fire * Vector3.new(3.2, 9.55, 1.5), flames, 1.2)
	Decor.pumpkin(parent, fire * CFrame.new(0, 9.55, 1.4) * CFrame.Angles(0, 0.2, 0), flames, 0.45)
	Decor.portrait(parent, Decor.place(P(-35, 15, -4), west), "face", 5, 6.5)

	-- Reception desk along the east wall, with a bell, a guest book and a board of keys
	local desk = Decor.place(P(35, 0, -4), east)
	local deskWood = Color3.fromRGB(58, 38, 28)
	prop(parent, "DeskFront", Vector3.new(16, 4.2, 1.6), desk * CFrame.new(0, 2.1, 5), deskWood, Enum.Material.Wood)
	for _, x in { -7.8, 7.8 } do
		prop(parent, "DeskSide", Vector3.new(0.4, 4.2, 3.2), desk * CFrame.new(x, 2.1, 3.9), deskWood, Enum.Material.Wood)
	end
	prop(parent, "DeskTop", Vector3.new(16.8, 0.35, 3.6), desk * CFrame.new(0, 4.4, 4.2), DARK_WOOD, Enum.Material.Wood)
	prop(parent, "BellBase", Vector3.new(0.14, 1.0, 1.0), desk * CFrame.new(-3, 4.65, 4.4) * UPRIGHT, BRASS, Enum.Material.Metal, 0, CYLINDER)
	prop(parent, "BellDome", Vector3.new(0.8, 0.8, 0.8), desk * CFrame.new(-3, 4.95, 4.4), BRASS, Enum.Material.Metal, 0, BALL)
	prop(parent, "GuestBook", Vector3.new(1.9, 0.18, 1.4), desk * CFrame.new(2.5, 4.67, 4.4), Color3.fromRGB(40, 24, 20), PLASTIC)
	prop(parent, "GuestBookPages", Vector3.new(1.75, 0.1, 1.25), desk * CFrame.new(2.5, 4.8, 4.4), Color3.fromRGB(222, 212, 185), PLASTIC)
	Decor.candle(parent, desk * Vector3.new(5.6, 4.58, 4.2), flames, 1.0)
	Decor.skull(parent, desk * CFrame.new(-6.2, 4.58, 4.3) * CFrame.Angles(0, -0.5, 0))
	Decor.pumpkin(parent, desk * CFrame.new(6.9, 4.58, 3.8) * CFrame.Angles(0, -0.3, 0), flames, 0.4)

	local board = desk * CFrame.new(0, 7.3, 0)
	prop(parent, "KeyBoard", Vector3.new(9, 4.2, 0.2), board * CFrame.new(0, 0, 0.1), DARK_WOOD, Enum.Material.Wood)
	for row = 0, 2 do
		for col = 0, 6 do
			if math.random() > 0.3 then -- some keys are gone
				local hook = board * CFrame.new((col - 3) * 1.2, 1.3 - row * 1.3, 0.2)
				prop(parent, "Hook", Vector3.new(0.12, 0.12, 0.2), hook, BRASS, Enum.Material.Metal)
				hangingKey(parent, hook)
			end
		end
	end
	local sign = prop(parent, "ReceptionSign", Vector3.new(8, 1.6, 0.3), desk * CFrame.new(0, 11.6, 0.15), Color3.fromRGB(20, 14, 12), Enum.Material.Wood)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back
	signGui.PixelsPerStud = 50
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "RECEPTION"
	signText.TextColor3 = Color3.fromRGB(215, 180, 100)
	signText.TextScaled = true
	signText.Font = Enum.Font.SpecialElite
	signText.Parent = signGui
	local vacancy = prop(parent, "NoVacancy", Vector3.new(3.4, 0.9, 0.2), desk * CFrame.new(5.6, 9.6, 0.3), Color3.fromRGB(70, 8, 10), Enum.Material.Neon)
	local vacancyGui = Instance.new("SurfaceGui")
	vacancyGui.Face = Enum.NormalId.Back
	vacancyGui.PixelsPerStud = 50
	vacancyGui.Parent = vacancy
	local vacancyText = Instance.new("TextLabel")
	vacancyText.Size = UDim2.fromScale(1, 1)
	vacancyText.BackgroundTransparency = 1
	vacancyText.Text = "NO VACANCY"
	vacancyText.TextColor3 = Color3.fromRGB(255, 70, 60)
	vacancyText.TextScaled = true
	vacancyText.Font = Enum.Font.SpecialElite
	vacancyText.Parent = vacancyGui

	-- Grandfather clock, bookshelves, portraits and windows around the walls
	Decor.clock(parent, Decor.place(P(35, 0, 14), east))
	Decor.bookshelf(parent, Decor.place(P(-35, 0, 12), west), 6, 10)
	Decor.bookshelf(parent, Decor.place(P(-35, 0, 21), west), 6, 10)
	Decor.portrait(parent, Decor.place(P(-35, 14, -26), west), "eyes", 3.4, 4.6)
	Decor.portrait(parent, Decor.place(P(35, 14, -26), east), "scratched", 3.4, 4.6)
	Decor.portrait(parent, Decor.place(P(35, 14, 26), east), "face", 3.4, 4.6)
	Decor.portrait(parent, Decor.place(P(-28, 14, -35), north), "face", 3.4, 4.6)
	Decor.portrait(parent, Decor.place(P(28, 14, -35), north), "eyes", 3.4, 4.6)
	Decor.window(parent, Decor.place(P(-12, 12, 35), south), 4.4, 8)
	Decor.window(parent, Decor.place(P(12, 12, 35), south), 4.4, 8)
	Decor.mirror(parent, Decor.place(P(0, 12, 35), south), 3.4, 5.4)

	-- Writing and handprints on the north wall, beyond the title sign
	Decor.writing(parent, Decor.place(P(-29, 9, -35), north), "THEY NEVER CHECKED OUT", 8, 2)
	for i, x in { 27, 29.5, 32 } do
		Decor.handprint(parent, Decor.place(P(x, 6.5 + i * 0.6, -35), north) * CFrame.Angles(0, 0, range(-0.3, 0.3)))
	end

	-- Cobwebs in every top corner
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Decor.cobweb(parent, P(sx * 34.6, 27.9, sz * 34.9), Vector3.new(-sx, 0, 0), 4.5)
			Decor.cobweb(parent, P(sx * 34.9, 27.9, sz * 34.6), Vector3.new(0, 0, -sz), 4.5)
		end
	end

	-- Jack-o'-lanterns, candle tables and dust-sheet chairs
	Decor.pumpkin(parent, Decor.place(P(9, 0, 30), Vector3.new(-0.5, 0, -1)), flames, 1)
	Decor.pumpkin(parent, Decor.place(P(-9, 0, 30), Vector3.new(0.5, 0, -1)), flames, 1)
	Decor.pumpkin(parent, Decor.place(P(32, 0, -20), Vector3.new(-1, 0, 0.3)), flames, 0.9)
	Decor.pumpkin(parent, Decor.place(P(-31, 0, -22), Vector3.new(1, 0, 0.3)), flames, 0.9)
	for _, x in { -16, 16 } do
		local tableAt = P(x, 0, 26)
		prop(parent, "SideTable", Vector3.new(0.2, 3.2, 3.2), CFrame.new(tableAt + Vector3.new(0, 2.7, 0)) * UPRIGHT, WOOD, Enum.Material.Wood, 0, CYLINDER)
		prop(parent, "SideTableStem", Vector3.new(2.5, 0.5, 0.5), CFrame.new(tableAt + Vector3.new(0, 1.25, 0)) * UPRIGHT, WOOD, Enum.Material.Wood, 0, CYLINDER)
		prop(parent, "SideTableFoot", Vector3.new(0.2, 2.2, 2.2), CFrame.new(tableAt + Vector3.new(0, 0.1, 0)) * UPRIGHT, WOOD, Enum.Material.Wood, 0, CYLINDER)
		Decor.candle(parent, tableAt + Vector3.new(0, 2.8, 0), flames, 1.1)
		Decor.candle(parent, tableAt + Vector3.new(0.9, 2.8, 0.4), flames, 0.7)
		Decor.candle(parent, tableAt + Vector3.new(-0.7, 2.8, -0.6), flames, 0.9, true)
	end
	Decor.coveredChair(parent, Decor.place(P(-30, 0, 30), Vector3.new(0.6, 0, -1)))
	Decor.coveredChair(parent, Decor.place(P(30, 0, 30), Vector3.new(-0.6, 0, -1)))
	Decor.coveredChair(parent, Decor.place(P(-30, 0, -29), Vector3.new(0.5, 0, 1)))

	-- A worn red rug on the walkway from the spawn to the vote pads
	prop(parent, "RugBorder", Vector3.new(14.8, 0.07, 26.8), CFrame.new(P(0, 0.035, 10)), Color3.fromRGB(140, 110, 56), Enum.Material.Fabric)
	prop(parent, "Rug", Vector3.new(13.6, 0.08, 25.6), CFrame.new(P(0, 0.04, 10)), Color3.fromRGB(82, 16, 24), Enum.Material.Fabric)

	-- Dust in the air and mist on the floor
	Decor.dust(parent, P(0, 13, 0), Vector3.new(66, 24, 66), 45)
	Decor.mist(parent, P(0, 1.2, 0), Vector3.new(66, 1.5, 66), 5)
end

return Decor
