-- Grandpa Gus's daily bounties: three find requests per player per day.
-- Turning one in pays three times what the Trading Post would, plus charms.

local Finds = require(script.Parent.Finds)
local Zones = require(script.Parent.Zones)

local Bounties = {}

Bounties.RewardMultiplier = 3

-- { rarity, count range, charm reward }
local SLOTS = {
	{ rarity = "Common", count = { 3, 5 }, charm = "clover", charmAmount = 5 },
	{ rarity = "Uncommon", count = { 2, 3 }, charm = "horseshoe", charmAmount = 3 },
	{ rarity = "Rare", count = { 1, 1 }, charm = "glow_stone", charmAmount = 2 },
}

function Bounties.Today(now)
	return math.floor(now / 86400)
end

-- Makes the day's bounties from the zones the player has unlocked
function Bounties.Generate(userId, day, unlockedZones)
	local random = Random.new(userId % 1000003 * 977 + day)
	local list = {}
	for _, slot in ipairs(SLOTS) do
		local pool = {}
		for _, zone in ipairs(Zones.List) do
			if unlockedZones[zone.id] then
				for _, find in ipairs(Finds.ByZone[zone.id] or {}) do
					if find.rarity == slot.rarity then
						table.insert(pool, find)
					end
				end
			end
		end
		if #pool > 0 then
			local find = pool[random:NextInteger(1, #pool)]
			table.insert(list, {
				findId = find.id,
				count = random:NextInteger(slot.count[1], slot.count[2]),
				charm = slot.charm,
				charmAmount = slot.charmAmount,
				done = false,
			})
		end
	end
	return list
end

-- Coins paid for a bounty
function Bounties.Reward(bounty, sellMultiplier)
	local find = Finds.ById[bounty.findId]
	return math.floor(find.value * bounty.count * Bounties.RewardMultiplier * sellMultiplier)
end

return Bounties
