-- Casting, nibbles, bites, hooking and catches. The server decides which fish
-- bites and checks the timing, so players can't pick their own fish. The
-- reeling fight runs on the player's screen using the shared Fight rules.
--
-- A cast goes: waiting (with fake nibbles) -> bite (strike now!) -> fight -> result
--   strike during waiting  = "early": the fish is scared off (bait kept)
--   no strike in time      = "stolen": the fish ate the bait
--   fight lost             = "snapped" or "escaped"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Fish = require(Shared.Fish)
local Rods = require(Shared.Rods)
local Zones = require(Shared.Zones)
local Events = require(Shared.Events)
local Bait = require(Shared.Bait)
local Fight = require(Shared.Fight)
local FishModel = require(Shared.FishModel)
local Level = require(Shared.Level)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)
local EconomyService = require(script.Parent.EconomyService)
local CosmeticService = require(script.Parent.CosmeticService)
local TutorialService = require(script.Parent.TutorialService)

local FishingService = {}

local ROD_NAME = "Fishing Rod"
local WANDER_LIMIT = 8 -- studs a player may drift from where they cast
local HOTSPOT_RADIUS = 12
local HOTSPOT_BITE = 0.65 -- bites come this much sooner at a bubbling hotspot

local random = Random.new()
local casts = {} -- [player] = current cast
local lastCast = {} -- [player] = os.clock()
local nextCastId = 0

local function fishingZoneParts()
	local result = {}
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("FishingZone") then
			table.insert(result, item)
		end
	end
	return result
end

local zoneParts = {}
local hotspots = {}

local function nearHotspot(position)
	for _, spot in ipairs(hotspots) do
		local flat = Vector3.new(spot.Position.X - position.X, 0, spot.Position.Z - position.Z)
		if flat.Magnitude <= HOTSPOT_RADIUS then
			return true
		end
	end
	return false
end

local function zoneAt(position)
	for _, zonePart in ipairs(zoneParts) do
		local relative = zonePart.CFrame:PointToObjectSpace(position)
		local half = zonePart.Size / 2
		if math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z and math.abs(relative.Y) <= half.Y + 3 then
			return zonePart:GetAttribute("FishingZone")
		end
	end
	return nil
end

-- True if there is land (an island, a bridge...) at this spot instead of water
local function isOverLand(position, character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = table.clone(zoneParts)
	table.insert(ignore, character)
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	local hit = Workspace:Raycast(position + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), params)
	return hit ~= nil and hit.Instance ~= Workspace.Terrain and hit.Position.Y > position.Y + 0.5
end

local function rodTip(player)
	local character = player.Character
	local tool = character and character:FindFirstChild(ROD_NAME)
	local handle = tool and tool:FindFirstChild("Handle")
	return handle and handle:FindFirstChild("Tip")
end

local function clearCast(player)
	local cast = casts[player]
	casts[player] = nil
	if cast and cast.bobber then
		cast.bobber:Destroy()
	end
end

local function makeBobber(player, position)
	local bobber = Instance.new("Part")
	bobber.Name = player.Name .. "Bobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.8, 0.8, 0.8)
	bobber.Color = Color3.fromRGB(255, 60, 60)
	bobber.Material = Enum.Material.SmoothPlastic
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.Position = position
	local attachment = Instance.new("Attachment")
	attachment.Parent = bobber

	-- The fishing line is a Beam: it only draws a line, so it can't pull the player
	local tip = rodTip(player)
	if tip then
		local line = Instance.new("Beam")
		line.Attachment0 = tip
		line.Attachment1 = attachment
		line.Width0 = 0.06
		line.Width1 = 0.06
		line.FaceCamera = true
		line.CurveSize0 = -2
		line.Segments = 12
		line.Color = ColorSequence.new(Color3.new(1, 1, 1))
		line.Transparency = NumberSequence.new(0.2)
		line.Parent = bobber
	end
	CosmeticService.DecorateBobber(player, bobber)
	bobber.Parent = Workspace
	return bobber
end

-- The bait on the hook for this cast (falls back to bread when you run out)
local function currentBait(data)
	local bait = Bait.ById[data.bait.equipped]
	if not bait or (not bait.free and (data.bait.owned[bait.id] or 0) <= 0) then
		return Bait.ById[Bait.Default]
	end
	return bait
end

