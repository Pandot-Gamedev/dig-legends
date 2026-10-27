-- Everything you can dig up. To add a find, copy a line and give it a new unique id.
-- value = coins for an average-weight find. weight = {min, max} in kg.
-- shape = how it looks when held up (see FindModel): coin, gem, bone, egg, relic, orb, ring, tooth, shell
-- color = optional, otherwise one is picked from the id

local Finds = {}

-- strikes: good hits needed to dig it out
-- zone: how wide the green sweet spot is (share of the bar)
-- speed: how fast the marker moves (bar widths per second)
Finds.Rarities = {
	{ id = "Common", weight = 60, color = Color3.fromRGB(200, 200, 200), strikes = 3, zone = 0.28, speed = 0.85 },
	{ id = "Uncommon", weight = 25, color = Color3.fromRGB(90, 200, 90), strikes = 4, zone = 0.24, speed = 0.95 },
	{ id = "Rare", weight = 10, color = Color3.fromRGB(70, 140, 255), strikes = 5, zone = 0.2, speed = 1.1 },
	{ id = "Epic", weight = 4, color = Color3.fromRGB(170, 80, 255), strikes = 6, zone = 0.17, speed = 1.25 },
	{ id = "Legendary", weight = 1, color = Color3.fromRGB(255, 170, 0), strikes = 7, zone = 0.14, speed = 1.4 },
}

Finds.RarityById = {}
for index, rarity in ipairs(Finds.Rarities) do
	rarity.order = index
	Finds.RarityById[rarity.id] = rarity
end

-- event = true: only found during its weekly event (see Events.luau)
Finds.List = {
	-- Backyard
	{ id = "bottle_cap", name = "Bottle Cap", zone = "backyard", rarity = "Common", value = 5, weight = { 0.01, 0.03 }, shape = "coin", color = Color3.fromRGB(200, 60, 60) },
	{ id = "old_penny", name = "Old Penny", zone = "backyard", rarity = "Common", value = 7, weight = { 0.01, 0.02 }, shape = "coin", color = Color3.fromRGB(190, 110, 60) },
	{ id = "glass_marble", name = "Glass Marble", zone = "backyard", rarity = "Common", value = 6, weight = { 0.01, 0.04 }, shape = "orb", color = Color3.fromRGB(90, 180, 255) },
	{ id = "snail_shell", name = "Snail Shell", zone = "backyard", rarity = "Common", value = 8, weight = { 0.02, 0.08 }, shape = "shell", color = Color3.fromRGB(210, 170, 120) },
	{ id = "toy_soldier", name = "Toy Soldier", zone = "backyard", rarity = "Uncommon", value = 20, weight = { 0.05, 0.2 }, shape = "relic", color = Color3.fromRGB(70, 110, 70) },
	{ id = "lost_key", name = "Lost Key", zone = "backyard", rarity = "Uncommon", value = 24, weight = { 0.02, 0.1 }, shape = "relic", color = Color3.fromRGB(200, 180, 90) },
	{ id = "flint_arrowhead", name = "Flint Arrowhead", zone = "backyard", rarity = "Uncommon", value = 28, weight = { 0.03, 0.15 }, shape = "tooth", color = Color3.fromRGB(110, 110, 120) },
	{ id = "pocket_watch", name = "Rusty Pocket Watch", zone = "backyard", rarity = "Rare", value = 60, weight = { 0.1, 0.3 }, shape = "coin", color = Color3.fromRGB(170, 140, 90) },
	{ id = "trilobite", name = "Trilobite Fossil", zone = "backyard", rarity = "Rare", value = 75, weight = { 0.2, 1.5 }, shape = "shell", color = Color3.fromRGB(150, 130, 100) },
	{ id = "silver_ring", name = "Silver Ring", zone = "backyard", rarity = "Epic", value = 200, weight = { 0.01, 0.05 }, shape = "ring", color = Color3.fromRGB(220, 225, 235) },
	{ id = "mammoth_tooth", name = "Mammoth Tooth", zone = "backyard", rarity = "Epic", value = 240, weight = { 1, 4 }, shape = "tooth", color = Color3.fromRGB(235, 225, 200) },
	{ id = "time_capsule", name = "Golden Time Capsule", zone = "backyard", rarity = "Legendary", value = 1200, weight = { 2, 6 }, shape = "relic", color = Color3.fromRGB(255, 200, 40) },

	-- Weekly event legendaries (one per week, rotating)
	{ id = "pirate_chest", name = "Buried Pirate Chest", zone = "backyard", rarity = "Legendary", value = 3000, weight = { 20, 60 }, shape = "relic", color = Color3.fromRGB(140, 90, 40), event = true },
	{ id = "meteorite", name = "Meteorite Chunk", zone = "backyard", rarity = "Legendary", value = 3000, weight = { 5, 30 }, shape = "orb", color = Color3.fromRGB(70, 60, 80), event = true },
}

Finds.ById = {}
Finds.ByZone = {} -- regular (non-event) finds per zone
Finds.EventFinds = {}
for _, find in ipairs(Finds.List) do
	assert(Finds.ById[find.id] == nil, "Duplicate find id: " .. find.id)
	Finds.ById[find.id] = find
	if find.event then
		table.insert(Finds.EventFinds, find)
	else
		Finds.ByZone[find.zone] = Finds.ByZone[find.zone] or {}
		table.insert(Finds.ByZone[find.zone], find)
	end
end

return Finds
