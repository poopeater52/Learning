-- GameConfig (ModuleScript in ReplicatedStorage)
-- Every number that controls the game lives here. To balance the game,
-- change values in this file; the other scripts read from it.

local Config = {}

-- Rounds ------------------------------------------------------------------
Config.MinPlayers = 1 -- 1 so you can test alone. Raise to 2+ when you launch.
Config.IntermissionTime = 25 -- seconds in the lobby (voting time) between nights
Config.GhostWakeDelay = 12 -- seconds of calm before the ghost wakes up
Config.EndScreenTime = 8 -- seconds the result is shown

-- Lobby ---------------------------------------------------------------------
Config.LobbyCenter = Vector3.new(0, 500, 0) -- high above the hotel so they never overlap

-- Hotel size (studs) --------------------------------------------------------
Config.RoomsPerSide = 4 -- 4 rooms on each side of the corridor = 8 rooms
Config.RoomWidth = 24
Config.RoomDepth = 22
Config.CorridorWidth = 12
Config.WallHeight = 14
Config.DoorWidth = 8
Config.DoorHeight = 9
Config.ExitHallLength = 14

-- Players ---------------------------------------------------------------------
Config.PlayerWalkSpeed = 16
Config.ForceFirstPerson = true -- first person during a night (scarier, flashlight points where you look)

-- Ghost -----------------------------------------------------------------------
Config.GhostCatchRange = 4.5 -- studs: closer than this and you are caught
Config.GhostStunTime = 1.5 -- seconds the ghost pauses after catching someone
Config.GhostSearchTime = 7 -- seconds it searches where it last saw you
Config.GhostPatrolSpeedScale = 0.6 -- patrol speed = GhostSpeed * this
Config.GhostSearchSpeedScale = 0.85
Config.GhostThinkInterval = 0.35 -- how often the ghost makes decisions

-- Saving ----------------------------------------------------------------------
-- Saving only works in a PUBLISHED game with "Enable Studio Access to API Services" turned on.
-- The game still plays fine without it, progress just won't be remembered.
Config.DataStoreName = "TheLastGuest_v1"
Config.AutosaveInterval = 90

-- Difficulties ------------------------------------------------------------------
-- Keys = keys to find, TimeLimit = seconds, GhostSpeed = studs/second while chasing
-- (players walk at 16), GhostSight = how far it can see you, GhostHear = how close
-- you can be before it hears you even through walls, HuntChance = how often it
-- walks straight toward a player instead of wandering, RelicRolls = relics won on escape.
Config.DifficultyOrder = { "Easy", "Normal", "Nightmare" }
Config.Difficulties = {
	Easy = {
		Color = Color3.fromRGB(80, 200, 110),
		Keys = 3,
		TimeLimit = 480,
		GhostSpeed = 10,
		GhostSight = 40,
		GhostHear = 9,
		HuntChance = 0,
		RelicRolls = 1,
		RarityWeights = { Common = 70, Uncommon = 22, Rare = 7, Epic = 1, Legendary = 0.1 },
	},
	Normal = {
		Color = Color3.fromRGB(240, 190, 60),
		Keys = 4,
		TimeLimit = 390,
		GhostSpeed = 13,
		GhostSight = 60,
		GhostHear = 12,
		HuntChance = 0.15,
		RelicRolls = 2,
		RarityWeights = { Common = 50, Uncommon = 30, Rare = 14, Epic = 5, Legendary = 1 },
	},
	Nightmare = {
		Color = Color3.fromRGB(220, 50, 50),
		Keys = 5,
		TimeLimit = 330,
		GhostSpeed = 15,
		GhostSight = 80,
		GhostHear = 15,
		HuntChance = 0.35,
		RelicRolls = 3,
		RarityWeights = { Common = 30, Uncommon = 30, Rare = 24, Epic = 12, Legendary = 4 },
	},
}

-- Relics ------------------------------------------------------------------------
-- Relics are collectibles only. They never make you stronger, so there is nothing to
-- "win" by buying them. Id must use only letters and numbers (no spaces).
Config.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
Config.Rarities = {
	Common = { Color = Color3.fromRGB(190, 190, 190) },
	Uncommon = { Color = Color3.fromRGB(90, 200, 120) },
	Rare = { Color = Color3.fromRGB(80, 150, 255) },
	Epic = { Color = Color3.fromRGB(180, 90, 255) },
	Legendary = { Color = Color3.fromRGB(255, 185, 50) },
}

Config.Relics = {
	{ Id = "CrackedMusicBox", Name = "Cracked Music Box", Rarity = "Common", Blurb = "It still plays, but only one note." },
	{ Id = "RustyRoomKey", Name = "Rusty Room Key", Rarity = "Common", Blurb = "Opens a room that no longer exists." },
	{ Id = "FadedPhotograph", Name = "Faded Photograph", Rarity = "Common", Blurb = "Everyone in it is facing away." },
	{ Id = "MeltedCandle", Name = "Melted Candle", Rarity = "Common", Blurb = "Warm to the touch. Nobody lit it." },
	{ Id = "PorcelainDoll", Name = "Porcelain Doll", Rarity = "Uncommon", Blurb = "Its eyes were open when you picked it up." },
	{ Id = "BellhopsCap", Name = "Bellhop's Cap", Rarity = "Uncommon", Blurb = "Still has a name tag: 'Ask for Arthur'." },
	{ Id = "TarnishedLocket", Name = "Tarnished Locket", Rarity = "Uncommon", Blurb = "The hinge creaks when no one is near." },
	{ Id = "GuestLedger", Name = "Guest Ledger", Rarity = "Rare", Blurb = "Your name is already in it." },
	{ Id = "ClockHand", Name = "Grandfather Clock Hand", Rarity = "Rare", Blurb = "Points at whoever is closest." },
	{ Id = "MirrorShard", Name = "Haunted Mirror Shard", Rarity = "Rare", Blurb = "The reflection is a second behind." },
	{ Id = "PhantomMonocle", Name = "Phantom's Monocle", Rarity = "Epic", Blurb = "Through it, the walls are thinner." },
	{ Id = "SilverBell", Name = "Silver Service Bell", Rarity = "Epic", Blurb = "Ring it once. Do not ring it twice." },
	{ Id = "LastGuestRing", Name = "The Last Guest's Ring", Rarity = "Legendary", Blurb = "Too big for any finger in the hotel." },
	{ Id = "HotelHeart", Name = "Heart of the Hotel", Rarity = "Legendary", Blurb = "It beats slower when you hold it." },
}

-- Helpers shared by the server and the client ------------------------------------

function Config.GetRelic(id)
	for _, relic in Config.Relics do
		if relic.Id == id then
			return relic
		end
	end
	return nil
end

-- Picks a random relic. Harder difficulties make rarer relics more likely.
function Config.RollRelic(difficultyName)
	local weights = Config.Difficulties[difficultyName].RarityWeights
	local total = 0
	for _, rarity in Config.RarityOrder do
		total += weights[rarity] or 0
	end

	local roll = math.random() * total
	local chosen = "Common"
	for _, rarity in Config.RarityOrder do
		local weight = weights[rarity] or 0
		roll -= weight
		if weight > 0 and roll <= 0 then
			chosen = rarity
			break
		end
	end

	local pool = {}
	for _, relic in Config.Relics do
		if relic.Rarity == chosen then
			table.insert(pool, relic)
		end
	end
	return pool[math.random(#pool)]
end

return Config
