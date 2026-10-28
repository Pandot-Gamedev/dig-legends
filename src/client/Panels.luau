-- The menus: Backpack, Trading Post, Charm Cart, Bounties, Collection, Shovels,
-- Shop, Travel and Rebirth.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Finds = require(Shared.Finds)
local Shovels = require(Shared.Shovels)
local Zones = require(Shared.Zones)
local Shop = require(Shared.Shop)
local Events = require(Shared.Events)
local Charms = require(Shared.Charms)
local Market = require(Shared.Market)
local Bounties = require(Shared.Bounties)
local Level = require(Shared.Level)
local Format = require(Shared.Format)

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local Notifications = require(script.Parent.Notifications)
local T = UI.Theme

local player = Players.LocalPlayer
local Panels = {}

local function act(actionName, argument)
	local ok, message = State.Action(actionName, argument)
	if not ok and message then
		Notifications.Show(message, "warning")
	end
	return ok
end

-- Robux prices come from Roblox, so they always match the Creator Dashboard
local priceCache = {}
local function robuxPrice(id, infoType, onReady)
	local key = tostring(infoType) .. id
	if priceCache[key] then
		onReady(priceCache[key])
		return
	end
	task.spawn(function()
		-- Asks Roblox every time instead of hard-coding prices, so each player sees
		-- their own regional price
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(id, infoType)
		end)
		if not ok then
			ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(id, infoType)
			end)
		end
		if ok and info and info.PriceInRobux then
			priceCache[key] = info.PriceInRobux
			onReady(info.PriceInRobux)
		end
	end)
end

local function row(parent, height, order)
	return UI.new("Frame", {
		Size = UDim2.new(1, -8, 0, height),
		BackgroundColor3 = T.Card,
		LayoutOrder = order or 0,
		Parent = parent,
	}, { UI.corner(10) })
end

local function heading(parent, text, order)
	UI.label(text, { Size = UDim2.new(1, -8, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = T.Gold, LayoutOrder = order, Parent = parent })
end

------------------------------------------------------------------ Backpack and Trading Post
local function sortedBag(data)
	local list = table.clone(data.bag)
	table.sort(list, function(a, b)
		return a.value > b.value
	end)
	return list
end

local function hotNames(hot)
	local names = {}
	for id in pairs(hot) do
		table.insert(names, Finds.ById[id].name)
	end
	table.sort(names)
	return table.concat(names, ", ")
end

-- One row per find. selling = true shows Sell buttons (Trading Post only).
local function findRows(body, data, selling, startOrder)
	local hot = Market.HotFinds()
	local bag = sortedBag(data)
	if #bag == 0 then
		UI.label("Your backpack is empty. Go dig something up!", { Size = UDim2.new(1, -8, 0, 26), Font = T.BodyFont, TextColor3 = T.Muted, LayoutOrder = startOrder, Parent = body })
		return
	end
	for index, entry in ipairs(bag) do
		local find = Finds.ById[entry.id]
		local rarity = Finds.RarityById[find.rarity]
		local card = row(body, 50, startOrder + index)
		local name = (entry.shiny and "Shiny " or "") .. find.name
		UI.label(name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(0.5, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rarity.color, Parent = card })
		local price = Market.Price(entry, data, hot)
		local detail = string.format("%s  -  %s  -  %s coins%s", find.rarity, Format.Weight(entry.weight), Format.Number(price), hot[entry.id] and "  (IN DEMAND x2)" or "")
		UI.label(detail, { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(0.6, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = hot[entry.id] and T.Gold or T.Muted, Parent = card })

		local uid = tostring(entry.uid)
		UI.button(entry.favorite and "Favorite" or "Keep?", entry.favorite and T.Gold or T.Card, function()
			act("ToggleFavorite", uid)
		end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, selling and -112 or -12, 0.5, 0), Size = UDim2.fromOffset(96, 34), Parent = card })
		if selling then
			UI.button("Sell", entry.favorite and T.Card or T.Good, function()
				act("SellFind", uid)
			end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(90, 34), Parent = card })
		end
	end
end

