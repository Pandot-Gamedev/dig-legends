-- Every fish in the game. To add a fish, copy a line and give it a new unique id.
-- value = coins for an average-weight fish. weight = {min, max} in kg.

local Fish = {}

-- hookWindow: seconds to strike after the real bite
-- reel: how fast the catch bar fills while reeling (per second)
-- strength: how hard the fish fights (thrash length, line tension, pull-back)
Fish.Rarities = {
	{ id = "Common", weight = 60, color = Color3.fromRGB(200, 200, 200), hookWindow = 1.0, reel = 0.3, strength = 0.8 },
	{ id = "Uncommon", weight = 25, color = Color3.fromRGB(90, 200, 90), hookWindow = 0.9, reel = 0.24, strength = 1.0 },
	{ id = "Rare", weight = 10, color = Color3.fromRGB(70, 140, 255), hookWindow = 0.8, reel = 0.19, strength = 1.25 },
	{ id = "Epic", weight = 4, color = Color3.fromRGB(170, 80, 255), hookWindow = 0.7, reel = 0.15, strength = 1.5 },
	{ id = "Legendary", weight = 0.9, color = Color3.fromRGB(255, 170, 0), hookWindow = 0.6, reel = 0.14, strength = 1.7 },
	{ id = "Mythic", weight = 0.1, color = Color3.fromRGB(255, 60, 120), hookWindow = 0.55, reel = 0.12, strength = 1.95 },
}

Fish.RarityById = {}
for index, rarity in ipairs(Fish.Rarities) do
	rarity.order = index
	Fish.RarityById[rarity.id] = rarity
end

