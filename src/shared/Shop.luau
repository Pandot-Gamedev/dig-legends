-- Everything sold for Robux. Nothing here changes what you dig up or how
-- many coins you earn: only looks and time-savers.
--
-- HOW TO FILL IN THE IDS (step 5 of the build plan):
--   Game passes: Creator Dashboard > your game > Monetization > Passes
--   Cosmetics:   Creator Dashboard > your game > Monetization > Developer Products
-- An id of 0 means "not set up yet": the item shows as "Coming soon" in the shop.

local Shop = {}

Shop.Passes = {
	{ id = "VIP", gamePassId = 2057879657, name = "VIP", suggestedPrice = 250, description = "Golden VIP name tag, a crown, and access to the VIP lounge." },
	{ id = "AutoSell", gamePassId = 2060422905, name = "Auto Sell", suggestedPrice = 150, description = "Your backpack sells itself when it fills up, wherever you are." },
	{ id = "BigBag", gamePassId = 2058845634, name = "Big Backpack", suggestedPrice = 100, description = "Carry 60 finds instead of 20." },
	{ id = "Teleporter", gamePassId = 2058899650, name = "Zone Teleporter", suggestedPrice = 200, description = "Teleport to any zone you have unlocked." },
}

-- kind: "shovelSkin" changes how your shovel looks, "trail" adds a trail behind you,
-- "title" shows a title above your head.
Shop.Cosmetics = {
	{ id = "skin_golden", kind = "shovelSkin", name = "Golden Shovel Skin", productId = 3723377192, suggestedPrice = 99, color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Foil },
	{ id = "skin_neon", kind = "shovelSkin", name = "Neon Pink Shovel Skin", productId = 3723377204, suggestedPrice = 75, color = Color3.fromRGB(255, 60, 200), material = Enum.Material.Neon },
	{ id = "skin_galaxy", kind = "shovelSkin", name = "Galaxy Shovel Skin", productId = 3723377180, suggestedPrice = 149, color = Color3.fromRGB(110, 60, 255), material = Enum.Material.ForceField },
	{ id = "skin_candy", kind = "shovelSkin", name = "Candy Shovel Skin", productId = 3723377224, suggestedPrice = 49, color = Color3.fromRGB(255, 120, 150), material = Enum.Material.SmoothPlastic },

	{ id = "trail_sparkle", kind = "trail", name = "Sparkle Trail", productId = 3723377257, suggestedPrice = 49, colors = { Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 255, 200) } },
	{ id = "trail_fire", kind = "trail", name = "Fire Trail", productId = 3723377243, suggestedPrice = 75, colors = { Color3.fromRGB(255, 220, 0), Color3.fromRGB(255, 40, 0) } },
	{ id = "trail_rainbow", kind = "trail", name = "Rainbow Trail", productId = 3723377236, suggestedPrice = 129, colors = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 120, 255), Color3.fromRGB(200, 0, 255) } },

	{ id = "title_lucky", kind = "title", name = "Title: Lucky Digger", text = "Lucky Digger", productId = 3723377288, suggestedPrice = 25, color = Color3.fromRGB(120, 200, 255) },
	{ id = "title_whisperer", kind = "title", name = "Title: Rock Whisperer", text = "Rock Whisperer", productId = 3723377276, suggestedPrice = 49, color = Color3.fromRGB(160, 255, 160) },
	{ id = "title_diglegend", kind = "title", name = "Title: Dig Legend", text = "Dig Legend", productId = 3723377268, suggestedPrice = 99, color = Color3.fromRGB(255, 190, 60) },
}

-- Free titles earned by playing. The server checks the "rule".
Shop.EarnedTitles = {
	{ id = "earned_backyard", kind = "title", name = "Backyard Master", text = "Backyard Master", rule = "zoneBook", zone = "backyard", color = Color3.fromRGB(140, 210, 110) },
	{ id = "earned_desert", kind = "title", name = "Desert Master", text = "Desert Master", rule = "zoneBook", zone = "desert", color = Color3.fromRGB(240, 190, 90) },
	{ id = "earned_caves", kind = "title", name = "Crystal Master", text = "Crystal Master", rule = "zoneBook", zone = "caves", color = Color3.fromRGB(180, 130, 255) },
	{ id = "earned_ruins", kind = "title", name = "Ruins Master", text = "Ruins Master", rule = "zoneBook", zone = "ruins", color = Color3.fromRGB(90, 200, 190) },
	{ id = "earned_volcano", kind = "title", name = "Volcano Master", text = "Volcano Master", rule = "zoneBook", zone = "volcano", color = Color3.fromRGB(255, 110, 50) },
	{ id = "earned_legend", kind = "title", name = "Legend Hunter", text = "Legend Hunter", rule = "eventFind", color = Color3.fromRGB(255, 150, 0) },
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
