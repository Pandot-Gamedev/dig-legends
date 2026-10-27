-- A charm is used up each time you dig, whether the find survives or not.
-- Charms are bought with coins or made from finds, never sold for Robux.
--
-- digSpeed: multiplies how long it takes to dig down (lower is faster)
-- luck: multiplies the chance of Rare and better finds
-- legendary: multiplies the chance of Legendary finds
-- shiny: multiplies the chance of a Shiny find
-- price/buyAmount: coins for a pack at the Charm Cart (no price = can't buy)
-- recipe: finds (by rarity) traded in to make craftAmount charms

local Charms = {}

Charms.List = {
	{
		id = "none",
		name = "No charm",
		free = true,
		color = Color3.fromRGB(200, 200, 200),
		description = "Free and endless. No bonus.",
	},
	{
		id = "clover",
		name = "Clover",
		price = 150,
		buyAmount = 10,
		digSpeed = 0.7,
		color = Color3.fromRGB(110, 220, 110),
		description = "Dig down 30% faster.",
	},
	{
		id = "horseshoe",
		name = "Horseshoe",
		price = 400,
		buyAmount = 5,
		luck = 1.35,
		recipe = { { rarity = "Common", count = 3 } },
		craftAmount = 2,
		color = Color3.fromRGB(190, 190, 210),
		description = "Rare and better finds 35% more likely.",
	},
	{
		id = "glow_stone",
		name = "Glow Stone",
		luck = 1.7,
		shiny = 2,
		recipe = { { rarity = "Uncommon", count = 2 }, { rarity = "Rare", count = 1 } },
		craftAmount = 3,
		color = Color3.fromRGB(120, 255, 220),
		description = "Rare+ finds 70% more likely, Shiny finds twice as likely. Craft only.",
	},
	{
		id = "legend_map",
		name = "Legend Map",
		legendary = 2.5,
		digSpeed = 0.85,
		recipe = { { rarity = "Rare", count = 3 }, { rarity = "Epic", count = 1 } },
		craftAmount = 2,
		color = Color3.fromRGB(255, 180, 40),
		description = "Legendary finds 2.5x as likely. Craft only.",
	},
}

Charms.ById = {}
for index, charm in ipairs(Charms.List) do
	charm.order = index
	Charms.ById[charm.id] = charm
end

Charms.Default = "none"

return Charms
