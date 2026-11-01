-- GhostModel (ModuleScript in ReplicatedStorage)
-- The ghost's body, shared by the game (Ghost, on the server) and the escape cutscene (on the client),
-- so it looks the same in both: a gaunt figure in a tattered pale dress with long black hair,
-- hollow eyes and too-long arms.
--
-- Only the invisible Root part is moved. Every visible part hangs off it on a Motor6D, which
-- GhostModel.pose re-aims to make the dress flutter, the hair sway and the arms reach (or wave).

local GhostModel = {}

local NECK = CFrame.new(0, 3.0, 0) -- where the head joins the body, relative to Root

local DRESS = Color3.fromRGB(226, 230, 236)
local SKIN = Color3.fromRGB(205, 214, 220)
local HAIR = Color3.fromRGB(12, 10, 12)

-- Returns model, root, limbs. Move the ghost by setting root.CFrame, and animate it with GhostModel.pose.
function GhostModel.build(position)
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

-- Animates the ghost. p holds:
--   Lean (radians, negative leans forward), Reach (0..1 arms raised forward), HeadYaw, HeadPitch,
--   Speed (studs/second, makes the hem and hair flutter more), Wave (0..1: how much the right arm waves hello)
function GhostModel.pose(limbs, p, now)
	local bodyBase = CFrame.Angles(p.Lean, 0, 0)
	local headBase = bodyBase * NECK * CFrame.Angles(p.HeadPitch, p.HeadYaw, math.sin(now * 0.7) * 0.05)
	local flutterScale = 1 + p.Speed * 0.1

	for _, limb in limbs do
		local base = limb.Group == "head" and headBase or bodyBase
		local rotation = CFrame.new()
		if limb.Kind == "flutter" then
			rotation = CFrame.Angles(
				math.sin(now * 1.9 + limb.Phase) * limb.Param * flutterScale,
				0,
				math.cos(now * 1.4 + limb.Phase) * limb.Param * 0.5 * flutterScale
			)
		elseif limb.Kind == "arm" then
			local raise = p.Reach * 1.3 + math.sin(now * 1.1 + limb.Phase) * 0.06
			local out = limb.Param * (0.14 + math.sin(now * 0.9 + limb.Phase) * 0.04)
			local wave = limb.Param == 1 and (p.Wave or 0) or 0
			if wave > 0 then
				-- The right arm lifts high and swings from side to side, blending in as Wave goes 0 -> 1
				raise += (2.7 + math.sin(now * 3) * 0.1 - raise) * wave
				out += (0.45 * math.sin(now * 7) - out) * wave
			end
			rotation = CFrame.Angles(raise, 0, out)
		end
		limb.Motor.C0 = base * limb.Attach * rotation * limb.Local
	end
end

return GhostModel
