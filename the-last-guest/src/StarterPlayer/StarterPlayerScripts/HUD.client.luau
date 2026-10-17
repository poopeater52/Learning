-- HUD (LocalScript in StarterPlayer > StarterPlayerScripts)
-- Draws everything the player sees on screen, runs the flashlight, and plays the jump scare.
-- All the UI is created by this script, so there is nothing to build by hand.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local state = ReplicatedStorage:WaitForChild("GameState")
local JumpScare = ReplicatedStorage:WaitForChild("JumpScare")
local Notify = ReplicatedStorage:WaitForChild("Notify")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PAPER = Color3.fromRGB(235, 225, 205)

local function make(className, props, parent)
	local object = Instance.new(className)
	for key, value in props do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local gui = make("ScreenGui", { Name = "TheLastGuestHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10 }, playerGui)

-- Top of the screen: objective and info -------------------------------------------

local messageLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0.7, 0, 0, 44),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
	TextColor3 = PAPER,
	TextScaled = true,
	Font = Enum.Font.Creepster,
	Text = "",
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, messageLabel)
make("UITextSizeConstraint", { MaxTextSize = 32 }, messageLabel)

local infoLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 62),
	Size = UDim2.new(0.5, 0, 0, 28),
	BackgroundTransparency = 1,
	TextColor3 = PAPER,
	TextStrokeTransparency = 0.5,
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	Text = "",
}, gui)
make("UITextSizeConstraint", { MaxTextSize = 20 }, infoLabel)

-- Pop-up notices (key found, ghost woke, relics won) ------------------------------

local toastHolder = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 100),
	Size = UDim2.new(0.6, 0, 0, 200),
	BackgroundTransparency = 1,
}, gui)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, toastHolder)

local toastCount = 0
local function toast(text, color)
	toastCount += 1
	local label = make("TextLabel", {
		LayoutOrder = toastCount,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		TextColor3 = color or PAPER,
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		Text = text,
	}, toastHolder)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, label)
	make("UITextSizeConstraint", { MaxTextSize = 18 }, label)

	task.delay(5, function()
		local info = TweenInfo.new(1)
		TweenService:Create(label, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(1)
		label:Destroy()
	end)
end

Notify.OnClientEvent:Connect(toast)

-- Status text ---------------------------------------------------------------------

local function refresh()
	local status = state:GetAttribute("Status")
	local countdown = state:GetAttribute("Countdown") or 0
	messageLabel.Text = state:GetAttribute("Message") or ""

	if status == "Playing" then
		infoLabel.Text = string.format(
			"Keys %d/%d     Time %d:%02d     %s",
			state:GetAttribute("KeysFound") or 0,
			state:GetAttribute("KeysNeeded") or 0,
			countdown // 60,
			countdown % 60,
			state:GetAttribute("Difficulty") or ""
		)
	elseif status == "Intermission" and countdown > 0 then
		infoLabel.Text = "Next night in " .. countdown .. "s"
	else
		infoLabel.Text = ""
	end
end
state.AttributeChanged:Connect(refresh)
refresh()

-- Relic collection panel -----------------------------------------------------------

local relicsButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 150, 0, 40),
	BackgroundColor3 = Color3.fromRGB(40, 28, 28),
	BorderSizePixel = 0,
	TextColor3 = PAPER,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	Text = "Relics (R)",
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, relicsButton)

local relicsPanel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 460, 0, 420),
	BackgroundColor3 = Color3.fromRGB(22, 16, 16),
	BorderSizePixel = 0,
	Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, relicsPanel)

local relicsTitle = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	TextColor3 = PAPER,
	TextSize = 30,
	Font = Enum.Font.Creepster,
	Text = "Relics",
}, relicsPanel)

local relicList = make("ScrollingFrame", {
	Position = UDim2.new(0, 10, 0, 50),
	Size = UDim2.new(1, -20, 1, -60),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, relicsPanel)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, relicList)

-- Show relics grouped by rarity, rarest last
local sortedRelics = {}
for _, rarity in Config.RarityOrder do
	for _, relic in Config.Relics do
		if relic.Rarity == rarity then
			table.insert(sortedRelics, relic)
		end
	end
