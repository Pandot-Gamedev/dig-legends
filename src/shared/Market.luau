-- Trading Post prices. Every 30 minutes one find per zone is "in demand" and
-- sells for double, so holding on to the right find can pay off.

local Config = require(script.Parent.Config)
local Finds = require(script.Parent.Finds)
local Zones = require(script.Parent.Zones)
local Events = require(script.Parent.Events)

local Market = {}

Market.HotMultiplier = 2

-- Returns { [findId] = true } for the finds in demand right now, and seconds left
function Market.HotFinds(now)
	now = now or Events.Now()
	local slot = math.floor(now / Config.MarketSeconds)
	local secondsLeft = Config.MarketSeconds - (now % Config.MarketSeconds)
	local random = Random.new(slot * 31 + 7)
	local hot = {}
	for _, zone in ipairs(Zones.List) do
		local pool = {}
		for _, find in ipairs(Finds.ByZone[zone.id] or {}) do
			if find.rarity ~= "Common" then
				table.insert(pool, find)
			end
		end
		if #pool > 0 then
			hot[pool[random:NextInteger(1, #pool)].id] = true
		end
	end
	return hot, secondsLeft
end

-- Coins for one find from the backpack, right now
function Market.Price(entry, rebirths, hot)
	hot = hot or Market.HotFinds()
	local price = entry.value * Config.SellMultiplier(rebirths)
	if hot[entry.id] then
		price *= Market.HotMultiplier
	end
	return math.floor(price)
end

return Market
