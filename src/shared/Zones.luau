-- Digging zones. Zones are unlocked with in-game coins.

local Zones = {}

Zones.List = {
	{ id = "backyard", name = "Backyard", price = 0, color = Color3.fromRGB(140, 210, 110) },
}

Zones.ById = {}
for index, zone in ipairs(Zones.List) do
	zone.order = index
	Zones.ById[zone.id] = zone
end

Zones.Default = "backyard"

return Zones
