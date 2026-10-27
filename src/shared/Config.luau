-- General game settings. Change numbers here to rebalance the game.

local Config = {}

Config.GameName = "Dig Legends"

-- Saving
Config.DataStoreName = "PlayerData_v1"
Config.LeaderboardStoreName = "TotalFound_v1"
Config.AutosaveSeconds = 120

-- Backpack
Config.BagSize = 20
Config.BigBagSize = 60 -- with the Big Backpack pass

-- Digging
Config.DigRange = 9 -- studs from the player to a dig spot
Config.DigDownMin = 1.2 -- seconds of digging before the find shows up (before shovel speed)
Config.DigDownMax = 2.4
Config.DigCooldown = 0.6
Config.SpotCooldown = 20 -- seconds before you can dig the same spot again
Config.ShinyChance = 1 / 100
Config.ShinyValueMultiplier = 3

-- Rebirth: cost = RebirthBaseCost * RebirthCostGrowth ^ rebirths
Config.RebirthBaseCost = 1000000
Config.RebirthCostGrowth = 3
Config.RebirthSellBonus = 0.25 -- +25% coins from selling per rebirth
Config.RebirthRequiresZone = "volcano"

-- Every completed Collection page (all regular finds of a zone) adds this much
-- to the coins you get, forever (rebirths keep the Collection)
Config.PageSellBonus = 0.05

-- Daily login reward: DailyRewardBase * streak day (streak capped at 7)
Config.DailyRewardBase = 100
Config.DailyStreakCap = 7

-- Trading Post
Config.MarketSeconds = 30 * 60 -- how often the "in demand" finds change
Config.StationRange = 25 -- how close you must be to the Trading Post / Charm Cart to use it

-- Set to true to try every game pass for free while testing in Roblox Studio.
-- Has no effect in the live game.
Config.TestPassesInStudio = false

-- How long each weather lasts, in seconds
Config.WeatherSeconds = 15 * 60

function Config.RebirthCost(rebirths)
	return math.floor(Config.RebirthBaseCost * Config.RebirthCostGrowth ^ rebirths)
end

-- pages = completed Collection pages (Finds.CompletedPages)
function Config.SellMultiplier(rebirths, pages)
	return 1 + Config.RebirthSellBonus * rebirths + Config.PageSellBonus * (pages or 0)
end

return Config