end

local function refreshRelics()
	for _, child in relicList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local ownedKinds = 0
	for order, relic in sortedRelics do
		local count = player:GetAttribute("Relic_" .. relic.Id) or 0
		local rarityColor = Config.Rarities[relic.Rarity].Color
		local label = make("TextLabel", {
			LayoutOrder = order,
			Size = UDim2.new(1, -8, 0, 40),
			BackgroundColor3 = Color3.fromRGB(34, 26, 26),
			BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextWrapped = true,
		}, relicList)
		make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, label)
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, label)

		if count > 0 then
			ownedKinds += 1
			label.TextColor3 = rarityColor
			label.Text = string.format("%s  x%d  [%s]\n%s", relic.Name, count, relic.Rarity, relic.Blurb)
		else
			label.TextColor3 = Color3.fromRGB(110, 110, 110)
			label.Text = string.format("???  [%s]\nEscape the hotel to find it.", relic.Rarity)
		end
	end
	relicsTitle.Text = string.format("Relics  %d/%d", ownedKinds, #sortedRelics)
end

player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 6) == "Relic_" then
		refreshRelics()
	end
end)
refreshRelics()

local function toggleRelics()
	relicsPanel.Visible = not relicsPanel.Visible
end
relicsButton.Activated:Connect(toggleRelics)

-- Flashlight -------------------------------------------------------------------------
-- An invisible part with a spotlight follows the camera, so the beam always points where you look.

local flashlightOn = true

local flashlightButton = make("TextButton", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -16),
	Size = UDim2.new(0, 150, 0, 40),
	BackgroundColor3 = Color3.fromRGB(40, 28, 28),
	BorderSizePixel = 0,
	TextColor3 = PAPER,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	Text = "Flashlight (F)",
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, flashlightButton)

local function toggleFlashlight()
	flashlightOn = not flashlightOn
end
flashlightButton.Activated:Connect(toggleFlashlight)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		toggleFlashlight()
	elseif input.KeyCode == Enum.KeyCode.R then
		toggleRelics()
	end
end)

local flashlightRig = make("Part", {
	Name = "FlashlightRig",
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Transparency = 1,
	Size = Vector3.new(0.5, 0.5, 0.5),
}, nil)
local spotlight = make("SpotLight", {
	Brightness = 3,
	Range = 60,
	Angle = 60,
	Face = Enum.NormalId.Front,
	Color = Color3.fromRGB(255, 244, 214),
	Shadows = true,
}, flashlightRig)

-- First person during a night -----------------------------------------------------

local function applyCameraMode()
	if Config.ForceFirstPerson and player:GetAttribute("InRound") == true then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		player.CameraMode = Enum.CameraMode.Classic
	end
end
player:GetAttributeChangedSignal("InRound"):Connect(applyCameraMode)
applyCameraMode()

-- Jump scare ------------------------------------------------------------------------

local scareFrame = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(120, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 50,
}, gui)
local scareText = make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextTransparency = 1,
	TextScaled = true,
	Font = Enum.Font.Creepster,
	Text = "CAUGHT",
	ZIndex = 51,
}, scareFrame)

local scareUntil = 0
local shaking = false

JumpScare.OnClientEvent:Connect(function()
	scareFrame.BackgroundTransparency = 0
	scareText.TextTransparency = 0
	scareUntil = os.clock() + 0.6

	task.delay(0.6, function()
		local info = TweenInfo.new(1.2)
		TweenService:Create(scareFrame, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(scareText, info, { TextTransparency = 1 }):Play()
	end)
end)

-- Runs every frame ----------------------------------------------------------------------

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	if flashlightRig.Parent ~= camera then
		flashlightRig.Parent = camera
	end
	flashlightRig.CFrame = camera.CFrame
	spotlight.Enabled = flashlightOn and player:GetAttribute("InRound") == true

	-- Camera shake while the scare plays
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if os.clock() < scareUntil then
			shaking = true
			humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * 0.8, (math.random() - 0.5) * 0.8, 0)
		elseif shaking then
			shaking = false
			humanoid.CameraOffset = Vector3.zero
		end
	end
end)
