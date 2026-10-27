-- Coins: the Fish Market, bait, bounties, rods, zones, rebirths and daily
-- rewards, plus the menu buttons players press (all go through the "Action" remote).

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Fish = require(Shared.Fish)
local Rods = require(Shared.Rods)
local Zones = require(Shared.Zones)
local Shop = require(Shared.Shop)
local Bait = require(Shared.Bait)
local Market = require(Shared.Market)
local Bounties = require(Shared.Bounties)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)
local TutorialService = require(script.Parent.TutorialService)

local EconomyService = {}

local function notify(player, text, kind)
	Remotes.Notify:FireClient(player, text, kind)
end

-- True if the player stands near a station (market, bait shop). Maps without
-- that station don't require it.
local function nearStation(player, station)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local found = false
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("Station") == station then
			found = true
			if root and (item.Position - root.Position).Magnitude <= Config.StationRange then
				return true
			end
		end
	end
	return not found
end

local function findInBag(data, uid)
	for index, fish in ipairs(data.bag) do
		if fish.uid == uid then
			return index, fish
		end
	end
	return nil
end

-- Sells every fish that isn't marked as a favorite.
-- auto = true for the Auto Sell pass (works anywhere).
function EconomyService.SellAll(player, auto)
	local data = DataService.Get(player)
	if not data then
		return false, "Still loading"
	end
	if not auto and not nearStation(player, "Sell") then
		return false, "Sell fish at the Fish Market"
	end
	local hot = Market.HotFish()
	local count, earned = DataService.Update(player, function(saved)
		local keep, total, sold = {}, 0, 0
		for _, fish in ipairs(saved.bag) do
			if fish.favorite then
				table.insert(keep, fish)
			else
				total += Market.Price(fish, saved.rebirths, hot)
				sold += 1
			end
		end
		saved.coins += total
		saved.totalEarned += total
		saved.bag = keep
		return sold, total
	end)
	if count == 0 then
		return false, "Nothing to sell (favorites are never sold)"
	end
	notify(player, string.format("Sold %d fish for %s coins", count, Format.Number(earned)), "coins")
	if not auto then
		TutorialService.Event(player, "Sell")
	end
	return true
end

function EconomyService.SellFish(player, uidText)
	local data = DataService.Get(player)
	local uid = tonumber(uidText)
	if not data or not uid then
		return false, "Unknown fish"
	end
	if not nearStation(player, "Sell") then
		return false, "Sell fish at the Fish Market"
	end
	local index, fish = findInBag(data, uid)
	if not index then
		return false, "That fish is gone"
	end
	if fish.favorite then
		return false, "Unfavorite it first"
	end
	local price = Market.Price(fish, data.rebirths)
	DataService.Update(player, function(saved)
		table.remove(saved.bag, index)
		saved.coins += price
		saved.totalEarned += price
	end)
	notify(player, string.format("Sold %s for %s coins", Fish.ById[fish.id].name, Format.Number(price)), "coins")
	TutorialService.Event(player, "Sell")
	return true
end

function EconomyService.ToggleFavorite(player, uidText)
	local data = DataService.Get(player)
	local index = data and findInBag(data, tonumber(uidText))
	if not index then
		return false, "That fish is gone"
	end
	DataService.Update(player, function(saved)
		saved.bag[index].favorite = not saved.bag[index].favorite or nil
	end)
	return true
end

function EconomyService.EquipBait(player, baitId)
	local bait = Bait.ById[baitId]
	local data = DataService.Get(player)
	if not bait or not data then
		return false, "Unknown bait"
	end
	if not bait.free and (data.bait.owned[bait.id] or 0) <= 0 then
		return false, "You don't have any " .. bait.name
	end
	DataService.Update(player, function(saved)
		saved.bait.equipped = bait.id
	end)
	return true
end

function EconomyService.BuyBait(player, baitId)
	local bait = Bait.ById[baitId]
	local data = DataService.Get(player)
	if not bait or not data or not bait.price then
		return false, "You can't buy that"
	end
	if not nearStation(player, "Bait") then
		return false, "Buy bait at the Bait & Tackle shop"
	end
	if data.coins < bait.price then
		return false, "Not enough coins"
	end
	DataService.Update(player, function(saved)
		saved.coins -= bait.price
		saved.bait.owned[bait.id] = (saved.bait.owned[bait.id] or 0) + bait.buyAmount
	end)
	notify(player, string.format("+%d %s", bait.buyAmount, bait.name), "success")
	return true
end

