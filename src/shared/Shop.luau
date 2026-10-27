-- Everything sold for Robux. Nothing here changes what you dig up or how
-- many coins you earn: only looks and time-savers.
--
-- HOW TO FILL IN THE IDS (see docs/SETUP_GUIDE.md, step 5):
--   Game passes: Creator Dashboard > your game > Monetization > Passes
--   Cosmetics:   Creator Dashboard > your game > Monetization > Developer Products
-- An id of 0 means "not set up yet": the item shows as "Coming soon" in the shop.

local Shop = {}

Shop.Passes = {
	{ id = "VIP", gamePassId = 0, name = "VIP", suggestedPrice = 250, description = "Golden VIP name tag, a crown, and access to the VIP lounge." },
	{ id = "AutoSell", gamePassId = 0, name = "Auto Sell", suggestedPrice = 150, description = "Your backpack sells itself when it fills up, wherever you are." },
	{ id = "BigBag", gamePassId = 0, name = "Big Backpack", suggestedPrice = 100, description = "Carry 60 finds instead of 20." },
	{ id = "Teleporter", gamePassId = 0, name = "Zone Teleporter", suggestedPrice = 200, description = "Teleport to any zone you have unlocked." },
}

-- kind: "rodSkin" changes how your shovel looks, "trail" adds a trail behind you,
-- "title" shows a title above your head.
Shop.Cosmetics = {
	{ id = "skin_golden", kind = "rodSkin", name = "Golden Shovel Skin", productId = 0, suggestedPrice = 99, color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Foil },
	{ id = "skin_neon", kind = "rodSkin", name = "Neon Pink Shovel Skin", productId = 0, suggestedPrice = 75, color = Color3.fromRGB(255, 60, 200), material = Enum.Material.Neon },
	{ id = "skin_galaxy", kind = "rodSkin", name = "Galaxy Shovel Skin", productId = 0, suggestedPrice = 149, color = Color3.fromRGB(110, 60, 255), material = Enum.Material.ForceField },
	{ id = "skin_candy", kind = "rodSkin", name = "Candy Shovel Skin", productId = 0, suggestedPrice = 49, color = Color3.fromRGB(255, 120, 150), material = Enum.Material.SmoothPlastic },

	{ id = "trail_sparkle", kind = "trail", name = "Sparkle Trail", productId = 0, suggestedPrice = 49, colors = { Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 255, 200) } },
	{ id = "trail_fire", kind = "trail", name = "Fire Trail", productId = 0, suggestedPrice = 75, colors = { Color3.fromRGB(255, 220, 0), Color3.fromRGB(255, 40, 0) } },
	{ id = "trail_rainbow", kind = "trail", name = "Rainbow Trail", productId = 0, suggestedPrice = 129, colors = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 120, 255), Color3.fromRGB(200, 0, 255) } },

	{ id = "title_lucky", kind = "title", name = "Title: Lucky Digger", text = "Lucky Digger", productId = 0, suggestedPrice = 25, color = Color3.fromRGB(120, 200, 255) },
	{ id = "title_whisperer", kind = "title", name = "Title: Rock Whisperer", text = "Rock Whisperer", productId = 0, suggestedPrice = 49, color = Color3.fromRGB(160, 255, 160) },
	{ id = "title_diglegend", kind = "title", name = "Title: Dig Legend", text = "Dig Legend", productId = 0, suggestedPrice = 99, color = Color3.fromRGB(255, 190, 60) },
}

-- Free titles earned by playing. The server checks the "rule".
Shop.EarnedTitles = {
	{ id = "earned_shallows", kind = "title", name = "Shallows Master", text = "Shallows Master", rule = "zoneBook", zone = "shallows", color = Color3.fromRGB(255, 220, 120) },
	{ id = "earned_mangroves", kind = "title", name = "Mangrove Master", text = "Mangrove Master", rule = "zoneBook", zone = "mangroves", color = Color3.fromRGB(110, 200, 110) },
	{ id = "earned_frostbite", kind = "title", name = "Frostbite Master", text = "Frostbite Master", rule = "zoneBook", zone = "frostbite", color = Color3.fromRGB(170, 220, 255) },
	{ id = "earned_legend", kind = "title", name = "Legend Hunter", text = "Legend Hunter", rule = "eventFish", color = Color3.fromRGB(255, 150, 0) },
	{ id = "earned_reborn", kind = "title", name = "Reborn", text = "Reborn", rule = "rebirth", color = Color3.fromRGB(255, 90, 160) },
}

Shop.PassById = {}
for _, pass in ipairs(Shop.Passes) do
	Shop.PassById[pass.id] = pass
end

Shop.CosmeticById = {}
Shop.CosmeticByProductId = {}
for _, item in ipairs(Shop.Cosmetics) do
	Shop.CosmeticById[item.id] = item
	if item.productId ~= 0 then
		Shop.CosmeticByProductId[item.productId] = item
	end
end
for _, item in ipairs(Shop.EarnedTitles) do
	item.earned = true
	Shop.CosmeticById[item.id] = item
end

return Shop