-- event = true: only catchable during its weekly event (see Events.luau)
Fish.List = {
	-- Sunny Shallows
	{ id = "sunny_minnow", name = "Sunny Minnow", zone = "shallows", rarity = "Common", value = 5, weight = { 0.1, 0.4 } },
	{ id = "pebble_perch", name = "Pebble Perch", zone = "shallows", rarity = "Common", value = 7, weight = { 0.3, 1.2 } },
	{ id = "sandy_sardine", name = "Sandy Sardine", zone = "shallows", rarity = "Common", value = 6, weight = { 0.1, 0.3 } },
	{ id = "bluegill_buddy", name = "Bluegill Buddy", zone = "shallows", rarity = "Common", value = 8, weight = { 0.2, 0.8 } },
	{ id = "coral_snapper", name = "Coral Snapper", zone = "shallows", rarity = "Uncommon", value = 20, weight = { 1, 4 } },
	{ id = "striped_bass", name = "Striped Bass", zone = "shallows", rarity = "Uncommon", value = 24, weight = { 2, 6 } },
	{ id = "puffer_pal", name = "Puffer Pal", zone = "shallows", rarity = "Uncommon", value = 28, weight = { 0.5, 2 } },
	{ id = "rainbow_trout", name = "Rainbow Trout", zone = "shallows", rarity = "Rare", value = 60, weight = { 1, 5 } },
	{ id = "lemon_ray", name = "Lemon Ray", zone = "shallows", rarity = "Rare", value = 75, weight = { 3, 12 } },
	{ id = "glimmer_koi", name = "Glimmer Koi", zone = "shallows", rarity = "Epic", value = 200, weight = { 2, 8 } },
	{ id = "seahorse_knight", name = "Seahorse Knight", zone = "shallows", rarity = "Epic", value = 240, weight = { 0.2, 1 } },
	{ id = "sunfin_emperor", name = "Sunfin Emperor", zone = "shallows", rarity = "Legendary", value = 1200, weight = { 20, 60 } },
	{ id = "golden_guppy_king", name = "Golden Guppy King", zone = "shallows", rarity = "Mythic", value = 6000, weight = { 1, 3 } },

	-- Misty Mangroves
	{ id = "mud_skipper", name = "Mud Skipper", zone = "mangroves", rarity = "Common", value = 25, weight = { 0.2, 0.6 } },
	{ id = "swamp_catfish", name = "Swamp Catfish", zone = "mangroves", rarity = "Common", value = 30, weight = { 2, 8 } },
	{ id = "reed_eel", name = "Reed Eel", zone = "mangroves", rarity = "Common", value = 35, weight = { 1, 3 } },
	{ id = "bog_tilapia", name = "Bog Tilapia", zone = "mangroves", rarity = "Common", value = 28, weight = { 0.5, 2 } },
	{ id = "moss_pike", name = "Moss Pike", zone = "mangroves", rarity = "Uncommon", value = 90, weight = { 3, 10 } },
	{ id = "lantern_gar", name = "Lantern Gar", zone = "mangroves", rarity = "Uncommon", value = 110, weight = { 4, 12 } },
	{ id = "root_crab", name = "Root Crab", zone = "mangroves", rarity = "Uncommon", value = 100, weight = { 0.5, 2 } },
	{ id = "mist_piranha", name = "Mist Piranha", zone = "mangroves", rarity = "Rare", value = 280, weight = { 0.5, 3 } },
	{ id = "jade_arowana", name = "Jade Arowana", zone = "mangroves", rarity = "Rare", value = 330, weight = { 2, 7 } },
	{ id = "ghost_barracuda", name = "Ghost Barracuda", zone = "mangroves", rarity = "Epic", value = 900, weight = { 8, 25 } },
	{ id = "bayou_gator_gar", name = "Bayou Gator Gar", zone = "mangroves", rarity = "Epic", value = 1100, weight = { 30, 90 } },
	{ id = "willow_wyrm", name = "Willow Wyrm", zone = "mangroves", rarity = "Legendary", value = 5000, weight = { 50, 150 } },
	{ id = "ancient_turtle", name = "Ancient Mangrove Turtle", zone = "mangroves", rarity = "Mythic", value = 25000, weight = { 100, 300 } },

	-- Frostbite Bay
	{ id = "ice_cod", name = "Ice Cod", zone = "frostbite", rarity = "Common", value = 110, weight = { 1, 5 } },
	{ id = "frost_herring", name = "Frost Herring", zone = "frostbite", rarity = "Common", value = 120, weight = { 0.2, 0.8 } },
	{ id = "snowball_smelt", name = "Snowball Smelt", zone = "frostbite", rarity = "Common", value = 100, weight = { 0.1, 0.4 } },
	{ id = "polar_pollock", name = "Polar Pollock", zone = "frostbite", rarity = "Common", value = 130, weight = { 1, 4 } },
	{ id = "glacier_salmon", name = "Glacier Salmon", zone = "frostbite", rarity = "Uncommon", value = 380, weight = { 3, 10 } },
	{ id = "arctic_char", name = "Arctic Char", zone = "frostbite", rarity = "Uncommon", value = 420, weight = { 2, 8 } },
	{ id = "crystal_crab", name = "Crystal Crab", zone = "frostbite", rarity = "Uncommon", value = 450, weight = { 1, 4 } },
	{ id = "aurora_halibut", name = "Aurora Halibut", zone = "frostbite", rarity = "Rare", value = 1200, weight = { 10, 40 } },
	{ id = "narwhal_pup", name = "Narwhal Pup", zone = "frostbite", rarity = "Rare", value = 1400, weight = { 40, 120 } },
	{ id = "blizzard_marlin", name = "Blizzard Marlin", zone = "frostbite", rarity = "Epic", value = 4000, weight = { 60, 200 } },
	{ id = "frozen_angler", name = "Frozen Angler", zone = "frostbite", rarity = "Epic", value = 4500, weight = { 5, 20 } },
	{ id = "yeti_whale", name = "Yeti Whale", zone = "frostbite", rarity = "Legendary", value = 20000, weight = { 500, 1500 } },
	{ id = "frostbite_kraken", name = "Frostbite Kraken", zone = "frostbite", rarity = "Mythic", value = 100000, weight = { 800, 2500 } },

	-- Weekly event legendaries (one per week, rotating)
	{ id = "moonscale_leviathan", name = "Moonscale Leviathan", zone = "shallows", rarity = "Legendary", value = 3000, weight = { 80, 200 }, event = true },
	{ id = "thunderjaw_shark", name = "Thunderjaw Shark", zone = "mangroves", rarity = "Legendary", value = 12000, weight = { 150, 400 }, event = true },
	{ id = "prism_manta", name = "Prism Manta", zone = "frostbite", rarity = "Legendary", value = 45000, weight = { 200, 600 }, event = true },
	{ id = "starfall_sturgeon", name = "Starfall Sturgeon", zone = "mangroves", rarity = "Legendary", value = 15000, weight = { 100, 300 }, event = true },
}

Fish.ById = {}
Fish.ByZone = {} -- regular (non-event) fish per zone
Fish.EventFish = {}
for _, fish in ipairs(Fish.List) do
	assert(Fish.ById[fish.id] == nil, "Duplicate fish id: " .. fish.id)
	Fish.ById[fish.id] = fish
	if fish.event then
		table.insert(Fish.EventFish, fish)
	else
		Fish.ByZone[fish.zone] = Fish.ByZone[fish.zone] or {}
		table.insert(Fish.ByZone[fish.zone], fish)
	end
end

return Fish
