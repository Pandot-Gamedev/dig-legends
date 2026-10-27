-- Fishing zones. Zones are unlocked with in-game coins.

local Zones = {}

Zones.List = {
	{ id = "shallows", name = "Sunny Shallows", price = 0, color = Color3.fromRGB(255, 220, 120) },
	{ id = "mangroves", name = "Misty Mangroves", price = 5000, color = Color3.fromRGB(90, 160, 90) },
	{ id = "frostbite", name = "Frostbite Bay", price = 150000, color = Color3.fromRGB(170, 220, 255) },
}

Zones.ById = {}
for index, zone in ipairs(Zones.List) do
	zone.order = index
	Zones.ById[zone.id] = zone
end

Zones.Default = "shallows"

return Zones