-- Which bag fish a recipe would use: the cheapest non-favorite fish of each rarity
local function pickIngredients(data, recipe)
	local used = {}
	for _, need in ipairs(recipe) do
		local candidates = {}
		for _, fish in ipairs(data.bag) do
			if not fish.favorite and not used[fish.uid] and Fish.ById[fish.id].rarity == need.rarity then
				table.insert(candidates, fish)
			end
		end
		if #candidates < need.count then
			return nil
		end
		table.sort(candidates, function(a, b)
			return a.value < b.value
		end)
		for i = 1, need.count do
			used[candidates[i].uid] = true
		end
	end
	return used
end
EconomyService.PickIngredients = pickIngredients

function EconomyService.CraftBait(player, baitId)
	local bait = Bait.ById[baitId]
	local data = DataService.Get(player)
	if not bait or not data or not bait.recipe then
		return false, "You can't make that"
	end
	if not nearStation(player, "Bait") then
		return false, "Make bait at the Bait & Tackle shop"
	end
	local used = pickIngredients(data, bait.recipe)
	if not used then
		return false, "You don't have the fish for that (favorites are never used)"
	end
	DataService.Update(player, function(saved)
		local keep = {}
		for _, fish in ipairs(saved.bag) do
			if not used[fish.uid] then
				table.insert(keep, fish)
			end
		end
		saved.bag = keep
		saved.bait.owned[bait.id] = (saved.bait.owned[bait.id] or 0) + bait.craftAmount
	end)
	notify(player, string.format("Made %d %s", bait.craftAmount, bait.name), "success")
	return true
end

-- Gives the player today's bounties if they don't have them yet
local function refreshBounties(player, data)
	local today = Bounties.Today(os.time())
	if data.bounties.day ~= today then
		data.bounties = { day = today, list = Bounties.Generate(player.UserId, today, data.zones) }
		return true
	end
	return false
end

function EconomyService.ClaimBounty(player, indexText)
	local data = DataService.Get(player)
	local index = tonumber(indexText)
	local bounty = data and index and data.bounties.list[index]
	if not bounty or bounty.done then
		return false, "That bounty is gone"
	end
	local chosen, found = {}, 0
	for _, fish in ipairs(data.bag) do
		if fish.id == bounty.fishId and not fish.favorite and found < bounty.count then
			chosen[fish.uid] = true
			found += 1
		end
	end
	if found < bounty.count then
		return false, string.format("You need %d %s (favorites don't count)", bounty.count, Fish.ById[bounty.fishId].name)
	end
	local reward = Bounties.Reward(bounty, Config.SellMultiplier(data.rebirths))
	DataService.Update(player, function(saved)
		local keep = {}
		for _, fish in ipairs(saved.bag) do
			if not chosen[fish.uid] then
				table.insert(keep, fish)
			end
		end
		saved.bag = keep
		saved.coins += reward
		saved.totalEarned += reward
		saved.bait.owned[bounty.bait] = (saved.bait.owned[bounty.bait] or 0) + bounty.baitAmount
		saved.bounties.list[index].done = true
	end)
	notify(player, string.format("Bounty done! +%s coins, +%d %s", Format.Number(reward), bounty.baitAmount, Bait.ById[bounty.bait].name), "coins")
	return true
end

function EconomyService.BuyRod(player, rodId)
	local rod = Rods.ById[rodId]
	local data = DataService.Get(player)
	if not rod or not data then
		return false, "Unknown rod"
	end
	if data.rodsOwned[rod.id] then
		return EconomyService.EquipRod(player, rodId)
	end
	if rod.requiresRebirths and data.rebirths < rod.requiresRebirths then
		return false, string.format("Needs %d rebirth(s)", rod.requiresRebirths)
	end
	if data.coins < rod.price then
		return false, "Not enough coins"
	end
	DataService.Update(player, function(saved)
		saved.coins -= rod.price
		saved.rodsOwned[rod.id] = true
		saved.equippedRod = rod.id
	end)
	notify(player, "You bought the " .. rod.name .. "!", "success")
	return true
end

function EconomyService.EquipRod(player, rodId)
	local data = DataService.Get(player)
	if not data or not data.rodsOwned[rodId] then
		return false, "You don't own that rod"
	end
	DataService.Update(player, function(saved)
		saved.equippedRod = rodId
	end)
	return true
end

function EconomyService.UnlockZone(player, zoneId)
	local zone = Zones.ById[zoneId]
	local data = DataService.Get(player)
	if not zone or not data then
		return false, "Unknown zone"
	end
	if data.zones[zone.id] then
		return true
	end
	if data.coins < zone.price then
		return false, string.format("You need %s coins to unlock %s", Format.Number(zone.price), zone.name)
	end
	DataService.Update(player, function(saved)
		saved.coins -= zone.price
		saved.zones[zone.id] = true
	end)
	notify(player, zone.name .. " unlocked!", "success")
	return true
end

