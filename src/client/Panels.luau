-- The menus: Bag, Fish Market, Bait & Tackle, Bounties, Fish Book, Rods,
-- Shop, Travel and Rebirth.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Fish = require(Shared.Fish)
local Rods = require(Shared.Rods)
local Zones = require(Shared.Zones)
local Shop = require(Shared.Shop)
local Events = require(Shared.Events)
local Bait = require(Shared.Bait)
local Market = require(Shared.Market)
local Bounties = require(Shared.Bounties)
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

------------------------------------------------------------------ Bag and Fish Market
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
		table.insert(names, Fish.ById[id].name)
	end
	table.sort(names)
	return table.concat(names, ", ")
end

-- One row per fish. selling = true shows Sell buttons (Fish Market only).
local function fishRows(body, data, selling, startOrder)
	local hot = Market.HotFish()
	local bag = sortedBag(data)
	if #bag == 0 then
		UI.label("Your bag is empty. Go catch some fish!", { Size = UDim2.new(1, -8, 0, 26), Font = T.BodyFont, TextColor3 = T.Muted, LayoutOrder = startOrder, Parent = body })
		return
	end
	for index, entry in ipairs(bag) do
		local fish = Fish.ById[entry.id]
		local rarity = Fish.RarityById[fish.rarity]
		local card = row(body, 50, startOrder + index)
		local name = (entry.shiny and "Shiny " or "") .. fish.name
		UI.label(name, { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(0.5, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rarity.color, Parent = card })
		local price = Market.Price(entry, data.rebirths, hot)
		local detail = string.format("%s  -  %s  -  %s coins%s", fish.rarity, Format.Weight(entry.weight), Format.Number(price), hot[entry.id] and "  (IN DEMAND x2)" or "")
		UI.label(detail, { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(0.6, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = hot[entry.id] and T.Gold or T.Muted, Parent = card })

		local uid = tostring(entry.uid)
		UI.button(entry.favorite and "Favorite" or "Keep?", entry.favorite and T.Gold or T.Card, function()
			act("ToggleFavorite", uid)
		end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, selling and -112 or -12, 0.5, 0), Size = UDim2.fromOffset(96, 34), Parent = card })
		if selling then
			UI.button("Sell", entry.favorite and T.Card or T.Good, function()
				act("SellFish", uid)
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
	heading(body, string.format("Fish (%d/%d)", #data.bag, size), 1)
	UI.label("Favorites are never sold, used for bait or turned in. Sell at the Fish Market.", { Size = UDim2.new(1, -8, 0, 20), Font = T.BodyFont, TextColor3 = T.Muted, LayoutOrder = 2, Parent = body })
	fishRows(body, data, false, 10)

	heading(body, "Bait (goes on your hook)", 1000)
	for index, bait in ipairs(Bait.List) do
		local count = bait.free and math.huge or (data.bait.owned[bait.id] or 0)
		if count > 0 then
			local card = row(body, 50, 1000 + index)
			UI.label(bait.name .. (bait.free and "" or ("  x" .. count)), { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(0.6, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = bait.color, Parent = card })
			UI.label(bait.description, { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(0.7, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Muted, Parent = card })
			local equipped = data.bait.equipped == bait.id
			UI.button(equipped and "On hook" or "Use", equipped and T.Card or T.Accent, function()
				act("EquipBait", bait.id)
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
	local hot, left = Market.HotFish()
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
			total += Market.Price(entry, data.rebirths, hot)
			count += 1
		end
	end
	UI.button(string.format("Sell all %d for %s coins (keeps favorites)", count, Format.Number(total)), count > 0 and T.Good or T.Card, function()
		act("SellAll")
	end, { Size = UDim2.new(1, -8, 0, 44), LayoutOrder = 2, Parent = body })
	UI.label("Tip: keep fish that are about to be in demand, or trade them for bait and bounties.", { Size = UDim2.new(1, -8, 0, 18), Font = T.BodyFont, TextColor3 = T.Muted, LayoutOrder = 3, Parent = body })
	fishRows(body, data, true, 10)
end

------------------------------------------------------------------ Bait & Tackle
local function fishCountByRarity(data)
	local counts = {}
	for _, entry in ipairs(data.bag) do
		if not entry.favorite then
			local rarity = Fish.ById[entry.id].rarity
			counts[rarity] = (counts[rarity] or 0) + 1
		end
	end
	return counts
end

local function renderBait(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	local counts = fishCountByRarity(data)
	UI.label("Better bait = better fish. A fish that bites eats the bait, even if it gets away.", { Size = UDim2.new(1, -8, 0, 20), Font = T.BodyFont, TextColor3 = T.Muted, LayoutOrder = 0, Parent = body })
	for index, bait in ipairs(Bait.List) do
		if not bait.free then
			local owned = data.bait.owned[bait.id] or 0
			local card = row(body, 96, index)
			UI.label(string.format("%s  (you have %d)", bait.name, owned), { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.45, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = bait.color, Parent = card })
			UI.label(bait.description, { Position = UDim2.fromOffset(12, 32), Size = UDim2.new(0.45, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Muted, Parent = card })
			if bait.recipe then
				local parts, canCraft = {}, true
				for _, need in ipairs(bait.recipe) do
					local have = counts[need.rarity] or 0
					canCraft = canCraft and have >= need.count
					table.insert(parts, string.format("%d %s (have %d)", need.count, need.rarity, have))
				end
				UI.label(string.format("Make %d from: %s", bait.craftAmount, table.concat(parts, " + ")), { Position = UDim2.fromOffset(12, 54), Size = UDim2.new(0.62, 0, 0, 34), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Text, Parent = card })
				UI.button("Make", canCraft and T.Good or T.Card, function()
					act("CraftBait", bait.id)
				end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 52), Size = UDim2.fromOffset(150, 34), Parent = card })
			end
			if bait.price then
				UI.button(string.format("Buy %d: %s", bait.buyAmount, Format.Number(bait.price)), data.coins >= bait.price and T.Accent or T.Card, function()
					act("BuyBait", bait.id)
				end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(150, 34), Parent = card })
			end
			if owned > 0 then
				local equipped = data.bait.equipped == bait.id
				UI.button(equipped and "On hook" or "Use", equipped and T.Card or T.Accent, function()
					act("EquipBait", bait.id)
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
	UI.label(string.format("Old Pete pays %dx the market price, plus bait. New bounties in %s.", Bounties.RewardMultiplier, Format.Duration(resetIn)), {
		Size = UDim2.new(1, -8, 0, 22),
		Font = T.BodyFont,
		TextColor3 = T.Muted,
		LayoutOrder = 0,
		Parent = body,
	})
	for index, bounty in ipairs(data.bounties.list) do
		local fish = Fish.ById[bounty.fishId]
		local rarity = Fish.RarityById[fish.rarity]
		local have = 0
		for _, entry in ipairs(data.bag) do
			if entry.id == bounty.fishId and not entry.favorite then
				have += 1
			end
		end
		local card = row(body, 70, index)
		UI.label(string.format("Bring %d %s", bounty.count, fish.name), { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.62, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rarity.color, Parent = card })
		local reward = Bounties.Reward(bounty, Config.SellMultiplier(data.rebirths))
		local zone = Zones.ById[fish.zone]
		UI.label(string.format("Have %d/%d  -  found in %s  -  reward %s coins + %d %s", math.min(have, bounty.count), bounty.count, zone and zone.name or "", Format.Number(reward), bounty.baitAmount, Bait.ById[bounty.bait].name), {
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

------------------------------------------------------------------ Fish Book
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
		table.insert(tabList, { id = zone.id, name = zone.name, fish = Fish.ByZone[zone.id] or {} })
	end
	table.insert(tabList, { id = "event", name = "Legends", fish = Fish.EventFish })

	local found, total = 0, #Fish.List
	for id in pairs(data.book) do
		if Fish.ById[id] then
			found += 1
		end
	end

	local current
	for index, tab in ipairs(tabList) do
		if tab.id == bookTab then
			current = tab
		end
		UI.button(tab.name, tab.id == bookTab and T.Accent or T.Card, function()
			bookTab = tab.id
			Panels.Book.refresh()
		end, { Size = UDim2.fromOffset(136, 36), LayoutOrder = index, Parent = tabs })
	end
	current = current or tabList[1]

	local zoneFound = 0
	for _, fish in ipairs(current.fish) do
		if data.book[fish.id] then
			zoneFound += 1
		end
	end
	UI.label(string.format("%s: %d/%d found   (whole book: %d/%d)", current.name, zoneFound, #current.fish, found, total), {
		Size = UDim2.new(1, -8, 0, 24),
		Font = T.BodyFont,
		TextColor3 = T.Muted,
		LayoutOrder = 2,
		Parent = body,
	})

	local grid = UI.new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = body }, {
		UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(134, 112), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	for index, fish in ipairs(current.fish) do
		local entry = data.book[fish.id]
		local rarity = Fish.RarityById[fish.rarity]
		local card = UI.new("Frame", { BackgroundColor3 = T.Card, LayoutOrder = index, Parent = grid }, { UI.corner(10), UI.stroke(rarity.color, 2), UI.padding(6), UI.list(2) })
		UI.label(entry and fish.name or "???", { Size = UDim2.new(1, 0, 0, 34), TextWrapped = true, Parent = card })
		UI.label(fish.rarity, { Size = UDim2.new(1, 0, 0, 18), TextColor3 = rarity.color, Parent = card })
		local detail = "Not caught yet"
		if entry then
			detail = string.format("x%d  best %s", entry.count, Format.Weight(entry.best))
			if entry.shiny > 0 then
				detail ..= string.format("\n%d shiny", entry.shiny)
			end
		end
		UI.label(detail, { Size = UDim2.new(1, 0, 0, 34), Font = T.BodyFont, TextColor3 = T.Muted, TextWrapped = true, Parent = card })
	end

	if current.id == "event" then
		local eventFish, left = Events.GetEventFish()
		local zone = Zones.ById[eventFish.zone]
		UI.label(string.format("This week: %s in %s (ends in %s)", eventFish.name, zone and zone.name or "", Format.Duration(left)), {
			Size = UDim2.new(1, -8, 0, 24),
			Font = T.BodyFont,
			TextColor3 = T.Gold,
			LayoutOrder = 4,
			Parent = body,
		})
	end
end

------------------------------------------------------------------ Rods
local function renderRods(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	for index, rod in ipairs(Rods.List) do
		local card = row(body, 64, index)
		UI.label(rod.name, { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.6, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rod.color:Lerp(Color3.new(1, 1, 1), 0.4), Parent = card })
		local stats = string.format("Luck x%.2f   Bites %d%% faster   Fight control +%d%%", rod.luck, math.floor((1 - rod.speed) * 100 + 0.5), math.floor(rod.control * 100 + 0.5))
		UI.label(stats, { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(0.68, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Muted, Parent = card })

		local text, color, onClick
		if data.equippedRod == rod.id then
			text, color = "Equipped", T.Card
		elseif data.rodsOwned[rod.id] then
			text, color = "Equip", T.Accent
			onClick = function()
				act("EquipRod", rod.id)
			end
		elseif rod.requiresRebirths and data.rebirths < rod.requiresRebirths then
			text, color = string.format("%d rebirth", rod.requiresRebirths), T.Card
		else
			text = Format.Number(rod.price) .. " coins"
			color = data.coins >= rod.price and T.Good or T.Bad
			onClick = function()
				act("BuyRod", rod.id)
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

	heading(body, "Rod skins (looks only)", nextOrder())
	for _, item in ipairs(Shop.Cosmetics) do
		if item.kind == "rodSkin" then
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
	UI.label("Harbor (hub)", { Position = UDim2.fromOffset(12, 14), Size = UDim2.new(0.6, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Parent = hubRow })
	UI.button("Go", T.Accent, function()
		if act("Teleport", "hub") then
			Panels.Teleport.close()
		end
	end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 38), Parent = hubRow })

	for index, zone in ipairs(Zones.List) do
		local card = row(body, 56, index + 1)
		UI.label(zone.name, { Position = UDim2.fromOffset(12, 14), Size = UDim2.new(0.6, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = zone.color, Parent = card })
		local props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(150, 38), Parent = card }
		if not data.zones[zone.id] then
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
	local nowBonus = math.floor((Config.SellMultiplier(data.rebirths) - 1) * 100 + 0.5)
	local nextBonus = math.floor((Config.SellMultiplier(data.rebirths + 1) - 1) * 100 + 0.5)
	local requiredZone = Zones.ById[Config.RebirthRequiresZone]

	local lines = {
		string.format("Rebirths: %d   (now +%d%% coins from fish)", data.rebirths, nowBonus),
		string.format("Next rebirth: +%d%% coins from fish, forever", nextBonus),
		string.format("Cost: %s coins", Format.Number(cost)),
		"You keep: your Fish Book, favorite fish, bait, titles, skins, trails and passes.",
		"You reset: coins, rods, unlocked zones and the rest of your bag.",
	}
	if requiredZone then
		table.insert(lines, "Requires: " .. requiredZone.name .. " unlocked.")
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
	Panels.Bag = UI.window(screenGui, "Bag", renderBag)
	Panels.Market = UI.window(screenGui, "Fish Market", renderMarket)
	Panels.Bait = UI.window(screenGui, "Bait & Tackle", renderBait)
	Panels.Bounties = UI.window(screenGui, "Old Pete's Bounties", renderBounties)
	Panels.Book = UI.window(screenGui, "Fish Book", renderBook)
	Panels.Rods = UI.window(screenGui, "Rods", renderRods)
	Panels.Shop = UI.window(screenGui, "Shop", renderShop)
	Panels.Teleport = UI.window(screenGui, "Travel", renderTeleport)
	Panels.Rebirth = UI.window(screenGui, "Rebirth", renderRebirth)

	State.Changed:Connect(function()
		for _, name in ipairs({ "Bag", "Market", "Bait", "Bounties", "Book", "Rods", "Shop", "Teleport", "Rebirth" }) do
			Panels[name].refresh()
		end
	end)
end

return Panels
