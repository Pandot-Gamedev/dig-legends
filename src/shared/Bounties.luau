-- Old Pete's daily bounties: three fish requests per player per day.
-- Turning one in pays three times what the market would, plus bait.

local Fish = require(script.Parent.Fish)
local Zones = require(script.Parent.Zones)

local Bounties = {}

Bounties.RewardMultiplier = 3

-- { rarity, count range, bait reward }
local SLOTS = {
	{ rarity = "Common", count = { 3, 5 }, bait = "worms", baitAmount = 5 },
	{ rarity = "Uncommon", count = { 2, 3 }, bait = "shrimp", baitAmount = 3 },
	{ rarity = "Rare", count = { 1, 1 }, bait = "glow_lure", baitAmount = 2 },
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
				for _, fish in ipairs(Fish.ByZone[zone.id] or {}) do
					if fish.rarity == slot.rarity then
						table.insert(pool, fish)
					end
				end
			end
		end
		if #pool > 0 then
			local fish = pool[random:NextInteger(1, #pool)]
			table.insert(list, {
				fishId = fish.id,
				count = random:NextInteger(slot.count[1], slot.count[2]),
				bait = slot.bait,
				baitAmount = slot.baitAmount,
				done = false,
			})
		end
	end
	return list
end

-- Coins paid for a bounty
function Bounties.Reward(bounty, sellMultiplier)
	local fish = Fish.ById[bounty.fishId]
	return math.floor(fish.value * bounty.count * Bounties.RewardMultiplier * sellMultiplier)
end

return Bounties