function EconomyService.Teleport(player, zoneId)
	local data = DataService.Get(player)
	local character = player.Character
	if not data or not character then
		return false, "Not ready"
	end
	if zoneId ~= "hub" then
		if not ShopService.HasPass(player, "Teleporter") then
			return false, "The Zone Teleporter pass lets you teleport to zones"
		end
		if not data.zones[zoneId] then
			return false, "Unlock that zone first"
		end
	end
	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("ZoneSpawn") == zoneId then
			character:PivotTo(item.CFrame + Vector3.new(0, 4, 0))
			return true
		end
	end
	return false, "No teleport spot for that zone"
end

function EconomyService.Rebirth(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Not ready"
	end
	local cost = Config.RebirthCost(data.rebirths)
	local requiredZone = Zones.ById[Config.RebirthRequiresZone]
	if requiredZone and not data.zones[requiredZone.id] then
		return false, "Unlock " .. requiredZone.name .. " first"
	end
	if data.coins < cost then
		return false, string.format("You need %s coins to rebirth", Format.Number(cost))
	end
	DataService.Update(player, function(saved)
		-- Keep: fish book, favorite fish, bait, cosmetics, titles, stats. Reset: coins, rods, zones, other fish.
		saved.rebirths += 1
		saved.coins = 0
		local favorites = {}
		for _, fish in ipairs(saved.bag) do
			if fish.favorite then
				table.insert(favorites, fish)
			end
		end
		saved.bag = favorites
		saved.rodsOwned = { [Rods.Default] = true }
		saved.equippedRod = Rods.Default
		saved.zones = { [Zones.Default] = true }
	end)
	EconomyService.Teleport(player, "hub")
	notify(player, string.format("Reborn! You now earn +%d%% coins from fish.", math.floor((Config.SellMultiplier(data.rebirths) - 1) * 100 + 0.5)), "success")
	return true
end

function EconomyService.EquipCosmetic(player, cosmeticId)
	local item = Shop.CosmeticById[cosmeticId]
	local data = DataService.Get(player)
	if not item or not data or not data.cosmetics.owned[cosmeticId] then
		return false, "You don't own that"
	end
	DataService.Update(player, function(saved)
		if saved.cosmetics.equipped[item.kind] == cosmeticId then
			saved.cosmetics.equipped[item.kind] = nil -- pressing again takes it off
		else
			saved.cosmetics.equipped[item.kind] = cosmeticId
		end
	end)
	return true
end

local function giveDailyReward(player, data)
	local today = math.floor(os.time() / 86400)
	if data.lastDailyDay == today then
		return
	end
	if data.lastDailyDay == today - 1 then
		data.dailyStreak += 1
	else
		data.dailyStreak = 1
	end
	data.lastDailyDay = today
	local day = math.min(data.dailyStreak, Config.DailyStreakCap)
	local reward = math.floor(Config.DailyRewardBase * day * Config.SellMultiplier(data.rebirths))
	data.coins += reward
	data.totalEarned += reward
	task.spawn(function()
		if DataService.WaitFor(player) then
			notify(player, string.format("Daily reward (day %d streak): +%s coins! Come back tomorrow for more.", data.dailyStreak, Format.Number(reward)), "coins")
		end
	end)
end

local actions = {
	SellAll = function(player)
		return EconomyService.SellAll(player, false)
	end,
	SellFish = EconomyService.SellFish,
	ToggleFavorite = EconomyService.ToggleFavorite,
	EquipBait = EconomyService.EquipBait,
	BuyBait = EconomyService.BuyBait,
	CraftBait = EconomyService.CraftBait,
	ClaimBounty = EconomyService.ClaimBounty,
	BuyRod = EconomyService.BuyRod,
	EquipRod = EconomyService.EquipRod,
	UnlockZone = EconomyService.UnlockZone,
	Teleport = EconomyService.Teleport,
	Rebirth = EconomyService.Rebirth,
	EquipCosmetic = EconomyService.EquipCosmetic,
}

function EconomyService.Start()
	DataService.OnLoaded(function(player, data)
		giveDailyReward(player, data)
		refreshBounties(player, data)
	end)

	-- New bounties at midnight UTC for players who are online
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				local data = DataService.Get(player)
				if data and data.bounties.day ~= Bounties.Today(os.time()) then
					DataService.Update(player, function(saved)
						refreshBounties(player, saved)
					end)
				end
			end
		end
	end)

	Remotes.Action.OnServerInvoke = function(player, actionName, argument)
		local action = actions[actionName]
		if type(actionName) ~= "string" or not action then
			return false, "Unknown action"
		end
		if argument ~= nil and type(argument) ~= "string" then
			return false, "Bad request"
		end
		local ok, success, message = pcall(action, player, argument)
		if not ok then
			warn("[EconomyService] " .. actionName .. " failed: " .. tostring(success))
			return false, "Something went wrong"
		end
		return success, message
	end
end

return EconomyService
