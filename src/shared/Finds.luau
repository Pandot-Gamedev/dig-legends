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

	-- Desert Dig
	{ id = "clay_shard", name = "Clay Pot Shard", zone = "desert", rarity = "Common", value = 22, weight = { 0.05, 0.3 }, shape = "relic", color = Color3.fromRGB(190, 110, 70) },
	{ id = "bleached_bone", name = "Sun-Bleached Bone", zone = "desert", rarity = "Common", value = 24, weight = { 0.1, 0.6 }, shape = "bone", color = Color3.fromRGB(240, 230, 210) },
	{ id = "desert_rose", name = "Desert Rose", zone = "desert", rarity = "Common", value = 26, weight = { 0.05, 0.4 }, shape = "gem", color = Color3.fromRGB(220, 160, 120) },
	{ id = "old_canteen", name = "Old Canteen", zone = "desert", rarity = "Common", value = 30, weight = { 0.3, 0.9 }, shape = "relic", color = Color3.fromRGB(120, 130, 90) },
	{ id = "copper_bracelet", name = "Copper Bracelet", zone = "desert", rarity = "Uncommon", value = 85, weight = { 0.02, 0.1 }, shape = "ring", color = Color3.fromRGB(200, 120, 70) },
	{ id = "scarab_amulet", name = "Scarab Amulet", zone = "desert", rarity = "Uncommon", value = 95, weight = { 0.02, 0.08 }, shape = "relic", color = Color3.fromRGB(40, 150, 140) },
	{ id = "raptor_claw", name = "Raptor Claw", zone = "desert", rarity = "Uncommon", value = 105, weight = { 0.1, 0.5 }, shape = "tooth", color = Color3.fromRGB(110, 90, 70) },
	{ id = "sphinx_figurine", name = "Sphinx Figurine", zone = "desert", rarity = "Rare", value = 280, weight = { 0.5, 2 }, shape = "relic", color = Color3.fromRGB(225, 190, 120) },
	{ id = "turquoise_nugget", name = "Turquoise Nugget", zone = "desert", rarity = "Rare", value = 300, weight = { 0.05, 0.3 }, shape = "gem", color = Color3.fromRGB(60, 200, 190) },
	{ id = "raptor_skull", name = "Raptor Skull", zone = "desert", rarity = "Epic", value = 900, weight = { 2, 8 }, shape = "bone", color = Color3.fromRGB(200, 185, 160) },
	{ id = "golden_ankh", name = "Golden Ankh", zone = "desert", rarity = "Epic", value = 1050, weight = { 0.3, 1.2 }, shape = "relic", color = Color3.fromRGB(255, 205, 60) },
	{ id = "trex_tooth", name = "Tyrannosaurus Tooth", zone = "desert", rarity = "Legendary", value = 5000, weight = { 1, 5 }, shape = "tooth", color = Color3.fromRGB(235, 220, 190) },

	-- Crystal Caves
	{ id = "quartz_shard", name = "Quartz Shard", zone = "caves", rarity = "Common", value = 95, weight = { 0.05, 0.4 }, shape = "gem", color = Color3.fromRGB(235, 235, 245) },
	{ id = "cave_pearl", name = "Cave Pearl", zone = "caves", rarity = "Common", value = 110, weight = { 0.01, 0.05 }, shape = "orb", color = Color3.fromRGB(240, 235, 220) },
	{ id = "fools_gold", name = "Fool's Gold", zone = "caves", rarity = "Common", value = 120, weight = { 0.1, 0.8 }, shape = "gem", color = Color3.fromRGB(210, 180, 80) },
	{ id = "rough_geode", name = "Rough Geode", zone = "caves", rarity = "Common", value = 130, weight = { 0.5, 3 }, shape = "orb", color = Color3.fromRGB(130, 120, 110) },
	{ id = "amethyst_cluster", name = "Amethyst Cluster", zone = "caves", rarity = "Uncommon", value = 380, weight = { 0.2, 1.5 }, shape = "gem", color = Color3.fromRGB(160, 90, 220) },
	{ id = "glowing_quartz", name = "Glowing Quartz", zone = "caves", rarity = "Uncommon", value = 420, weight = { 0.1, 1 }, shape = "gem", color = Color3.fromRGB(120, 255, 220) },
	{ id = "cave_bear_tooth", name = "Cave Bear Tooth", zone = "caves", rarity = "Uncommon", value = 450, weight = { 0.05, 0.3 }, shape = "tooth", color = Color3.fromRGB(230, 220, 195) },
	{ id = "miners_lantern", name = "Old Miner's Lantern", zone = "caves", rarity = "Rare", value = 1100, weight = { 1, 3 }, shape = "relic", color = Color3.fromRGB(160, 120, 60) },
	{ id = "raw_sapphire", name = "Raw Sapphire", zone = "caves", rarity = "Rare", value = 1300, weight = { 0.02, 0.2 }, shape = "gem", color = Color3.fromRGB(40, 80, 230) },
	{ id = "crystal_skull", name = "Crystal Skull", zone = "caves", rarity = "Epic", value = 3800, weight = { 1, 4 }, shape = "relic", color = Color3.fromRGB(200, 230, 255) },
	{ id = "starlight_geode", name = "Starlight Geode", zone = "caves", rarity = "Epic", value = 4200, weight = { 1, 6 }, shape = "orb", color = Color3.fromRGB(70, 50, 140) },
	{ id = "rainbow_diamond", name = "Rainbow Diamond", zone = "caves", rarity = "Legendary", value = 20000, weight = { 0.01, 0.1 }, shape = "gem", color = Color3.fromRGB(255, 150, 230) },

	-- Sunken Ruins
	{ id = "mosaic_tile", name = "Mosaic Tile", zone = "ruins", rarity = "Common", value = 380, weight = { 0.1, 0.5 }, shape = "relic", color = Color3.fromRGB(70, 140, 200) },
	{ id = "bronze_coin", name = "Bronze Coin", zone = "ruins", rarity = "Common", value = 420, weight = { 0.01, 0.03 }, shape = "coin", color = Color3.fromRGB(180, 120, 60) },
	{ id = "sea_glass", name = "Sea Glass", zone = "ruins", rarity = "Common", value = 450, weight = { 0.01, 0.05 }, shape = "orb", color = Color3.fromRGB(120, 210, 170) },
	{ id = "conch_shell", name = "Conch Shell", zone = "ruins", rarity = "Common", value = 520, weight = { 0.3, 1.5 }, shape = "shell", color = Color3.fromRGB(250, 190, 170) },
	{ id = "marble_hand", name = "Marble Statue Hand", zone = "ruins", rarity = "Uncommon", value = 1500, weight = { 2, 8 }, shape = "relic", color = Color3.fromRGB(235, 235, 230) },
	{ id = "silver_goblet", name = "Silver Goblet", zone = "ruins", rarity = "Uncommon", value = 1650, weight = { 0.3, 1 }, shape = "relic", color = Color3.fromRGB(210, 215, 225) },
	{ id = "ancient_tablet", name = "Ancient Tablet", zone = "ruins", rarity = "Uncommon", value = 1800, weight = { 3, 12 }, shape = "relic", color = Color3.fromRGB(150, 150, 130) },
	{ id = "emerald_ring", name = "Emerald Ring", zone = "ruins", rarity = "Rare", value = 4800, weight = { 0.01, 0.05 }, shape = "ring", color = Color3.fromRGB(40, 200, 90) },
	{ id = "trident_tip", name = "Trident Tip", zone = "ruins", rarity = "Rare", value = 5200, weight = { 1, 4 }, shape = "tooth", color = Color3.fromRGB(200, 170, 80) },
	{ id = "golden_mask", name = "Golden Mask", zone = "ruins", rarity = "Epic", value = 15000, weight = { 1, 4 }, shape = "relic", color = Color3.fromRGB(255, 200, 50) },
	{ id = "black_pearl", name = "Black Pearl", zone = "ruins", rarity = "Epic", value = 16000, weight = { 0.01, 0.05 }, shape = "orb", color = Color3.fromRGB(40, 40, 55) },
	{ id = "atlantis_orb", name = "Orb of Atlantis", zone = "ruins", rarity = "Legendary", value = 80000, weight = { 3, 10 }, shape = "orb", color = Color3.fromRGB(60, 220, 255) },

	-- Volcano Core
	{ id = "obsidian_shard", name = "Obsidian Shard", zone = "volcano", rarity = "Common", value = 1500, weight = { 0.1, 1 }, shape = "gem", color = Color3.fromRGB(35, 30, 45) },
	{ id = "lava_rock", name = "Lava Rock", zone = "volcano", rarity = "Common", value = 1700, weight = { 1, 5 }, shape = "orb", color = Color3.fromRGB(90, 50, 40) },
	{ id = "sulfur_crystal", name = "Sulfur Crystal", zone = "volcano", rarity = "Common", value = 1900, weight = { 0.1, 0.6 }, shape = "gem", color = Color3.fromRGB(240, 220, 60) },
	{ id = "ash_fossil", name = "Ash Fossil", zone = "volcano", rarity = "Common", value = 2100, weight = { 0.5, 3 }, shape = "shell", color = Color3.fromRGB(120, 115, 110) },
	{ id = "fire_opal", name = "Fire Opal", zone = "volcano", rarity = "Uncommon", value = 6000, weight = { 0.02, 0.2 }, shape = "gem", color = Color3.fromRGB(255, 120, 60) },
	{ id = "magma_beetle", name = "Magma Beetle Fossil", zone = "volcano", rarity = "Uncommon", value = 6400, weight = { 0.1, 0.5 }, shape = "shell", color = Color3.fromRGB(200, 60, 30) },
	{ id = "salamander_bones", name = "Fire Salamander Bones", zone = "volcano", rarity = "Uncommon", value = 7000, weight = { 0.5, 3 }, shape = "bone", color = Color3.fromRGB(230, 160, 120) },
	{ id = "dragon_scale", name = "Dragon Scale", zone = "volcano", rarity = "Rare", value = 19000, weight = { 0.5, 2 }, shape = "shell", color = Color3.fromRGB(180, 30, 40) },
	{ id = "ember_ruby", name = "Ember Ruby", zone = "volcano", rarity = "Rare", value = 21000, weight = { 0.02, 0.2 }, shape = "gem", color = Color3.fromRGB(230, 30, 50) },
	{ id = "golem_heart", name = "Lava Golem Heart", zone = "volcano", rarity = "Epic", value = 58000, weight = { 5, 20 }, shape = "orb", color = Color3.fromRGB(255, 90, 20) },
	{ id = "fire_diamond", name = "Fire Diamond", zone = "volcano", rarity = "Epic", value = 64000, weight = { 0.05, 0.3 }, shape = "gem", color = Color3.fromRGB(255, 70, 30) },
	{ id = "dragon_egg", name = "Dragon Egg Fossil", zone = "volcano", rarity = "Legendary", value = 320000, weight = { 10, 40 }, shape = "egg", color = Color3.fromRGB(110, 40, 40) },

	-- Weekly event legendaries (one per week, rotating through the zones)
	{ id = "pirate_chest", name = "Buried Pirate Chest", zone = "backyard", rarity = "Legendary", value = 3000, weight = { 20, 60 }, shape = "relic", color = Color3.fromRGB(140, 90, 40), event = true },
	{ id = "meteorite", name = "Meteorite Chunk", zone = "desert", rarity = "Legendary", value = 12000, weight = { 5, 30 }, shape = "orb", color = Color3.fromRGB(70, 60, 80), event = true },
	{ id = "mountain_heart", name = "Heart of the Mountain", zone = "caves", rarity = "Legendary", value = 50000, weight = { 5, 25 }, shape = "gem", color = Color3.fromRGB(255, 80, 200), event = true },
	{ id = "sunken_crown", name = "Sunken King's Crown", zone = "ruins", rarity = "Legendary", value = 200000, weight = { 2, 6 }, shape = "ring", color = Color3.fromRGB(255, 215, 80), event = true },
	{ id = "phoenix_feather", name = "Phoenix Feather", zone = "volcano", rarity = "Legendary", value = 800000, weight = { 0.1, 0.5 }, shape = "relic", color = Color3.fromRGB(255, 160, 40), event = true },
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

-- Zones whose regular finds are all in the Collection
function Finds.IsPageComplete(book, zoneId)
	local list = Finds.ByZone[zoneId]
	if not list then
		return false
	end
	for _, find in ipairs(list) do
		if not book[find.id] then
			return false
		end
	end
	return true
end

function Finds.CompletedPages(book)
	local pages = 0
	for zoneId in pairs(Finds.ByZone) do
		if Finds.IsPageComplete(book, zoneId) then
			pages += 1
		end
	end
	return pages
end

return Finds
