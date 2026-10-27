-- Digging zones, in the order you reach them. A zone needs a digger level and
-- in-game coins to unlock. short = name on the Collection tabs.

local Zones = {}

Zones.List = {
	{ id = "backyard", name = "Backyard", short = "Backyard", level = 1, price = 0, color = Color3.fromRGB(140, 210, 110) },
	{ id = "desert", name = "Desert Dig", short = "Desert", level = 5, price = 2500, color = Color3.fromRGB(240, 190, 90) },
	{ id = "caves", name = "Crystal Caves", short = "Caves", level = 12, price = 20000, color = Color3.fromRGB(180, 130, 255) },
	{ id = "ruins", name = "Sunken Ruins", short = "Ruins", level = 20, price = 120000, color = Color3.fromRGB(90, 200, 190) },
	{ id = "volcano", name = "Volcano Core", short = "Volcano", level = 30, price = 700000, color = Color3.fromRGB(255, 110, 50) },
}

Zones.ById = {}
for index, zone in ipairs(Zones.List) do
	zone.order = index
	Zones.ById[zone.id] = zone
end

Zones.Default = "backyard"

return Zones
