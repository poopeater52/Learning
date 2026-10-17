-- BrainrotConfig (ModuleScript in ReplicatedStorage)
-- Every number that controls the game lives here.
-- Change these to balance your game: no other script needs editing.

local Config = {}

-- Money
Config.StartingCash = 50
Config.SellRefund = 0.5 -- selling gives back 50% of what you paid

-- Conveyor belt
Config.BeltSpawnInterval = 2.5 -- seconds between new brainrots
Config.BeltTravelTime = 25 -- seconds to walk the whole belt before disappearing

-- Bases
Config.SlotsPerBase = 10
Config.LockDuration = 30 -- seconds a base stays locked after pressing the button

-- Stealing
Config.StealHoldTime = 1.5 -- seconds you must hold E to steal
Config.CarrySpeed = 12 -- walk speed while carrying a stolen brainrot (normal is 16)
Config.BonkRange = 8 -- studs: how close you must be to bonk a thief
Config.BonkCooldown = 0.8

-- Saving (only works in a published game with "Enable Studio Access to API Services" on)
Config.DataStoreName = "BrainrotSave_v1"
Config.AutosaveInterval = 60

-- Rarities: Weight = how often it shows up on the belt (bigger = more common)
Config.Rarities = {
	{ Name = "Common", Color = Color3.fromRGB(200, 200, 200), Weight = 55 },
	{ Name = "Rare", Color = Color3.fromRGB(80, 160, 255), Weight = 25 },
	{ Name = "Epic", Color = Color3.fromRGB(180, 80, 255), Weight = 12 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 190, 40), Weight = 6 },
	{ Name = "Mythic", Color = Color3.fromRGB(255, 60, 60), Weight = 1.8 },
	{ Name = "Secret", Color = Color3.fromRGB(20, 20, 20), Weight = 0.2 },
}

-- The brainrots! Add your own by copying a line.
-- Cost = price on the belt, Income = cash per second while in your base,
-- Size = how big it is, BodyColor/HeadColor = what it looks like.
Config.Brainrots = {
	{ Name = "Pizzarino Dinosaurino", Rarity = "Common", Cost = 25, Income = 1, Size = 1, BodyColor = Color3.fromRGB(230, 120, 50), HeadColor = Color3.fromRGB(110, 190, 90) },
	{ Name = "Cappuccino Ninja", Rarity = "Common", Cost = 60, Income = 2, Size = 1, BodyColor = Color3.fromRGB(120, 80, 50), HeadColor = Color3.fromRGB(40, 40, 40) },
	{ Name = "Sandalini Supremo", Rarity = "Common", Cost = 120, Income = 4, Size = 1.1, BodyColor = Color3.fromRGB(190, 150, 100), HeadColor = Color3.fromRGB(240, 200, 160) },
	{ Name = "Bananito Bandito", Rarity = "Rare", Cost = 400, Income = 10, Size = 1.15, BodyColor = Color3.fromRGB(250, 220, 60), HeadColor = Color3.fromRGB(60, 60, 60) },
	{ Name = "Gelato Gorilla", Rarity = "Rare", Cost = 900, Income = 20, Size = 1.3, BodyColor = Color3.fromRGB(90, 70, 60), HeadColor = Color3.fromRGB(255, 170, 200) },
	{ Name = "Tortellini Tornado", Rarity = "Epic", Cost = 3000, Income = 55, Size = 1.3, BodyColor = Color3.fromRGB(240, 210, 130), HeadColor = Color3.fromRGB(150, 200, 255) },
	{ Name = "Frigorifero Elefante", Rarity = "Epic", Cost = 7500, Income = 120, Size = 1.5, BodyColor = Color3.fromRGB(230, 235, 240), HeadColor = Color3.fromRGB(150, 150, 160) },
	{ Name = "Bombardini Burrito", Rarity = "Legendary", Cost = 25000, Income = 350, Size = 1.5, BodyColor = Color3.fromRGB(220, 180, 110), HeadColor = Color3.fromRGB(120, 130, 80) },
	{ Name = "Lasagna Lightning", Rarity = "Legendary", Cost = 60000, Income = 750, Size = 1.6, BodyColor = Color3.fromRGB(200, 70, 40), HeadColor = Color3.fromRGB(255, 240, 80) },
	{ Name = "Spaghettini Rocketini", Rarity = "Mythic", Cost = 250000, Income = 2500, Size = 1.8, BodyColor = Color3.fromRGB(250, 230, 150), HeadColor = Color3.fromRGB(255, 60, 60) },
	{ Name = "Il Grande Toasterone", Rarity = "Secret", Cost = 2000000, Income = 15000, Size = 2.2, BodyColor = Color3.fromRGB(170, 170, 180), HeadColor = Color3.fromRGB(255, 140, 0) },
}

-- Helpers shared by the server and client scripts

function Config.GetBrainrot(name)
	for _, info in Config.Brainrots do
		if info.Name == name then
			return info
		end
	end
	return nil
end

function Config.GetRarity(rarityName)
	for _, rarity in Config.Rarities do
		if rarity.Name == rarityName then
			return rarity
		end
	end
	return Config.Rarities[1]
end

-- 1500 -> "$1.5K", 2000000 -> "$2M"
function Config.FormatCash(amount)
	local suffixes = { "", "K", "M", "B", "T" }
	local index = 1
	while amount >= 1000 and index < #suffixes do
		amount /= 1000
		index += 1
	end
	if index == 1 then
		return "$" .. math.floor(amount)
	end
	return "$" .. string.format("%.1f", amount):gsub("%.0$", "") .. suffixes[index]
end

return Config