local function renderBag(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	local size = State.runtime.bagSize or Config.BagSize
	heading(body, string.format("Finds (%d/%d)", #data.bag, size), 1)
	UI.label("Favorites are never sold, used for charms or turned in. Sell at the Trading Post.", { Size = UDim2.new(1, -8, 0, 20), Font = T.BodyFont, TextColor3 = T.Muted, LayoutOrder = 2, Parent = body })
	findRows(body, data, false, 10)

	heading(body, "Charms (one is used up each dig)", 1000)
	for index, charm in ipairs(Charms.List) do
		local count = charm.free and math.huge or (data.charms.owned[charm.id] or 0)
		if count > 0 then
			local card = row(body, 50, 1000 + index)
			UI.label(charm.name .. (charm.free and "" or ("  x" .. count)), { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(0.6, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = charm.color, Parent = card })
			UI.label(charm.description, { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(0.7, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Muted, Parent = card })
			local equipped = data.charms.equipped == charm.id
			UI.button(equipped and "In use" or "Use", equipped and T.Card or T.Accent, function()
				act("EquipCharm", charm.id)
			end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(110, 34), Parent = card })
		end
	end
end

local function renderMarket(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	local hot, left = Market.HotFinds()
	UI.label(string.format("In demand (sells for x2) for %s: %s", Format.Duration(left), hotNames(hot)), {
		Size = UDim2.new(1, -8, 0, 40),
		TextWrapped = true,
		TextColor3 = T.Gold,
		LayoutOrder = 1,
		Parent = body,
	})

	local total, count = 0, 0
	for _, entry in ipairs(data.bag) do
		if not entry.favorite then
			total += Market.Price(entry, data, hot)
			count += 1
		end
	end
	UI.button(string.format("Sell all %d for %s coins (keeps favorites)", count, Format.Number(total)), count > 0 and T.Good or T.Card, function()
		act("SellAll")
	end, { Size = UDim2.new(1, -8, 0, 44), LayoutOrder = 2, Parent = body })
	UI.label("Tip: keep finds that are about to be in demand, or trade them for charms and bounties.", { Size = UDim2.new(1, -8, 0, 18), Font = T.BodyFont, TextColor3 = T.Muted, LayoutOrder = 3, Parent = body })
	findRows(body, data, true, 10)
end

------------------------------------------------------------------ Charm Cart
local function findCountByRarity(data)
	local counts = {}
	for _, entry in ipairs(data.bag) do
		if not entry.favorite then
			local rarity = Finds.ById[entry.id].rarity
			counts[rarity] = (counts[rarity] or 0) + 1
		end
	end
	return counts
end

local function renderCharms(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	local counts = findCountByRarity(data)
	UI.label("Charms bring luck. One is used up each time you find something, even if it breaks.", { Size = UDim2.new(1, -8, 0, 20), Font = T.BodyFont, TextColor3 = T.Muted, LayoutOrder = 0, Parent = body })
	for index, charm in ipairs(Charms.List) do
		if not charm.free then
			local owned = data.charms.owned[charm.id] or 0
			local card = row(body, 96, index)
			UI.label(string.format("%s  (you have %d)", charm.name, owned), { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.45, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = charm.color, Parent = card })
			UI.label(charm.description, { Position = UDim2.fromOffset(12, 32), Size = UDim2.new(0.45, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Muted, Parent = card })
			if charm.recipe then
				local parts, canCraft = {}, true
				for _, need in ipairs(charm.recipe) do
					local have = counts[need.rarity] or 0
					canCraft = canCraft and have >= need.count
					table.insert(parts, string.format("%d %s (have %d)", need.count, need.rarity, have))
				end
				UI.label(string.format("Make %d from: %s", charm.craftAmount, table.concat(parts, " + ")), { Position = UDim2.fromOffset(12, 54), Size = UDim2.new(0.62, 0, 0, 34), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Text, Parent = card })
				UI.button("Make", canCraft and T.Good or T.Card, function()
					act("CraftCharm", charm.id)
				end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 52), Size = UDim2.fromOffset(150, 34), Parent = card })
			end
			if charm.price then
				UI.button(string.format("Buy %d: %s", charm.buyAmount, Format.Number(charm.price)), data.coins >= charm.price and T.Accent or T.Card, function()
					act("BuyCharm", charm.id)
				end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(150, 34), Parent = card })
			end
			if owned > 0 then
				local equipped = data.charms.equipped == charm.id
				UI.button(equipped and "In use" or "Use", equipped and T.Card or T.Accent, function()
					act("EquipCharm", charm.id)
				end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -170, 0, 10), Size = UDim2.fromOffset(90, 34), Parent = card })
			end
		end
	end
end

------------------------------------------------------------------ Bounties
local function renderBounties(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	local now = os.time()
	local resetIn = 86400 - (now % 86400)
	UI.label(string.format("Grandpa Gus pays %dx the Trading Post price, plus charms. New bounties in %s.", Bounties.RewardMultiplier, Format.Duration(resetIn)), {
		Size = UDim2.new(1, -8, 0, 22),
		Font = T.BodyFont,
		TextColor3 = T.Muted,
		LayoutOrder = 0,
		Parent = body,
	})
	for index, bounty in ipairs(data.bounties.list) do
		local find = Finds.ById[bounty.findId]
		local rarity = Finds.RarityById[find.rarity]
		local have = 0
		for _, entry in ipairs(data.bag) do
			if entry.id == bounty.findId and not entry.favorite then
				have += 1
			end
		end
		local card = row(body, 70, index)
		UI.label(string.format("Bring %dx %s", bounty.count, find.name), { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.62, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rarity.color, Parent = card })
		local reward = Bounties.Reward(bounty, Market.Multiplier(data))
		local zone = Zones.ById[find.zone]
		UI.label(string.format("Have %d/%d  -  found in %s  -  reward %s coins + %d %s", math.min(have, bounty.count), bounty.count, zone and zone.name or "", Format.Number(reward), bounty.charmAmount, Charms.ById[bounty.charm].name), {
			Position = UDim2.fromOffset(12, 36),
			Size = UDim2.new(0.68, 0, 0, 28),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = T.BodyFont,
			TextColor3 = T.Muted,
			Parent = card,
		})
		local props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 40), Parent = card }
		if bounty.done then
			UI.button("Done!", T.Card, nil, props)
		else
			UI.button("Turn in", have >= bounty.count and T.Good or T.Card, function()
				act("ClaimBounty", tostring(index))
			end, props)
		end
	end
end

------------------------------------------------------------------ Collection
local bookTab = Zones.List[1].id

local function renderBook(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(10).Parent = body

	local tabs = UI.new("Frame", { Size = UDim2.new(1, -8, 0, 40), BackgroundTransparency = 1, LayoutOrder = 1, Parent = body }, { UI.list(8, Enum.FillDirection.Horizontal) })
	local tabList = {}
	for _, zone in ipairs(Zones.List) do
		table.insert(tabList, { id = zone.id, name = zone.name, short = zone.short, finds = Finds.ByZone[zone.id] or {} })
	end
	table.insert(tabList, { id = "event", name = "Weekly Legends", short = "Legends", finds = Finds.EventFinds })

	local found, total = 0, #Finds.List
	for id in pairs(data.book) do
		if Finds.ById[id] then
			found += 1
		end
	end

	local current
	for index, tab in ipairs(tabList) do
		if tab.id == bookTab then
			current = tab
		end
		UI.button(tab.short, tab.id == bookTab and T.Accent or T.Card, function()
			bookTab = tab.id
			Panels.Book.refresh()
		end, { Size = UDim2.new(1 / #tabList, -8, 0, 36), LayoutOrder = index, Parent = tabs })
	end
	current = current or tabList[1]

	local zoneFound = 0
	for _, find in ipairs(current.finds) do
		if data.book[find.id] then
			zoneFound += 1
		end
	end
	local header = string.format("%s: %d/%d found   (whole collection: %d/%d)", current.name, zoneFound, #current.finds, found, total)
	if current.id ~= "event" then
		header ..= Finds.IsPageComplete(data.book, current.id) and "   Page complete!" or string.format("   Complete it: +%d%% coins", math.floor(Config.PageSellBonus * 100 + 0.5))
	end
	UI.label(header, {
		Size = UDim2.new(1, -8, 0, 24),
		Font = T.BodyFont,
		TextColor3 = T.Muted,
		LayoutOrder = 2,
		Parent = body,
	})

	local grid = UI.new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = body }, {
		UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(134, 112), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	for index, find in ipairs(current.finds) do
		local entry = data.book[find.id]
		local rarity = Finds.RarityById[find.rarity]
		local card = UI.new("Frame", { BackgroundColor3 = T.Card, LayoutOrder = index, Parent = grid }, { UI.corner(10), UI.stroke(rarity.color, 2), UI.padding(6), UI.list(2) })
		UI.label(entry and find.name or "???", { Size = UDim2.new(1, 0, 0, 34), TextWrapped = true, Parent = card })
		UI.label(find.rarity, { Size = UDim2.new(1, 0, 0, 18), TextColor3 = rarity.color, Parent = card })
		local detail = "Not found yet"
		if entry then
			detail = string.format("x%d  best %s", entry.count, Format.Weight(entry.best))
			if entry.shiny > 0 then
				detail ..= string.format("\n%d shiny", entry.shiny)
			end
		end
		UI.label(detail, { Size = UDim2.new(1, 0, 0, 34), Font = T.BodyFont, TextColor3 = T.Muted, TextWrapped = true, Parent = card })
	end

	if current.id == "event" then
		local eventFind, left = Events.GetEventFind()
		local zone = Zones.ById[eventFind.zone]
		UI.label(string.format("This week: %s in %s (ends in %s)", eventFind.name, zone and zone.name or "", Format.Duration(left)), {
			Size = UDim2.new(1, -8, 0, 24),
			Font = T.BodyFont,
			TextColor3 = T.Gold,
			LayoutOrder = 4,
			Parent = body,
		})
	end
end

------------------------------------------------------------------ Shovels
local function renderShovels(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	for index, shovel in ipairs(Shovels.List) do
		local card = row(body, 64, index)
		UI.label(shovel.name, { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.6, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = shovel.color:Lerp(Color3.new(1, 1, 1), 0.4), Parent = card })
		local stats = string.format("Luck x%.2f   Digs %d%% faster   Sweet spot +%d%%", shovel.luck, math.floor((1 - shovel.speed) * 100 + 0.5), math.floor(shovel.power * 100 + 0.5))
		UI.label(stats, { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(0.68, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Muted, Parent = card })

		local text, color, onClick
		if data.equippedShovel == shovel.id then
			text, color = "Equipped", T.Card
		elseif data.shovelsOwned[shovel.id] then
			text, color = "Equip", T.Accent
			onClick = function()
				act("EquipShovel", shovel.id)
			end
		elseif shovel.requiresRebirths and data.rebirths < shovel.requiresRebirths then
			text, color = string.format("%d rebirth", shovel.requiresRebirths), T.Card
		else
			text = Format.Number(shovel.price) .. " coins"
			color = data.coins >= shovel.price and T.Good or T.Bad
			onClick = function()
				act("BuyShovel", shovel.id)
			end
		end
		UI.button(text, color, onClick, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(150, 40), Parent = card })
	end
end

------------------------------------------------------------------ Shop
local function renderShop(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	heading(body, "Game passes (yours forever)", nextOrder())
	for _, pass in ipairs(Shop.Passes) do
		local card = row(body, 64, nextOrder())
		UI.label(pass.name, { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.6, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		UI.label(pass.description, { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(0.68, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Muted, Parent = card })
		local button = UI.button("...", T.Good, nil, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 40), Parent = card })
		if State.HasPass(pass.id) then
			button.Text = "Owned"
			button.BackgroundColor3 = T.Card
		elseif pass.gamePassId == 0 then
			button.Text = "Coming soon"
			button.BackgroundColor3 = T.Card
		else
			robuxPrice(pass.gamePassId, Enum.InfoType.GamePass, function(price)
				button.Text = "R$ " .. price
			end)
			button.Activated:Connect(function()
				MarketplaceService:PromptGamePassPurchase(player, pass.gamePassId)
			end)
		end
	end

	local function cosmeticRow(item)
		local card = row(body, 52, nextOrder())
		local label = UI.label(item.name, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.65, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = label })
		local owned = data.cosmetics.owned[item.id]
		local equipped = data.cosmetics.equipped[item.kind] == item.id
		local button = UI.button("...", T.Good, nil, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 36), Parent = card })
		if owned then
			button.Text = equipped and "Unequip" or "Equip"
			button.BackgroundColor3 = equipped and T.Card or T.Accent
			button.Activated:Connect(function()
				act("EquipCosmetic", item.id)
			end)
		elseif item.earned then
			button.Text = "Not earned"
			button.BackgroundColor3 = T.Card
		elseif item.productId == 0 then
			button.Text = "Coming soon"
			button.BackgroundColor3 = T.Card
		else
			robuxPrice(item.productId, Enum.InfoType.Product, function(price)
				button.Text = "R$ " .. price
			end)
			button.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, item.productId)
			end)
		end
	end

	heading(body, "Shovel skins (looks only)", nextOrder())
	for _, item in ipairs(Shop.Cosmetics) do
		if item.kind == "shovelSkin" then
			cosmeticRow(item)
		end
	end
	heading(body, "Trails (looks only)", nextOrder())
	for _, item in ipairs(Shop.Cosmetics) do
		if item.kind == "trail" then
			cosmeticRow(item)
		end
	end
	heading(body, "Titles", nextOrder())
	for _, item in ipairs(Shop.Cosmetics) do
		if item.kind == "title" then
			cosmeticRow(item)
		end
	end
	heading(body, "Earned titles (free, unlocked by playing)", nextOrder())
	for _, item in ipairs(Shop.EarnedTitles) do
		cosmeticRow(item)
	end
end

------------------------------------------------------------------ Teleport
local function renderTeleport(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	local hasPass = State.HasPass("Teleporter")
	if not hasPass then
		UI.label("Walk across the bridges to reach zones, or get the Zone Teleporter pass in the Shop.", {
			Size = UDim2.new(1, -8, 0, 40),
			TextWrapped = true,
			Font = T.BodyFont,
			TextColor3 = T.Muted,
			LayoutOrder = 0,
			Parent = body,
		})
	end

	local hubRow = row(body, 56, 1)
	UI.label("Dig Town (hub)", { Position = UDim2.fromOffset(12, 14), Size = UDim2.new(0.6, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Parent = hubRow })
	UI.button("Go", T.Accent, function()
		if act("Teleport", "hub") then
			Panels.Teleport.close()
		end
	end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 38), Parent = hubRow })

	for index, zone in ipairs(Zones.List) do
		local card = row(body, 56, index + 1)
		UI.label(zone.name, { Position = UDim2.fromOffset(12, 14), Size = UDim2.new(0.6, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = zone.color, Parent = card })
		local props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(150, 38), Parent = card }
		local previous = Zones.Previous(zone.id)
		if not data.zones[zone.id] and previous and not data.zones[previous.id] then
			UI.button("Unlock " .. previous.short .. " first", T.Card, nil, props)
		elseif not data.zones[zone.id] and Level.FromXp(data.xp) < zone.level then
			UI.button("Needs Lv " .. zone.level, T.Card, nil, props)
		elseif not data.zones[zone.id] then
			UI.button("Unlock " .. Format.Number(zone.price), data.coins >= zone.price and T.Good or T.Bad, function()
				act("UnlockZone", zone.id)
			end, props)
		elseif hasPass then
			UI.button("Go", T.Accent, function()
				if act("Teleport", zone.id) then
					Panels.Teleport.close()
				end
			end, props)
		else
			UI.button("Unlocked", T.Card, nil, props)
		end
	end
end

------------------------------------------------------------------ Rebirth
local function renderRebirth(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(10).Parent = body
	local cost = Config.RebirthCost(data.rebirths)
	local pages = Finds.CompletedPages(data.book)
	local nowBonus = math.floor((Config.SellMultiplier(data.rebirths, pages) - 1) * 100 + 0.5)
	local nextBonus = math.floor((Config.SellMultiplier(data.rebirths + 1, pages) - 1) * 100 + 0.5)
	local requiredZone = Zones.ById[Config.RebirthRequiresZone]

	local lines = {
		string.format("Rebirths: %d   (now +%d%% coins from finds)", data.rebirths, nowBonus),
		string.format("Next rebirth: +%d%% coins from finds, forever", nextBonus),
		string.format("Cost: %s coins", Format.Number(cost)),
		"You keep: your Collection, favorite finds, charms, titles, skins, trails and passes.",
		"You reset: coins, shovels, unlocked zones and the rest of your backpack.",
	}
	if requiredZone then
		local done = data.zones[requiredZone.id] and "  (done)" or "  (not yet)"
		table.insert(lines, "Requires: " .. requiredZone.name .. " unlocked." .. done)
	end
	for index, text in ipairs(lines) do
		UI.label(text, { Size = UDim2.new(1, -8, 0, 26), TextWrapped = true, Font = index <= 3 and T.Font or T.BodyFont, TextColor3 = index <= 3 and T.Text or T.Muted, LayoutOrder = index, Parent = body })
	end
	local ready = data.coins >= cost and (not requiredZone or data.zones[requiredZone.id])
	UI.button("Rebirth", ready and T.Good or T.Card, function()
		if act("Rebirth") then
			Panels.Rebirth.close()
		end
	end, { Size = UDim2.fromOffset(200, 50), LayoutOrder = 99, Parent = body })
end

function Panels.Init(screenGui)
	Panels.Bag = UI.window(screenGui, "Backpack", renderBag)
	Panels.Market = UI.window(screenGui, "Trading Post", renderMarket)
	Panels.Charms = UI.window(screenGui, "Charm Cart", renderCharms)
	Panels.Bounties = UI.window(screenGui, "Grandpa Gus's Bounties", renderBounties)
	Panels.Book = UI.window(screenGui, "Collection", renderBook)
	Panels.Shovels = UI.window(screenGui, "Shovels", renderShovels)
	Panels.Shop = UI.window(screenGui, "Shop", renderShop)
	Panels.Teleport = UI.window(screenGui, "Travel", renderTeleport)
	Panels.Rebirth = UI.window(screenGui, "Rebirth", renderRebirth)

	State.Changed:Connect(function()
		for _, name in ipairs({ "Bag", "Market", "Charms", "Bounties", "Book", "Shovels", "Shop", "Teleport", "Rebirth" }) do
			Panels[name].refresh()
		end
	end)
end

return Panels
