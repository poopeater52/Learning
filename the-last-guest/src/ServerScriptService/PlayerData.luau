-- PlayerData (ModuleScript in ServerScriptService)
-- Remembers each player's relic collection and escape count between visits.
-- Relics are copied onto the player as attributes named "Relic_<Id>" so the HUD can show them.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local PlayerData = {}

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local sessions = {} -- [Player] = { Relics = { [id] = count }, Escapes = number }
local canSave = {} -- [Player] = true only if their data loaded, so a failed load can never wipe a save

local function keyFor(player)
	return "Player_" .. player.UserId
end

local function loadFromStore(player)
	local success, data
	for attempt = 1, 3 do
		success, data = pcall(function()
			return store:GetAsync(keyFor(player))
		end)
		if success then
			break
		end
		task.wait(attempt)
	end

	if success then
		canSave[player] = true
		return data or {}
	end

	warn("[TheLastGuest] Could not load data for " .. player.Name .. ". Progress won't be saved this visit. (" .. tostring(data) .. ")")
	return {}
end

local function publishAttributes(player)
	local session = sessions[player]
	if not session then
		return
	end
	for _, relic in Config.Relics do
		player:SetAttribute("Relic_" .. relic.Id, session.Relics[relic.Id] or 0)
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Escapes.Value = session.Escapes
	end
end

local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local escapes = Instance.new("IntValue")
	escapes.Name = "Escapes"
	escapes.Parent = leaderstats
	leaderstats.Parent = player

	local data = loadFromStore(player)
	if player.Parent == nil then
		return -- they left while we were loading
	end

	local session = { Relics = {}, Escapes = 0 }
	if type(data.Escapes) == "number" then
		session.Escapes = data.Escapes
	end
	if type(data.Relics) == "table" then
		for id, count in data.Relics do
			if Config.GetRelic(id) and type(count) == "number" then
				session.Relics[id] = count
			end
		end
	end
	sessions[player] = session
	publishAttributes(player)
end

local function save(player)
	local session = sessions[player]
	if not session or not canSave[player] then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(keyFor(player), { Relics = session.Relics, Escapes = session.Escapes })
	end)
	if not ok then
		warn("[TheLastGuest] Could not save data for " .. player.Name .. ": " .. tostring(err))
	end
end

-- Adds one copy of a relic. Returns false if the player's data hasn't loaded yet.
function PlayerData.AwardRelic(player, relicId)
	local session = sessions[player]
	if not session or not Config.GetRelic(relicId) then
		return false
	end
	session.Relics[relicId] = (session.Relics[relicId] or 0) + 1
	publishAttributes(player)
	return true
end

function PlayerData.RecordEscape(player)
	local session = sessions[player]
	if session then
		session.Escapes += 1
		publishAttributes(player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	sessions[player] = nil
	canSave[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	task.wait(2)
end)

task.spawn(function()
	while true do
		task.wait(Config.AutosaveInterval)
		for _, player in Players:GetPlayers() do
			save(player)
		end
	end
end)

return PlayerData
