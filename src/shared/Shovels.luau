-- Shovels are bought with in-game coins only (never Robux).
-- luck: multiplies the chance of Rare and better finds
-- speed: multiplies how long it takes to dig down (lower is faster)
-- power: widens the green sweet spot in the dig minigame

local Shovels = {}

Shovels.List = {
	{ id = "trowel", name = "Garden Trowel", price = 0, luck = 1.0, speed = 1.0, power = 0.0, color = Color3.fromRGB(140, 100, 60) },
	{ id = "spade", name = "Garden Spade", price = 400, luck = 1.1, speed = 0.92, power = 0.06, color = Color3.fromRGB(110, 150, 90) },
	{ id = "steel", name = "Steel Shovel", price = 2500, luck = 1.25, speed = 0.85, power = 0.12, color = Color3.fromRGB(200, 205, 215) },
	{ id = "golden", name = "Golden Shovel", price = 12000, luck = 1.45, speed = 0.77, power = 0.18, color = Color3.fromRGB(255, 200, 40) },
	{ id = "crystal", name = "Crystal Shovel", price = 60000, luck = 1.7, speed = 0.68, power = 0.25, color = Color3.fromRGB(170, 120, 255) },
	{ id = "magma", name = "Magma Shovel", price = 300000, luck = 2.0, speed = 0.6, power = 0.32, color = Color3.fromRGB(255, 90, 30) },
}

Shovels.ById = {}
for index, shovel in ipairs(Shovels.List) do
	shovel.order = index
	Shovels.ById[shovel.id] = shovel
end

Shovels.Default = "trowel"

return Shovels
