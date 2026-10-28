-- Creates the Dig Legends game passes and developer products through Roblox
-- Open Cloud, with their prices and icons, so nobody has to make them by hand.
--
-- One-time setup:
--   1. Creator Hub > Open Cloud > API Keys > Create API Key, with write access to
--      "game-passes" and "developer-products" for this experience only.
--   2. In Studio: File > Experience Settings > Security: turn on Allow HTTP Requests,
--      and under Local Secrets create one named ShopKey holding the key, domain
--      apis.roblox.com.
-- Then press Play, pick the Server view and paste this file into the command bar.
-- It prints one "ITEM" line per item with its new id. Developer products that
-- already exist (same name) are skipped, but game passes are not, so running it
-- twice makes duplicate passes. The key needs write access to both game-passes
-- and developer-products. Turn Allow HTTP Requests off again afterwards.
-- Used on 2026-10-28: the ids it made are in src/shared/Shop.luau.

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local UNIVERSE = 10773541582
local ICONS = "https://raw.githubusercontent.com/Pandot-Gamedev/dig-legends/main/store/"
local key = HttpService:GetSecret("ShopKey")

local PASSES = {
	{ "VIP", 250, "Golden VIP name tag, a crown, and access to the VIP lounge.", "pass_vip.png" },
	{ "Zone Teleporter", 200, "Teleport to any zone you have unlocked.", "pass_teleporter.png" },
	{ "Auto Sell", 150, "Your backpack sells itself when it fills up, wherever you are.", "pass_auto_sell.png" },
	{ "Big Backpack", 100, "Carry 60 finds instead of 20.", "pass_big_bag.png" },
}
local PRODUCTS = {
	{ "Galaxy Shovel Skin", 149, "A swirling galaxy look for your shovel. Looks only.", "product_skin_galaxy.png" },
	{ "Golden Shovel Skin", 99, "A shiny gold look for your shovel. Looks only.", "product_skin_golden.png" },
	{ "Neon Pink Shovel Skin", 75, "A glowing pink look for your shovel. Looks only.", "product_skin_neon.png" },
	{ "Candy Shovel Skin", 49, "A sweet candy look for your shovel. Looks only.", "product_skin_candy.png" },
	{ "Rainbow Trail", 129, "A rainbow trail follows you everywhere. Looks only.", "product_trail_rainbow.png" },
	{ "Fire Trail", 75, "A trail of flames follows you everywhere. Looks only.", "product_trail_fire.png" },
	{ "Sparkle Trail", 49, "A blue sparkle trail follows you everywhere. Looks only.", "product_trail_sparkle.png" },
	{ "Title: Dig Legend", 99, "Shows \"Dig Legend\" above your head.", "product_title_diglegend.png" },
	{ "Title: Rock Whisperer", 49, "Shows \"Rock Whisperer\" above your head.", "product_title_whisperer.png" },
	{ "Title: Lucky Digger", 25, "Shows \"Lucky Digger\" above your head.", "product_title_lucky.png" },
}

-- A multipart/form-data body with text fields and one PNG file
local function form(fields, fileField, fileName, png)
	local boundary = "DigLegends" .. HttpService:GenerateGUID(false):gsub("-", "")
	local parts = {}
	for _, field in ipairs(fields) do
		table.insert(parts, string.format("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s\r\n", boundary, field[1], tostring(field[2])))
	end
	if png then
		table.insert(parts, string.format("--%s\r\nContent-Disposition: form-data; name=\"%s\"; filename=\"%s\"\r\nContent-Type: image/png\r\n\r\n", boundary, fileField, fileName) .. png .. "\r\n")
	end
	table.insert(parts, "--" .. boundary .. "--\r\n")
	return table.concat(parts), "multipart/form-data; boundary=" .. boundary
end

local function icon(fileName)
	local ok, png = pcall(HttpService.GetAsync, HttpService, ICONS .. fileName)
	if not ok then
		warn("ICON missing " .. fileName .. ": " .. tostring(png))
		return nil
	end
	return png
end

local function post(path, body, contentType)
	local ok, response = pcall(HttpService.RequestAsync, HttpService, {
		Url = "https://apis.roblox.com" .. path,
		Method = "POST",
		Headers = { ["x-api-key"] = key, ["Content-Type"] = contentType },
		Body = body,
	})
	if not ok then
		return nil, tostring(response)
	end
	if not response.Success then
		return nil, response.StatusCode .. " " .. response.Body:sub(1, 300)
	end
	return HttpService:JSONDecode(response.Body)
end

-- Developer products that already exist, by name, so a second run skips them
local existingProducts = {}
local pages = MarketplaceService:GetDeveloperProductsAsync()
while true do
	for _, product in ipairs(pages:GetCurrentPage()) do
		existingProducts[product.Name] = product.ProductId
	end
	if pages.IsFinished then
		break
	end
	pages:AdvanceToNextPageAsync()
end

for _, pass in ipairs(PASSES) do
	local body, contentType = form({
		{ "name", pass[1] },
		{ "description", pass[3] },
		{ "isForSale", "true" },
		{ "price", pass[2] },
		{ "isRegionalPricingEnabled", "true" },
	}, "imageFile", pass[4], icon(pass[4]))
	local result, problem = post(string.format("/game-passes/v1/universes/%d/game-passes", UNIVERSE), body, contentType)
	if result then
		print("ITEM pass", pass[1], result.gamePassId or result.id or HttpService:JSONEncode(result))
	else
		warn("FAILED pass " .. pass[1] .. ": " .. problem)
	end
	task.wait(1)
end

for _, product in ipairs(PRODUCTS) do
	if existingProducts[product[1]] then
		print("ITEM product", product[1], existingProducts[product[1]], "(already there)")
	else
		local body, contentType = form({
			{ "name", product[1] },
			{ "description", product[3] },
			{ "isForSale", "true" },
			{ "price", product[2] },
			{ "isRegionalPricingEnabled", "true" },
		}, "imageFile", product[4], icon(product[4]))
		local result, problem = post(string.format("/developer-products/v2/universes/%d/developer-products", UNIVERSE), body, contentType)
		if result then
			print("ITEM product", product[1], result.productId or result.id or HttpService:JSONEncode(result))
		else
			warn("FAILED product " .. product[1] .. ": " .. problem)
		end
		task.wait(1)
	end
end
print("ITEM done")
