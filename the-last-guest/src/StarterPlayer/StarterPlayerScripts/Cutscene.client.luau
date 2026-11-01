-- Cutscene (LocalScript in StarterPlayer > StarterPlayerScripts)
-- Plays when you escape the hotel: a fast car pulls away from the front door. Through its rear window you
-- see the ghost, standing in an upstairs window, wave goodbye. Then "YOU ESCAPED" fades in.
--
-- The whole scene is built here, on your screen only, far away from the game, and removed afterwards.
-- Nothing in it is saved or shown to other players.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local GhostModel = require(ReplicatedStorage:WaitForChild("GhostModel"))
local CutsceneEvent = ReplicatedStorage:WaitForChild("Cutscene")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local STAGE = Vector3.new(4000, 200, 0) -- where the scene is built: far from anything in the game
local TOTAL = math.max(Config.CutsceneTime, 11) -- seconds

local PAPER = Color3.fromRGB(235, 225, 205)

-- Stage coordinates -> world coordinates
local function L(x, y, z)
	return STAGE + Vector3.new(x, y, z)
end

local function ease(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function part(parent, name, size, position, color, material, transparency, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = typeof(position) == "CFrame" and position or CFrame.new(position)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function glow(parent, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Parent = parent
	return light
end

-- The scene ---------------------------------------------------------------------------------
-- The hotel front faces +Z. The road runs away from it along +Z. The car drives down the road.

local function buildHotel(stage)
	local rng = Random.new(5)
	local wall = Color3.fromRGB(58, 42, 44)

	part(stage, "HotelBody", Vector3.new(100, 46, 30), L(0, 23, -15), wall, Enum.Material.Brick)
	part(stage, "Roof", Vector3.new(106, 3, 36), L(0, 47.5, -15), Color3.fromRGB(26, 20, 22), Enum.Material.Slate)
	part(stage, "Chimney", Vector3.new(5, 9, 5), L(-30, 53, -15), wall, Enum.Material.Brick)
	part(stage, "Chimney", Vector3.new(5, 9, 5), L(34, 53, -15), wall, Enum.Material.Brick)

	-- Windows: mostly dark, some with a warm light on
	for _, y in { 8, 36 } do
		for _, x in { -42, -30, -18, 18, 30, 42 } do
			local lit = rng:NextNumber() < 0.28
			part(
				stage,
				"Window",
				Vector3.new(5, 7, 0.3),
				L(x, y, 0.15),
				lit and Color3.fromRGB(255, 176, 90) or Color3.fromRGB(10, 12, 16),
				lit and Enum.Material.Neon or Enum.Material.Glass,
				lit and 0.35 or 0.15
			)
		end
	end
	for _, y in { 22 } do
		for _, x in { -42, -30, -18, 18, 30, 42 } do
			local lit = rng:NextNumber() < 0.28
			part(stage, "Window", Vector3.new(5, 7, 0.3), L(x, y, 0.15), lit and Color3.fromRGB(255, 176, 90) or Color3.fromRGB(10, 12, 16), lit and Enum.Material.Neon or Enum.Material.Glass, lit and 0.35 or 0.15)
		end
	end
	part(stage, "Window", Vector3.new(5, 7, 0.3), L(0, 37, 0.15), Color3.fromRGB(10, 12, 16), Enum.Material.Glass, 0.15)

	-- Front door, steps, porch lamps and the sign
	part(stage, "Steps", Vector3.new(16, 0.6, 5), L(0, 0.3, 3), Color3.fromRGB(70, 70, 74), Enum.Material.Concrete)
	part(stage, "Door", Vector3.new(8, 10, 0.5), L(0, 5.6, 0.25), Color3.fromRGB(96, 58, 32), Enum.Material.Wood)
	for _, x in { -7, 7 } do
		local lamp = part(stage, "PorchLamp", Vector3.new(1, 1.4, 1), L(x, 9, 1.4), Color3.fromRGB(255, 214, 150), Enum.Material.Neon)
		glow(lamp, Color3.fromRGB(255, 190, 120), 2, 40)
	end
	local sign = part(stage, "Sign", Vector3.new(24, 3, 0.6), L(0, 11.5, 0.3), Color3.fromRGB(16, 12, 12), Enum.Material.Wood)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- Back = +Z, toward the road
	gui.PixelsPerStud = 40
	gui.Parent = sign
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "THE LAST GUEST"
	text.TextColor3 = Color3.fromRGB(215, 40, 40)
	text.TextScaled = true
	text.Font = Enum.Font.Creepster
	text.Parent = gui

	-- The bay window where the ghost stands: a shallow glass box on the front of the hotel
	local wood = Color3.fromRGB(44, 30, 24)
	part(stage, "BayBack", Vector3.new(10, 14, 0.2), L(0, 21, 0.1), Color3.fromRGB(14, 12, 16))
	part(stage, "BayTop", Vector3.new(10.6, 0.6, 3.8), L(0, 28.3, 1.8), wood, Enum.Material.Wood)
	part(stage, "BaySill", Vector3.new(10.6, 0.6, 3.8), L(0, 13.7, 1.8), wood, Enum.Material.Wood)
	part(stage, "BaySide", Vector3.new(0.6, 14.6, 3.8), L(-5.3, 21, 1.8), wood, Enum.Material.Wood)
	part(stage, "BaySide", Vector3.new(0.6, 14.6, 3.8), L(5.3, 21, 1.8), wood, Enum.Material.Wood)
	part(stage, "BayGlass", Vector3.new(10, 14, 0.15), L(0, 21, 3.5), Color3.fromRGB(150, 170, 200), Enum.Material.Glass, 0.6)
	part(stage, "Mullion", Vector3.new(0.3, 14, 0.2), L(0, 21, 3.6), wood, Enum.Material.Wood)
	part(stage, "Mullion", Vector3.new(10, 0.3, 0.2), L(0, 21, 3.6), wood, Enum.Material.Wood)

	-- Cold light inside the bay so the ghost can be seen from far away
	local bulb = part(stage, "BayLight", Vector3.new(0.5, 0.5, 0.5), L(0, 24, 2), Color3.fromRGB(170, 200, 255), Enum.Material.Neon, 1)
	glow(bulb, Color3.fromRGB(160, 190, 255), 3, 22)
end

local function buildGround(stage)
	part(stage, "Ground", Vector3.new(900, 1, 1500), L(0, -0.5, 700), Color3.fromRGB(16, 22, 16), Enum.Material.Grass)
	part(stage, "Road", Vector3.new(24, 0.2, 1500), L(0, 0.05, 700), Color3.fromRGB(30, 30, 34), Enum.Material.Asphalt)
	for z = 24, 1000, 14 do
		part(stage, "RoadLine", Vector3.new(0.7, 0.1, 6), L(0, 0.2, z), Color3.fromRGB(220, 190, 60))
	end

	-- Bare dead trees along the road
	local rng = Random.new(11)
	for i = 1, 44 do
		local side = (i % 2 == 0) and 1 or -1
		local x = side * (22 + rng:NextNumber() * 40)
		local z = 30 + i * 21
		local height = 18 + rng:NextNumber() * 10
		local bark = Color3.fromRGB(26, 19, 15)
		part(stage, "Trunk", Vector3.new(height, 2.2, 2.2), CFrame.new(L(x, height / 2, z)) * CFrame.Angles(0, 0, math.pi / 2), bark, Enum.Material.Wood, 0, Enum.PartType.Cylinder)
		for b = 1, 3 do
			local angle = rng:NextNumber() * math.pi * 2
			local yy = height * (0.5 + 0.15 * b)
			local reach = 5 + rng:NextNumber() * 3
			part(
				stage,
				"Branch",
				Vector3.new(reach, 0.6, 0.6),
				CFrame.new(L(x, yy, z)) * CFrame.Angles(0, angle, 0.5) * CFrame.new(reach / 2, 0, 0),
				bark,
				Enum.Material.Wood
			)
		end
	end
end

-- A red car. It is built facing +Z, so it drives down the road away from the hotel.
local function buildCar(stage)
	local car = Instance.new("Model")
	car.Name = "Car"
	local red = Color3.fromRGB(130, 16, 22)
	local black = Color3.fromRGB(14, 14, 16)

	local body = part(car, "Body", Vector3.new(7, 1.8, 15), Vector3.new(0, 1.7, 0), red, Enum.Material.SmoothPlastic)
	car.PrimaryPart = body
	body.Reflectance = 0.25
	part(car, "Hood", Vector3.new(6.6, 0.8, 3.5), Vector3.new(0, 2.8, 5), red)
	part(car, "Cabin", Vector3.new(6.2, 1.8, 7.2), Vector3.new(0, 3.5, -1.3), red)
	part(car, "Windshield", Vector3.new(5.8, 1.5, 0.2), Vector3.new(0, 3.5, 2.35), Color3.fromRGB(20, 26, 34), Enum.Material.Glass, 0.5)
	part(car, "RearWindow", Vector3.new(5.8, 1.5, 0.2), Vector3.new(0, 3.5, -4.95), Color3.fromRGB(20, 26, 34), Enum.Material.Glass, 0.5)
	part(car, "BumperFront", Vector3.new(7.2, 0.6, 0.5), Vector3.new(0, 1.0, 7.7), black)
	part(car, "BumperBack", Vector3.new(7.2, 0.6, 0.5), Vector3.new(0, 1.0, -7.7), black)
	for _, x in { -3.5, 3.5 } do
		for _, z in { -4.8, 4.8 } do
			part(car, "Wheel", Vector3.new(1.2, 3, 3), Vector3.new(x, 1.5, z), black, Enum.Material.SmoothPlastic, 0, Enum.PartType.Cylinder)
		end
	end
	for _, x in { -2.3, 2.3 } do
		local head = part(car, "Headlight", Vector3.new(1.4, 0.8, 0.3), Vector3.new(x, 2, 7.55), Color3.fromRGB(255, 250, 225), Enum.Material.Neon)
		local beam = Instance.new("SpotLight")
		beam.Face = Enum.NormalId.Back -- +Z: the way the car is heading
		beam.Angle = 55
		beam.Range = 70
		beam.Brightness = 5
		beam.Color = Color3.fromRGB(255, 244, 214)
		beam.Parent = head

		local tail = part(car, "Taillight", Vector3.new(1.4, 0.7, 0.3), Vector3.new(x, 2.2, -7.55), Color3.fromRGB(255, 30, 30), Enum.Material.Neon)
		glow(tail, Color3.fromRGB(255, 40, 40), 1.5, 14)
	end
	car.Parent = stage
	return car
end

-- The screen ------------------------------------------------------------------------------------

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for key, value in props do
		f[key] = value
	end
	f.Parent = parent
	return f
end

local function buildScreen(relicText, relicColor, titleText)
	local gui = Instance.new("ScreenGui")
	gui.Name = "EscapeCutscene"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.Parent = playerGui

	local seat = Color3.fromRGB(8, 8, 10)

	-- The inside of the car, seen from the back seat: a window frame, headrests and the mirror
	local window = frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 5 })
	frame(window, { Size = UDim2.fromScale(1, 0.12), BackgroundColor3 = seat, ZIndex = 5 })
	frame(window, { Position = UDim2.fromScale(0, 0.82), Size = UDim2.fromScale(1, 0.18), BackgroundColor3 = seat, ZIndex = 5 })
	frame(window, { Size = UDim2.fromScale(0.07, 1), BackgroundColor3 = seat, ZIndex = 5 })
	frame(window, { Position = UDim2.fromScale(0.93, 0), Size = UDim2.fromScale(0.07, 1), BackgroundColor3 = seat, ZIndex = 5 })
	frame(window, { Position = UDim2.fromScale(0.07, 0.12), Size = UDim2.fromScale(0.86, 0.7), BackgroundColor3 = Color3.fromRGB(10, 14, 22), BackgroundTransparency = 0.88, ZIndex = 4 })
	local mirror = frame(window, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.025), Size = UDim2.fromScale(0.22, 0.085), BackgroundColor3 = Color3.fromRGB(22, 22, 26), ZIndex = 6 })
	Instance.new("UICorner", mirror).CornerRadius = UDim.new(0, 12)
	for _, x in { 0.17, 0.71 } do
		local headrest = frame(window, { Position = UDim2.fromScale(x, 0.74), Size = UDim2.fromScale(0.12, 0.3), BackgroundColor3 = Color3.fromRGB(18, 18, 22), ZIndex = 6 })
		Instance.new("UICorner", headrest).CornerRadius = UDim.new(0, 40)
	end

	-- Cinema bars
	frame(gui, { Size = UDim2.fromScale(1, 0.1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 20 })
	frame(gui, { Position = UDim2.fromScale(0, 0.9), Size = UDim2.fromScale(1, 0.1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 20 })

	-- "YOU ESCAPED"
	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.42)
	title.Size = UDim2.fromScale(0.8, 0.22)
	title.BackgroundTransparency = 1
	title.Text = titleText or "YOU ESCAPED"
	title.Font = Enum.Font.Creepster
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(240, 240, 245)
	title.TextTransparency = 1
	title.ZIndex = 30
	title.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.Color = Color3.fromRGB(150, 15, 20)
	stroke.Transparency = 1
	stroke.Parent = title

	local subtitle = Instance.new("TextLabel")
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.fromScale(0.5, 0.56)
	subtitle.Size = UDim2.fromScale(0.8, 0.05)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = relicText
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextScaled = true
	subtitle.TextColor3 = relicColor or PAPER
	subtitle.TextStrokeTransparency = 1
	subtitle.TextTransparency = 1
	subtitle.ZIndex = 30
	subtitle.Parent = gui
	Instance.new("UITextSizeConstraint", subtitle).MaxTextSize = 26

	-- Full-screen black used for fades and the cut between shots
	local fade = frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0, ZIndex = 50 })

	return { Gui = gui, Window = window, Title = title, Stroke = stroke, Subtitle = subtitle, Fade = fade }
