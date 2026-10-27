-- Dig spots, digging down and finds. The server decides what is buried and
-- checks the timing, so players can't pick their own finds. The dig minigame
-- runs on the player's screen using the shared Dig rules.
--
-- A dig goes: digging down -> minigame -> result
--   walking away while digging = "walked": nothing found, the spot stays
--   too many misses            = "cracked": the find breaks (the charm is used up)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Finds = require(Shared.Finds)
local Shovels = require(Shared.Shovels)
local Zones = require(Shared.Zones)
local Events = require(Shared.Events)
local Charms = require(Shared.Charms)
local Dig = require(Shared.Dig)
local FindModel = require(Shared.FindModel)
local Level = require(Shared.Level)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)
local EconomyService = require(script.Parent.EconomyService)
local CosmeticService = require(script.Parent.CosmeticService)
local TutorialService = require(script.Parent.TutorialService)

local DigService = {}

local SHOVEL_NAME = "Shovel"
local WANDER_LIMIT = 6 -- studs a player may drift from where they started digging
local SHOVEL_LENGTH = 5
-- How far the shovel leans while held. If it points the wrong way in Studio,
-- flip the sign (e.g. to 35).
local SHOVEL_TILT = -35

local random = Random.new()
local digs = {} -- [player] = current dig
local lastDig = {} -- [player] = os.clock()
local spotCooldowns = {} -- [player] = { [spot] = os.clock() when it can be dug again }
local nextDigId = 0

local function isDigSpot(spot)
	return typeof(spot) == "Instance" and spot:IsA("BasePart") and spot:IsDescendantOf(Workspace) and spot:GetAttribute("DigSpot") ~= nil
end

local function shovelTool(player)
	local character = player.Character
	return character and character:FindFirstChild(SHOVEL_NAME)
end

local function gripFor(lean)
	return CFrame.new(0, SHOVEL_LENGTH / 2 - 0.6, 0) * CFrame.Angles(math.rad(SHOVEL_TILT + lean), 0, 0)
end

-- A puff of dirt from the spot, seen by everyone
local function dirtBurst(spot, count)
	local emitter = spot:FindFirstChild("Dirt")
	if not emitter then
		emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Dirt"
		emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(120, 85, 55))
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.6) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(8, 14)
		emitter.SpreadAngle = Vector2.new(35, 35)
		emitter.Acceleration = Vector3.new(0, -35, 0)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Rate = 0
		emitter.Parent = spot
	end
	emitter:Emit(count)
end

local function clearDig(player)
	local dig = digs[player]
	digs[player] = nil
	local tool = shovelTool(player)
	if tool then
		tool.Grip = gripFor(0)
	end
	return dig
end

-- The charm used for this dig (falls back to no charm when you run out)
local function currentCharm(data)
	local charm = Charms.ById[data.charms.equipped]
	if not charm or (not charm.free and (data.charms.owned[charm.id] or 0) <= 0) then
		return Charms.ById[Charms.Default]
	end
	return charm
end

