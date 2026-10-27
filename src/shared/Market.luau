-- Fish Market prices. Every 30 minutes one fish per zone is "in demand" and
-- sells for double, so holding on to the right fish can pay off.

local Config = require(script.Parent.Config)
local Fish = require(script.Parent.Fish)
local Zones = require(script.Parent.Zones)
local Events = require(script.Parent.Events)

local Market = {}

Market.HotMultiplier = 2

-- Returns { [fishId] = true } for the fish in demand right now, and seconds left
function Market.HotFish(now)
	now = now or Events.Now()
	local slot = math.floor(now / Config.MarketSeconds)
	local secondsLeft = Config.MarketSeconds - (now % Config.MarketSeconds)
	local random = Random.new(slot * 31 + 7)
	local hot = {}
	for _, zone in ipairs(Zones.List) do
		local pool = {}
		for _, fish in ipairs(Fish.ByZone[zone.id] or {}) do
			if fish.rarity ~= "Common" then
				table.insert(pool, fish)
			end
		end
		if #pool > 0 then
			hot[pool[random:NextInteger(1, #pool)].id] = true
		end
	end
	return hot, secondsLeft
end

-- Coins for one fish from the bag, right now
function Market.Price(entry, rebirths, hot)
	hot = hot or Market.HotFish()
	local price = entry.value * Config.SellMultiplier(rebirths)
	if hot[entry.id] then
		price *= Market.HotMultiplier
	end
	return math.floor(price)
end

return Market