end

-- Playing it ---------------------------------------------------------------------------------------

local function setControls(enabled)
	local ok, controls = pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
	end)
	if ok and controls then
		if enabled then
			controls:Enable()
		else
			controls:Disable()
		end
	end
end

-- How far down the road the car is. It sits still, then pulls away fast.
local function carDistance(t)
	local drive = t - 2.0
	if drive <= 0 then
		return 14
	elseif drive < 1.8 then
		return 14 + 0.5 * 60 * drive * drive
	end
	return math.min(14 + 97.2 + 110 * (drive - 1.8), 900)
end

local playing = false

local function play(relicText, relicColor, titleText)
	if playing then
		return
	end
	playing = true

	local camera = workspace.CurrentCamera
	local hud = playerGui:FindFirstChild("TheLastGuestHUD")
	local saved = {
		Ambient = Lighting.Ambient,
		FogColor = Lighting.FogColor,
		FogStart = Lighting.FogStart,
		FogEnd = Lighting.FogEnd,
	}
	local stage, screen

	local function cleanup()
		if stage then
			stage:Destroy()
		end
		if screen then
			screen.Gui:Destroy()
		end
		Lighting.Ambient = saved.Ambient
		Lighting.FogColor = saved.FogColor
		Lighting.FogStart = saved.FogStart
		Lighting.FogEnd = saved.FogEnd
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
		if hud then
			hud.Enabled = true
		end
		setControls(true)
		playing = false
	end

	local ok, err = pcall(function()
		setControls(false)
		if hud then
			hud.Enabled = false
		end
		camera.CameraType = Enum.CameraType.Scriptable

		-- A little more light and haze than the game, so the hotel can be seen from the road
		Lighting.Ambient = Color3.fromRGB(34, 38, 58)
		Lighting.FogColor = Color3.fromRGB(10, 12, 20)
		Lighting.FogStart = 200
		Lighting.FogEnd = 1400

		screen = buildScreen(relicText or "", relicColor, titleText)
		stage = Instance.new("Folder")
		stage.Name = "EscapeCutsceneStage"
		stage.Parent = workspace

		buildGround(stage)
		buildHotel(stage)
		local car = buildCar(stage)

		-- The ghost, standing in the bay window facing the road
		local ghost, ghostRoot, limbs = GhostModel.build(L(0, 18, 1.6))
		local ghostBase = CFrame.new(L(0, 18, 1.6)) * CFrame.Angles(0, math.pi, 0) -- turned to face +Z
		ghostRoot.CFrame = ghostBase
		ghost.Parent = stage

		local carHidden = false
		local start = os.clock()

		while true do
			local t = os.clock() - start
			if t >= TOTAL then
				break
			end

			-- Car
			local z = carDistance(t)
			car:PivotTo(CFrame.new(L(4, 1.7, z))) -- the car's pivot is its body, which sits 1.7 studs above the ground

			-- Ghost: stands still, then waves as the car leaves
			ghostRoot.CFrame = ghostBase * CFrame.new(0, 0.12 * math.sin(t * 2.3), 0)
			GhostModel.pose(limbs, {
				Lean = 0,
				Reach = 0.1,
				HeadYaw = math.sin(t * 1.3) * 0.25,
				HeadPitch = 0,
				Speed = 0,
				Wave = ease((t - 2.2) / 0.8),
			}, os.clock())

			if t < 3 then
				-- Shot 1: the hotel front at night, the car about to leave. The camera drifts in, then drops to the car.
				local a = t / 3
				local camPos = L(-26 + 16 * a, 7 + a, 46 - 12 * a)
				local target = L(0, 15, 0):Lerp(L(4, 4, z), ease(a))
				camera.CFrame = CFrame.lookAt(camPos, target)
				camera.FieldOfView = 60
			else
				-- Shot 2: from the back seat, looking out of the rear window at the ghost waving from the hotel.
				-- The lens zooms in as the car speeds away, so the window stays in view while the road races past.
				if not carHidden then
					carHidden = true
					for _, descendant in car:GetDescendants() do
						if descendant:IsA("BasePart") then
							descendant.Transparency = 1 -- we are inside it now
						end
					end
					screen.Window.Visible = true
				end
				local distance = z + 2.3
				local viewHeight = 46 - 20 * ease((t - 3) / 5) -- studs of the hotel kept in view; smaller = closer on the ghost
				local shake = Vector3.new(math.noise(t * 9, 1) * 0.06, math.noise(t * 9, 2) * 0.06, 0)
				camera.CFrame = CFrame.lookAt(L(4, 3.7, z - 2.3) + shake, L(0, 21.5, 1.6))
				camera.FieldOfView = math.clamp(math.deg(2 * math.atan(viewHeight / (2 * distance))), 4, 70)
			end

			-- Fades: in at the start, a quick blink at the cut, out at the end
			local black = 0
			if t < 0.6 then
				black = 1 - t / 0.6
			elseif t > 2.85 and t < 3.0 then
				black = (t - 2.85) / 0.15
			elseif t >= 3.0 and t < 3.2 then
				black = 1 - (t - 3.0) / 0.2
			elseif t > TOTAL - 1.2 then
				black = (t - (TOTAL - 1.2)) / 1.2
			end
			screen.Fade.BackgroundTransparency = 1 - math.clamp(black, 0, 1)

			-- "YOU ESCAPED"
			local titleAlpha = ease((t - 6.8) / 1.0)
			screen.Title.TextTransparency = 1 - titleAlpha
			screen.Stroke.Transparency = 1 - titleAlpha
			screen.Subtitle.TextTransparency = 1 - ease((t - 7.8) / 0.8)

			RunService.RenderStepped:Wait()
		end
	end)

	cleanup()
	if not ok then
		warn("[TheLastGuest] The escape cutscene hit a problem: " .. tostring(err))
	end
end

CutsceneEvent.OnClientEvent:Connect(play)