-- Pick what is buried, using shovel luck, the charm, weather and the weekly event
local function rollFind(data, zoneId, charm)
	local shovel = Shovels.ById[data.equippedShovel] or Shovels.ById[Shovels.Default]
	local weather = Events.GetWeather()
	local eventFind = Events.GetEventFind()

	local byRarity = {}
	for _, find in ipairs(Finds.ByZone[zoneId] or {}) do
		byRarity[find.rarity] = byRarity[find.rarity] or {}
		table.insert(byRarity[find.rarity], find)
	end

	local choices = {}
	local total = 0
	for _, rarity in ipairs(Finds.Rarities) do
		if byRarity[rarity.id] then
			local weight = rarity.weight
			if rarity.order >= 3 then
				weight *= shovel.luck * (weather.luckMultiplier or 1) * (charm.luck or 1)
			end
			if rarity.order >= 5 then
				weight *= (weather.legendaryMultiplier or 1) * (charm.legendary or 1)
			end
			total += weight
			table.insert(choices, { rarity = rarity, weight = weight })
		end
	end

	local pick = random:NextNumber(0, total)
	local chosen = choices[1].rarity
	for _, choice in ipairs(choices) do
		pick -= choice.weight
		if pick <= 0 then
			chosen = choice.rarity
			break
		end
	end

	local find
	if chosen.id == "Legendary" and eventFind and eventFind.zone == zoneId and random:NextNumber() < 0.5 then
		find = eventFind
	else
		local pool = byRarity[chosen.id]
		find = pool[random:NextInteger(1, #pool)]
	end

	-- Heavier finds are rarer and worth more
	local roll = random:NextNumber() ^ 1.6
	local weight = find.weight[1] + (find.weight[2] - find.weight[1]) * roll
	local shinyChance = Config.ShinyChance * (weather.shinyMultiplier or 1) * (charm.shiny or 1)
	local shiny = random:NextNumber() < shinyChance
	local value = find.value * (0.75 + 0.5 * roll)
	if shiny then
		value *= Config.ShinyValueMultiplier
	end

	return {
		id = find.id,
		weight = math.floor(weight * 100 + 0.5) / 100,
		value = value,
		shiny = shiny,
	}
end

local function announce(player, find, found)
	local rarity = Finds.RarityById[find.rarity]
	if rarity.order < 5 then
		return
	end
	local text = string.format("%s dug up a %s%s %s!", player.DisplayName, found.shiny and "Shiny " or "", find.rarity, find.name)
	for _, other in ipairs(Players:GetPlayers()) do
		Remotes.Notify:FireClient(other, text, "rare")
	end
end

local function coolSpot(player, spot)
	spotCooldowns[player] = spotCooldowns[player] or {}
	spotCooldowns[player][spot] = os.clock() + Config.SpotCooldown
end

-- Ends the dig without a find and tells the player why
local function lose(player, dig, reason)
	if digs[player] == dig then
		clearDig(player)
	end
	-- Once the find is rolled the spot is used up, however the dig ends. Otherwise
	-- players could put the shovel away to reroll a find they don't like.
	if dig.phase == "minigame" then
		coolSpot(player, dig.spot)
	end
	Remotes.DigResult:FireClient(player, dig.id, nil, reason)
end

local function onReady(player, dig)
	if digs[player] ~= dig or not player.Parent then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end

	-- The charm is used up now, whatever happens next
	local charm = dig.charm
	if not charm.free then
		DataService.Update(player, function(saved)
			local left = math.max(0, (saved.charms.owned[charm.id] or 0) - 1)
			saved.charms.owned[charm.id] = left
			if left == 0 and saved.charms.equipped == charm.id then
				saved.charms.equipped = Charms.Default
				Remotes.Notify:FireClient(player, "That was your last " .. charm.name .. ".", "info")
			end
		end)
	end

	local shovel = Shovels.ById[data.equippedShovel] or Shovels.ById[Shovels.Default]
	dig.find = rollFind(data, dig.zone, charm)
	dig.rarity = Finds.RarityById[Finds.ById[dig.find.id].rarity]
	dig.params = Dig.Params(dig.rarity, shovel)
	dig.phase = "minigame"
	dig.readyAt = os.clock()
	dirtBurst(dig.spot, 12)
	Remotes.DigReady:FireClient(player, dig.id, dig.params)

	task.delay(Dig.MaxSeconds + 5, function()
		if digs[player] == dig then
			lose(player, dig, "timeout")
		end
	end)
end

local function onStartDig(player, spot)
	if not isDigSpot(spot) then
		return nil
	end
	local data = DataService.Get(player)
	local runtime = DataService.GetRuntime(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not root or not humanoid or humanoid.Health <= 0 or not shovelTool(player) then
		return nil
	end
	if digs[player] then
		return nil
	end
	if lastDig[player] and os.clock() - lastDig[player] < Config.DigCooldown then
		return nil
	end

	if #data.bag >= runtime.bagSize then
		if ShopService.HasPass(player, "AutoSell") then
			EconomyService.SellAll(player, true)
		end
		data = DataService.Get(player)
		if #data.bag >= runtime.bagSize then
			Remotes.Notify:FireClient(player, "Your backpack is full! Sell finds at the Trading Post.", "warning")
			return nil
		end
	end

	-- A little extra range for internet lag
	local flat = Vector3.new(spot.Position.X - root.Position.X, 0, spot.Position.Z - root.Position.Z)
	if flat.Magnitude > Config.DigRange + 4 then
		Remotes.Notify:FireClient(player, "Get closer to the dig spot.", "warning")
		return nil
	end

	local zoneId = spot:GetAttribute("DigSpot")
	if not data.zones[zoneId] then
		local zone = Zones.ById[zoneId]
		Remotes.Notify:FireClient(player, "Unlock " .. (zone and zone.name or zoneId) .. " to dig here.", "warning")
		return nil
	end
	local readyAt = spotCooldowns[player] and spotCooldowns[player][spot]
	if readyAt and os.clock() < readyAt then
		Remotes.Notify:FireClient(player, "You already dug here. Try another spot!", "warning")
		return nil
	end

	lastDig[player] = os.clock()
	nextDigId += 1
	local charm = currentCharm(data)
	local dig = {
		id = nextDigId,
		origin = root.Position,
		zone = zoneId,
		spot = spot,
		phase = "digging",
		charm = charm,
	}
	digs[player] = dig

	local shovel = Shovels.ById[data.equippedShovel] or Shovels.ById[Shovels.Default]
	local weather = Events.GetWeather()
	local wait = random:NextNumber(Config.DigDownMin, Config.DigDownMax) * shovel.speed * (weather.digMultiplier or 1) * (charm.digSpeed or 1)
	TutorialService.Event(player, "Dig")

	-- The shovel goes up and down while digging, so everyone can see it
	task.spawn(function()
		local lean = 0
		while digs[player] == dig do
			lean = lean == 0 and 35 or 0
			local tool = shovelTool(player)
			if tool then
				tool.Grip = gripFor(lean)
			end
			if lean > 0 then
				dirtBurst(spot, 4)
			end
			task.wait(0.3)
		end
	end)
	task.delay(wait, onReady, player, dig)
	return dig.id
end

local function onDigDone(player, digId, outcome, perfects)
	local dig = digs[player]
	if not dig or dig.id ~= digId or dig.phase ~= "minigame" then
		return
	end
	if outcome ~= "found" then
		lose(player, dig, "cracked")
		return
	end
	-- Nobody can dig a find out faster than a perfect, non-stop tapper
	if os.clock() - dig.readyAt < Dig.MinSeconds(dig.params) * 0.9 then
		lose(player, dig, "cracked")
		return
	end
	clearDig(player)
	coolSpot(player, dig.spot)

	perfects = math.clamp(math.floor(tonumber(perfects) or 0), 0, dig.params.strikes)
	local find = Finds.ById[dig.find.id]
	local found = dig.find
	found.value = math.max(1, math.floor(found.value * Dig.ValueMultiplier(perfects, dig.params.strikes)))
	local levelBefore, levelAfter = 1, 1
	local isNew, isRecord = DataService.Update(player, function(data)
		found.uid = data.nextUid
		data.nextUid += 1
		table.insert(data.bag, found)
		data.totalFound += 1
		local entry = data.book[found.id]
		local firstTime = entry == nil
		if firstTime then
			entry = { count = 0, best = 0, shiny = 0 }
			data.book[found.id] = entry
		end
		local record = not firstTime and found.weight > entry.best
		entry.count += 1
		entry.best = math.max(entry.best, found.weight)
		if found.shiny then
			entry.shiny += 1
		end

		levelBefore = Level.FromXp(data.xp)
		data.xp += Level.XpForFind(found.id, firstTime)
		levelAfter = Level.FromXp(data.xp)
		for level = levelBefore + 1, levelAfter do
			data.coins += level * Level.CoinsPerLevel
		end
		return firstTime, record
	end)

	Remotes.DigResult:FireClient(player, digId, {
		id = found.id,
		weight = found.weight,
		value = found.value,
		shiny = found.shiny,
		perfects = perfects,
		strikes = dig.params.strikes,
		isNew = isNew,
		isRecord = isRecord,
		xp = Level.XpForFind(found.id, isNew),
	})
	if levelAfter > levelBefore then
		Remotes.Notify:FireClient(player, string.format("LEVEL UP! You're now a Lv %d digger. +%s coins", levelAfter, Format.Number(levelAfter * Level.CoinsPerLevel)), "rare")
	end
	DigService.ShowOff(player, found)
	TutorialService.Event(player, "Find")
	announce(player, find, found)

	local data = DataService.Get(player)
	local runtime = DataService.GetRuntime(player)
	if data and runtime and #data.bag >= runtime.bagSize and ShopService.HasPass(player, "AutoSell") then
		EconomyService.SellAll(player, true)
	end
end

-- The player holds the find up over their head for everyone to see
function DigService.ShowOff(player, found)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local model = head and FindModel.Build(found.id, found.weight, found.shiny)
	if not model then
		return
	end
	local size = FindModel.SizeFor(found.weight)
	local body = model.PrimaryPart
	model:PivotTo(head.CFrame * CFrame.new(0, 1.2 + size * 0.5, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = body
	weld.Parent = body
	model.Parent = character
	task.delay(2.5, function()
		model:Destroy()
	end)
end

-- Builds the shovel tool from the player's equipped shovel and shovel skin
local function buildShovel(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local shovel = Shovels.ById[data.equippedShovel] or Shovels.ById[Shovels.Default]

	local tool = Instance.new("Tool")
	tool.Name = SHOVEL_NAME
	tool.ToolTip = shovel.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, SHOVEL_LENGTH, 0.3)
	handle.CanCollide = false
	handle.Massless = true
	handle.Color = Color3.fromRGB(130, 90, 55)
	handle.Material = Enum.Material.Wood
	handle.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(1.3, 1.5, 0.2)
	blade.CanCollide = false
	blade.Massless = true
	blade.Color = shovel.color
	blade.Material = Enum.Material.Metal
	blade.CFrame = handle.CFrame * CFrame.new(0, -SHOVEL_LENGTH / 2 - 0.6, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = blade
	weld.Parent = blade
	blade.Parent = tool

	-- Hold the shovel near its top end, blade down
	tool.Grip = gripFor(0)

	CosmeticService.StyleShovel(player, blade)
	return tool
end

local function giveShovel(player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		return
	end
	local character = player.Character
	local wasEquipped = character and character:FindFirstChild(SHOVEL_NAME) ~= nil
	for _, container in ipairs({ backpack, character }) do
		local old = container and container:FindFirstChild(SHOVEL_NAME)
		if old then
			old:Destroy()
		end
	end
	local tool = buildShovel(player)
	if not tool then
		return
	end
	if wasEquipped and character then
		tool.Parent = character
	else
		tool.Parent = backpack
	end
end

function DigService.GiveShovel(player)
	clearDig(player)
	giveShovel(player)
end

function DigService.Start()
	-- Walking away from your hole stops digging
	task.spawn(function()
		while true do
			task.wait(0.3)
			for player, dig in pairs(digs) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not root or (root.Position - dig.origin).Magnitude > WANDER_LIMIT then
					lose(player, dig, "walked")
				end
			end
		end
	end)

	Remotes.StartDig.OnServerInvoke = function(player, spot)
		return onStartDig(player, spot)
	end
	Remotes.DigDone.OnServerEvent:Connect(onDigDone)
	Remotes.CancelDig.OnServerEvent:Connect(function(player)
		local dig = digs[player]
		if dig then
			lose(player, dig, "walked")
		end
	end)

	DataService.OnLoaded(function(player)
		player.CharacterAdded:Connect(function()
			local dig = digs[player]
			if dig then
				lose(player, dig, "walked")
			end
			task.defer(giveShovel, player)
		end)
		task.spawn(function()
			if DataService.WaitFor(player) and player.Character then
				giveShovel(player)
			end
		end)
	end)

	-- Rebuild the shovel when the player equips a new shovel or shovel skin
	local shovelLooks = {}
	DataService.OnChanged(function(player, data)
		local look = data.equippedShovel .. "|" .. tostring(data.cosmetics.equipped.shovelSkin)
		if shovelLooks[player] ~= nil and shovelLooks[player] ~= look then
			DigService.GiveShovel(player)
		end
		shovelLooks[player] = look
	end)

	Players.PlayerRemoving:Connect(function(player)
		clearDig(player)
		lastDig[player] = nil
		spotCooldowns[player] = nil
		shovelLooks[player] = nil
	end)
end

return DigService