-- Pick which fish bites, using rod luck, bait, weather and the weekly event
local function rollFish(data, zoneId, bait)
	local rod = Rods.ById[data.equippedRod] or Rods.ById[Rods.Default]
	local weather = Events.GetWeather()
	local eventFish = Events.GetEventFish()

	local byRarity = {}
	for _, fish in ipairs(Fish.ByZone[zoneId] or {}) do
		byRarity[fish.rarity] = byRarity[fish.rarity] or {}
		table.insert(byRarity[fish.rarity], fish)
	end

	local choices = {}
	local total = 0
	for _, rarity in ipairs(Fish.Rarities) do
		if byRarity[rarity.id] then
			local weight = rarity.weight
			if rarity.order >= 3 then
				weight *= rod.luck * (weather.luckMultiplier or 1) * (bait.luck or 1)
			end
			if rarity.order >= 5 then
				weight *= (weather.legendaryMultiplier or 1) * (bait.legendary or 1)
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

	local fish
	if chosen.id == "Legendary" and eventFish.zone == zoneId and random:NextNumber() < 0.5 then
		fish = eventFish
	else
		local pool = byRarity[chosen.id]
		fish = pool[random:NextInteger(1, #pool)]
	end

	-- Heavier fish are rarer and worth more
	local roll = random:NextNumber() ^ 1.6
	local weight = fish.weight[1] + (fish.weight[2] - fish.weight[1]) * roll
	local shinyChance = Config.ShinyChance * (weather.shinyMultiplier or 1) * (bait.shiny or 1)
	local shiny = random:NextNumber() < shinyChance
	local value = fish.value * (0.75 + 0.5 * roll)
	if shiny then
		value *= Config.ShinyValueMultiplier
	end

	return {
		id = fish.id,
		weight = math.floor(weight * 10 + 0.5) / 10,
		value = math.max(1, math.floor(value)),
		shiny = shiny,
	}
end

local function announce(player, fish, caught)
	local rarity = Fish.RarityById[fish.rarity]
	if rarity.order < 5 then
		return
	end
	local text = string.format("%s caught a %s%s %s!", player.DisplayName, caught.shiny and "Shiny " or "", fish.rarity, fish.name)
	for _, other in ipairs(Players:GetPlayers()) do
		Remotes.Notify:FireClient(other, text, "rare")
	end
end

-- Ends the cast without a catch and tells the player why
local function lose(player, cast, reason)
	if casts[player] == cast then
		clearCast(player)
	end
	Remotes.CatchResult:FireClient(player, cast.id, nil, reason)
end

local function dipBobber(cast, depth, seconds)
	local bobber = cast.bobber
	if not bobber or not bobber.Parent then
		return
	end
	local home = cast.surface
	local down = TweenService:Create(bobber, TweenInfo.new(seconds / 2), { Position = home - Vector3.new(0, depth, 0) })
	down:Play()
	task.delay(seconds / 2, function()
		if bobber.Parent and cast.phase == "waiting" then
			TweenService:Create(bobber, TweenInfo.new(seconds / 2), { Position = home }):Play()
		end
	end)
end

local function onBite(player, cast)
	if casts[player] ~= cast or not player.Parent then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end

	-- The fish takes the bait now, whatever happens next
	local bait = cast.bait
	if not bait.free then
		DataService.Update(player, function(saved)
			local left = math.max(0, (saved.bait.owned[bait.id] or 0) - 1)
			saved.bait.owned[bait.id] = left
			if left == 0 and saved.bait.equipped == bait.id then
				saved.bait.equipped = Bait.Default
				Remotes.Notify:FireClient(player, "That was your last " .. bait.name .. ". Back to Bread.", "info")
			end
		end)
	end

	cast.catch = rollFish(data, cast.zone, bait)
	cast.rarity = Fish.RarityById[Fish.ById[cast.catch.id].rarity]
	cast.phase = "bite"
	cast.biteAt = os.clock()
	if cast.bobber then
		cast.bobber.Position = cast.surface - Vector3.new(0, 1.2, 0)
		cast.bobber.Color = Color3.fromRGB(255, 220, 0)
	end
	Remotes.Bite:FireClient(player, cast.id, { window = cast.rarity.hookWindow })

	task.delay(cast.rarity.hookWindow + Config.HookGrace, function()
		if casts[player] == cast and cast.phase == "bite" then
			lose(player, cast, "stolen")
		end
	end)
end

local function onCast(player, target)
	if typeof(target) ~= "Vector3" then
		return nil
	end
	local data = DataService.Get(player)
	local runtime = DataService.GetRuntime(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not root or not humanoid or humanoid.Health <= 0 or not character:FindFirstChild(ROD_NAME) then
		return nil
	end
	if casts[player] then
		return nil
	end
	if lastCast[player] and os.clock() - lastCast[player] < Config.CastCooldown then
		return nil
	end

	if #data.bag >= runtime.bagSize then
		if ShopService.HasPass(player, "AutoSell") then
			EconomyService.SellAll(player, true)
		end
		data = DataService.Get(player)
		if #data.bag >= runtime.bagSize then
			Remotes.Notify:FireClient(player, "Your bag is full! Sell fish at the Fish Market.", "warning")
			return nil
		end
	end

	local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
	if flat.Magnitude > Config.MaxCastDistance then
		Remotes.Notify:FireClient(player, "That's too far. Get closer to the water.", "warning")
		return nil
	end

	local zoneId = zoneAt(target)
	if not zoneId or isOverLand(target, character) then
		Remotes.Notify:FireClient(player, "Cast into the water to fish.", "warning")
		return nil
	end
	if not data.zones[zoneId] then
		local zone = Zones.ById[zoneId]
		Remotes.Notify:FireClient(player, "Unlock " .. (zone and zone.name or zoneId) .. " to fish here.", "warning")
		return nil
	end

	lastCast[player] = os.clock()
	nextCastId += 1
	local surface = Vector3.new(target.X, 0.3, target.Z)
	local bait = currentBait(data)
	local cast = {
		id = nextCastId,
		origin = root.Position,
		zone = zoneId,
		phase = "waiting",
		surface = surface,
		bait = bait,
		bobber = makeBobber(player, surface),
	}
	casts[player] = cast

	local rod = Rods.ById[data.equippedRod] or Rods.ById[Rods.Default]
	local weather = Events.GetWeather()
	local wait = random:NextNumber(Config.BiteWaitMin, Config.BiteWaitMax) * rod.speed * (weather.biteMultiplier or 1) * (bait.biteSpeed or 1)
	if nearHotspot(target) then
		wait *= HOTSPOT_BITE
	end
	TutorialService.Event(player, "Cast")

	-- Fake nibbles to tempt an early strike
	local nibbles = random:NextInteger(0, Config.NibblesMax)
	for _ = 1, nibbles do
		local at = random:NextNumber(0.8, math.max(0.9, wait - 0.7))
		task.delay(at, function()
			if casts[player] == cast and cast.phase == "waiting" then
				dipBobber(cast, 0.35, 0.4)
				Remotes.Nibble:FireClient(player, cast.id)
			end
		end)
	end
	task.delay(wait, onBite, player, cast)
	return cast.id
end

local function onHook(player, castId)
	local cast = casts[player]
	if not cast or cast.id ~= castId then
		return
	end
	if cast.phase == "waiting" then
		lose(player, cast, "early")
		return
	end
	if cast.phase ~= "bite" then
		return
	end
	if os.clock() - cast.biteAt > cast.rarity.hookWindow + Config.HookGrace then
		lose(player, cast, "stolen")
		return
	end

	local data = DataService.Get(player)
	local rod = data and Rods.ById[data.equippedRod] or Rods.ById[Rods.Default]
	cast.phase = "fight"
	cast.fightParams = Fight.Params(cast.rarity, rod)
	cast.hookAt = os.clock()
	Remotes.Fight:FireClient(player, cast.id, cast.fightParams)

	task.delay(Fight.MaxSeconds + 5, function()
		if casts[player] == cast then
			lose(player, cast, "escaped")
		end
	end)
end

local function onReel(player, castId, outcome)
	local cast = casts[player]
	if not cast or cast.id ~= castId or cast.phase ~= "fight" then
		return
	end
	if outcome ~= "caught" then
		lose(player, cast, outcome == "snapped" and "snapped" or "escaped")
		return
	end
	-- Nobody can land a fish faster than a perfect, non-stop reel
	if os.clock() - cast.hookAt < Fight.MinSeconds(cast.fightParams) * 0.9 then
		lose(player, cast, "escaped")
		return
	end
	clearCast(player)

	local fish = Fish.ById[cast.catch.id]
	local caught = cast.catch
	local levelBefore, levelAfter = 1, 1
	local isNew, isRecord = DataService.Update(player, function(data)
		caught.uid = data.nextUid
		data.nextUid += 1
		table.insert(data.bag, caught)
		data.totalCaught += 1
		local entry = data.book[caught.id]
		local firstTime = entry == nil
		if firstTime then
			entry = { count = 0, best = 0, shiny = 0 }
			data.book[caught.id] = entry
		end
		local record = not firstTime and caught.weight > entry.best
		entry.count += 1
		entry.best = math.max(entry.best, caught.weight)
		if caught.shiny then
			entry.shiny += 1
		end

		levelBefore = Level.FromXp(data.xp)
		data.xp += Level.XpForCatch(caught.id, firstTime)
		levelAfter = Level.FromXp(data.xp)
		for level = levelBefore + 1, levelAfter do
			data.coins += level * Level.CoinsPerLevel
		end
		return firstTime, record
	end)

	Remotes.CatchResult:FireClient(player, castId, {
		id = caught.id,
		weight = caught.weight,
		value = caught.value,
		shiny = caught.shiny,
		isNew = isNew,
		isRecord = isRecord,
		xp = Level.XpForCatch(caught.id, isNew),
	})
	if levelAfter > levelBefore then
		Remotes.Notify:FireClient(player, string.format("LEVEL UP! You're now an Lv %d angler. +%s coins", levelAfter, Format.Number(levelAfter * Level.CoinsPerLevel)), "rare")
	end
	FishingService.ShowOff(player, caught)
	TutorialService.Event(player, "Catch")
	announce(player, fish, caught)

	local data = DataService.Get(player)
	local runtime = DataService.GetRuntime(player)
	if data and runtime and #data.bag >= runtime.bagSize and ShopService.HasPass(player, "AutoSell") then
		EconomyService.SellAll(player, true)
	end
end

-- The player holds the fish up over their head for everyone to see
function FishingService.ShowOff(player, caught)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local model = head and FishModel.Build(caught.id, caught.weight, caught.shiny)
	if not model then
		return
	end
	local length = FishModel.LengthFor(caught.weight)
	local body = model.PrimaryPart
	model:PivotTo(head.CFrame * CFrame.new(0, 1.2 + length * 0.25, 0) * CFrame.Angles(0, math.rad(90), 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = body
	weld.Parent = body
	model.Parent = character
	task.delay(2.5, function()
		model:Destroy()
	end)
end

-- Builds the rod tool from the player's equipped rod and rod skin
local function buildRod(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local rod = Rods.ById[data.equippedRod] or Rods.ById[Rods.Default]

	local tool = Instance.new("Tool")
	tool.Name = ROD_NAME
	tool.ToolTip = rod.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local length = 7
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.25, length, 0.25)
	handle.CanCollide = false
	handle.Massless = true
	handle.Color = rod.color
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool

	local tip = Instance.new("Attachment")
	tip.Name = "Tip"
	tip.Position = Vector3.new(0, length / 2, 0)
	tip.Parent = handle

	-- Hold the rod near its bottom end, tilted forward.
	-- If the rod ever points the wrong way, change ROD_TILT (e.g. to -50).
	local ROD_TILT = 50
	tool.Grip = CFrame.new(0, -length / 2 + 0.6, 0) * CFrame.Angles(math.rad(ROD_TILT), 0, 0)

	CosmeticService.StyleRod(player, handle)
	return tool
end

local function giveRod(player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		return
	end
	local character = player.Character
	local wasEquipped = character and character:FindFirstChild(ROD_NAME) ~= nil
	for _, container in ipairs({ backpack, character }) do
		local old = container and container:FindFirstChild(ROD_NAME)
		if old then
			old:Destroy()
		end
	end
	local tool = buildRod(player)
	if not tool then
		return
	end
	if wasEquipped and character then
		tool.Parent = character
	else
		tool.Parent = backpack
	end
end

function FishingService.GiveRod(player)
	clearCast(player)
	giveRod(player)
end

function FishingService.Start()
	zoneParts = fishingZoneParts()
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("Hotspot") then
			table.insert(hotspots, item)
		end
	end
	Workspace.DescendantAdded:Connect(function(item)
		if item:IsA("BasePart") and item:GetAttribute("FishingZone") then
			table.insert(zoneParts, item)
		elseif item:IsA("BasePart") and item:GetAttribute("Hotspot") then
			table.insert(hotspots, item)
		end
	end)

	-- Walking away from your line reels it in
	task.spawn(function()
		while true do
			task.wait(0.3)
			for player, cast in pairs(casts) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not root or (root.Position - cast.origin).Magnitude > WANDER_LIMIT then
					lose(player, cast, "walked")
				end
			end
		end
	end)

	Remotes.Cast.OnServerInvoke = function(player, target)
		return onCast(player, target)
	end
	Remotes.Hook.OnServerEvent:Connect(onHook)
	Remotes.Reel.OnServerEvent:Connect(onReel)
	Remotes.CancelCast.OnServerEvent:Connect(function(player)
		clearCast(player)
	end)

	DataService.OnLoaded(function(player)
		player.CharacterAdded:Connect(function()
			clearCast(player)
			task.defer(giveRod, player)
		end)
		task.spawn(function()
			if DataService.WaitFor(player) and player.Character then
				giveRod(player)
			end
		end)
	end)

	-- Rebuild the rod when the player equips a new rod or rod skin
	local rodLooks = {}
	DataService.OnChanged(function(player, data)
		local look = data.equippedRod .. "|" .. tostring(data.cosmetics.equipped.rodSkin)
		if rodLooks[player] ~= nil and rodLooks[player] ~= look then
			FishingService.GiveRod(player)
		end
		rodLooks[player] = look
	end)

	Players.PlayerRemoving:Connect(function(player)
		clearCast(player)
		lastCast[player] = nil
		rodLooks[player] = nil
	end)
end

return FishingService
