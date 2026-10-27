-- Bait goes on the hook before each cast. A fish that bites eats it, whether
-- you land the fish or not. Bait is bought with coins or made from fish you
-- caught, never sold for Robux.
--
-- biteSpeed: multiplies the wait for a bite (lower is faster)
-- luck: multiplies the chance of Rare and better fish
-- legendary: multiplies the chance of Legendary and Mythic fish
-- shiny: multiplies the chance of a Shiny fish
-- price/buyAmount: coins for a pack at the Bait & Tackle shop (no price = can't buy)
-- recipe: fish (by rarity) traded in to make craftAmount bait

local Bait = {}

Bait.List = {
	{
		id = "bread",
		name = "Bread",
		free = true,
		color = Color3.fromRGB(230, 200, 140),
		description = "Free and endless. No bonus.",
	},
	{
		id = "worms",
		name = "Worms",
		price = 150,
		buyAmount = 10,
		biteSpeed = 0.7,
		color = Color3.fromRGB(220, 120, 130),
		description = "Fish bite 30% sooner.",
	},
	{
		id = "shrimp",
		name = "Shrimp",
		price = 400,
		buyAmount = 5,
		luck = 1.35,
		recipe = { { rarity = "Common", count = 3 } },
		craftAmount = 2,
		color = Color3.fromRGB(255, 150, 100),
		description = "Rare and better fish 35% more likely.",
	},
	{
		id = "glow_lure",
		name = "Glow Lure",
		luck = 1.7,
		shiny = 2,
		recipe = { { rarity = "Uncommon", count = 2 }, { rarity = "Rare", count = 1 } },
		craftAmount = 3,
		color = Color3.fromRGB(120, 255, 220),
		description = "Rare+ fish 70% more likely, Shiny fish twice as likely. Craft only.",
	},
	{
		id = "legend_chum",
		name = "Legend Chum",
		legendary = 2.5,
		biteSpeed = 0.85,
		recipe = { { rarity = "Rare", count = 3 }, { rarity = "Epic", count = 1 } },
		craftAmount = 2,
		color = Color3.fromRGB(255, 180, 40),
		description = "Legendary and Mythic fish 2.5x as likely. Craft only.",
	},
}

Bait.ById = {}
for index, bait in ipairs(Bait.List) do
	bait.order = index
	Bait.ById[bait.id] = bait
end

Bait.Default = "bread"

return Bait
