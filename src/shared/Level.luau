-- Digger level. Every find gives XP (more for rarer finds and new ones).
-- Your level shows above your head and pays a coin reward each time it goes up.

local Finds = require(script.Parent.Finds)

local Level = {}

Level.XpByRarity = {
	Common = 5,
	Uncommon = 10,
	Rare = 25,
	Epic = 60,
	Legendary = 150,
}
Level.NewFindBonus = 25
Level.CoinsPerLevel = 150 -- reward for reaching level N is N * this

-- Total XP needed to reach a level (level 1 needs 0)
function Level.XpFor(level)
	return math.floor(40 * (level - 1) ^ 1.6)
end

function Level.FromXp(xp)
	local level = 1
	while Level.XpFor(level + 1) <= xp do
		level += 1
	end
	return level
end

-- How far through the current level, from 0 to 1
function Level.Progress(xp)
	local level = Level.FromXp(xp)
	local from, to = Level.XpFor(level), Level.XpFor(level + 1)
	return (xp - from) / (to - from), level
end

function Level.XpForFind(findId, isNew)
	local find = Finds.ById[findId]
	local xp = Level.XpByRarity[find.rarity] or 5
	if isNew then
		xp += Level.NewFindBonus
	end
	return xp
end

return Level
