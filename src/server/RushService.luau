-- Treasure Rush: every 15 minutes a big glowing dig site pops up in Dig Town.
-- Everyone digs it with the normal dig minigame, and every good dig fills the
-- site a bit. When it is full, every helper gets a guaranteed Rare or better
-- find from the best zone they have unlocked (Epic or better when 3 or more
-- players helped). Nobody shares a find, so helping never costs anything.
--
-- Players' screens follow the rush through attributes on ReplicatedStorage:
--   RushActive (bool), RushProgress, RushTarget, RushHelpers, RushEndsAt (server time)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Finds = require(Shared.Finds)
local Events = require(Shared.Events)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local RushService = {}

local DEFAULT_SITE = Vector3.new(20, 3, 8) -- used when the map has no RushSite part
local GOLD = Color3.fromRGB(255, 200, 60)

local rush = nil -- the rush going on right now, if any
local giveLoot = nil -- function(player, minRarityOrder), set in Start

local function notifyAll(text, kind)
	for _, player in ipairs(Players:GetPlayers()) do
		Remotes.Notify:FireClient(player, text, kind)
	end
end

local function sitePosition()
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("RushSite") then
			return item.Position
		end
	end
	return DEFAULT_SITE
end

local function publish()
	ReplicatedStorage:SetAttribute("RushActive", rush ~= nil)
	ReplicatedStorage:SetAttribute("RushProgress", rush and rush.progress or 0)
	ReplicatedStorage:SetAttribute("RushTarget", rush and rush.target or 0)
	ReplicatedStorage:SetAttribute("RushHelpers", rush and rush.helperCount or 0)
	ReplicatedStorage:SetAttribute("RushEndsAt", rush and rush.endsAt or 0)
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		if key ~= "Parent" then
			p[key] = value
		end
	end
	p.Parent = props.Parent
	return p
end

-- A mound of dirt with a half-buried chest, a beam of light and a sign that
-- shows how much is dug
local function buildSite(at)
	local model = Instance.new("Model")
	model.Name = "TreasureRush"

	local mound = part({
		Name = "RushMound",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, 12, 12),
		CFrame = CFrame.new(at.X, at.Y + 0.2, at.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Ground,
		Color = Color3.fromRGB(120, 85, 50),
		CanCollide = false,
		Parent = model,
	})
	-- The mound is the dig spot: DigService and the players' screens look for this
	mound:SetAttribute("DigSpot", "rush")
	mound:SetAttribute("TreasureRush", true)

	local chest = part({ Name = "Chest", Size = Vector3.new(5, 2.6, 3.4), CFrame = CFrame.new(at.X, at.Y + 1.1, at.Z) * CFrame.Angles(math.rad(-12), math.rad(20), 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(130, 80, 40), Parent = model })
	part({ Name = "ChestLid", Size = Vector3.new(5.1, 0.9, 3.5), CFrame = chest.CFrame * CFrame.new(0, 1.7, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 95, 50), Parent = model })
	for _, x in ipairs({ -1.8, 1.8 }) do
		part({ Name = "ChestBand", Size = Vector3.new(0.4, 3.6, 3.6), CFrame = chest.CFrame * CFrame.new(x, 0.45, 0), Material = Enum.Material.Metal, Color = GOLD, CanCollide = false, Parent = model })
	end

	local beam = part({
		Name = "RushBeam",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(120, 3, 3),
		CFrame = CFrame.new(at.X, at.Y + 60, at.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Neon,
		Color = GOLD,
		Transparency = 0.55,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Parent = model,
	})

	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 22
	light.Brightness = 2
	light.Parent = chest

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkle"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(GOLD)
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(1, 1.8)
	sparkles.Speed = NumberRange.new(3, 7)
	sparkles.SpreadAngle = Vector2.new(70, 70)
	sparkles.EmissionDirection = Enum.NormalId.Right -- the mound lies on its side, so +X points up
	sparkles.Rate = 25
	sparkles.Parent = mound

	local dirt = Instance.new("ParticleEmitter")
	dirt.Name = "Dirt"
	dirt.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dirt.Color = ColorSequence.new(Color3.fromRGB(120, 85, 55))
	dirt.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2) })
	dirt.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	dirt.Lifetime = NumberRange.new(0.5, 0.9)
	dirt.Speed = NumberRange.new(8, 14)
	dirt.SpreadAngle = Vector2.new(40, 40)
	dirt.Acceleration = Vector3.new(0, -35, 0)
	dirt.EmissionDirection = Enum.NormalId.Right
	dirt.Rate = 0
	dirt.Parent = mound

	-- The sign floats over the chest and can be seen from across town
	local signHolder = part({ Name = "RushSign", Size = Vector3.new(1, 1, 1), Position = at + Vector3.new(0, 9, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = model })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 92)
	gui.LightInfluence = 0
	gui.MaxDistance = 400
	gui.Parent = signHolder
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 34)
	title.BackgroundTransparency = 1
	title.Text = "TREASURE RUSH!"
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = GOLD
	title.TextStrokeTransparency = 0.2
	title.Parent = gui
	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.fromOffset(10, 40)
	barBack.Size = UDim2.new(1, -20, 0, 20)
	barBack.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
	barBack.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = barBack
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = GOLD
	fill.Parent = barBack
	corner:Clone().Parent = fill
	local info = Instance.new("TextLabel")
	info.Position = UDim2.fromOffset(0, 64)
	info.Size = UDim2.new(1, 0, 0, 26)
	info.BackgroundTransparency = 1
	info.TextScaled = true
	info.Font = Enum.Font.GothamBold
	info.TextColor3 = Color3.new(1, 1, 1)
	info.TextStrokeTransparency = 0.2
	info.Parent = gui

	model.PrimaryPart = mound
	model.Parent = Workspace
	return {
		model = model,
		mound = mound,
		chest = chest,
		beam = beam,
		fill = fill,
		info = info,
		title = title,
	}
end

local function refreshSign()
	if not rush then
		return
	end
	local site = rush.site
	site.fill.Size = UDim2.fromScale(math.clamp(rush.progress / rush.target, 0, 1), 1)
	local left = math.max(0, rush.endsAt - Events.Now())
	site.info.Text = string.format("%d/%d dug  -  %s left", rush.progress, rush.target, Format.Duration(left))
end

-- Ends the rush: loot for every helper if it was dug out, otherwise it sinks
local function finish(succeeded)
	local current = rush
	if not current then
		return
	end
	rush = nil
	publish()

	-- Nobody can start a new dig here while the site goes away
	local site = current.site
	site.mound:SetAttribute("DigSpot", nil)
	site.mound:SetAttribute("TreasureRush", nil)
	if succeeded then
		local helpers = {}
		for player in pairs(current.helpers) do
			if player.Parent then
				table.insert(helpers, player)
			end
		end
		local team = #helpers >= Config.RushTeamSize
		local minOrder = team and Finds.RarityById.Epic.order or Finds.RarityById.Rare.order
		notifyAll(string.format("The Treasure Rush is dug out! %d digger%s got %s finds.", #helpers, #helpers == 1 and "" or "s", team and "Epic or better" or "Rare or better"), "rare")
		for _, player in ipairs(helpers) do
			task.spawn(giveLoot, player, minOrder)
		end
		-- The lid flies open and the chest bursts with sparkles
		site.title.Text = "DUG OUT!"
		site.info.Text = string.format("%d digger%s shared the loot", #helpers, #helpers == 1 and "" or "s")
		site.fill.Size = UDim2.fromScale(1, 1)
		local lid = site.model:FindFirstChild("ChestLid")
		if lid then
			lid.CFrame = lid.CFrame * CFrame.new(0, 1, -1.6) * CFrame.Angles(math.rad(-70), 0, 0)
		end
		local burst = site.mound:FindFirstChild("Sparkle")
		if burst then
			burst.Rate = 0
			burst:Emit(120)
		end
		task.delay(6, function()
			site.model:Destroy()
		end)
	else
		notifyAll("The Treasure Rush sank back into the ground. Next time!", "info")
		site.title.Text = "IT SANK..."
		site.beam.Transparency = 0.9
		task.delay(3, function()
			site.model:Destroy()
		end)
	end
end

function RushService.Begin()
	if rush then
		return
	end
	local players = #Players:GetPlayers()
	if players == 0 then
		return
	end
	local at = sitePosition()
	rush = {
		site = buildSite(at),
		progress = 0,
		target = math.min(Config.RushDigsMax, Config.RushDigs + Config.RushDigsPerPlayer * (players - 1)),
		helpers = {}, -- [player] = good digs
		helperCount = 0,
		endsAt = Events.Now() + Config.RushSeconds,
	}
	publish()
	refreshSign()
	notifyAll("TREASURE RUSH in Dig Town! Dig it out together for a guaranteed great find.", "rare")

	local mine = rush
	task.spawn(function()
		while rush == mine do
			if Events.Now() >= mine.endsAt then
				finish(false)
				break
			end
			refreshSign()
			task.wait(1)
		end
	end)
end

function RushService.IsSite(spot)
	return rush ~= nil and spot == rush.site.mound
end

-- A player finished a good dig at the site. Returns the progress and target,
-- or nil if the rush is already over.
function RushService.AddDig(player)
	if not rush then
		return nil
	end
	if not rush.helpers[player] then
		rush.helpers[player] = 0
		rush.helperCount += 1
	end
	rush.helpers[player] += 1
	rush.progress += 1
	local progress, target = rush.progress, rush.target
	local dirt = rush.site.mound:FindFirstChild("Dirt")
	if dirt then
		dirt:Emit(16)
	end
	publish()
	refreshSign()
	if progress >= target then
		finish(true)
	end
	return progress, target
end

-- loot(player, minRarityOrder) gives one helper their find
function RushService.Start(loot)
	giveLoot = loot
	publish()
	task.spawn(function()
		task.wait(Config.RushFirstSeconds)
		while true do
			RushService.Begin()
			task.wait(Config.RushEverySeconds)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if rush and rush.helpers[player] then
			rush.helpers[player] = nil
			rush.helperCount -= 1
			publish()
		end
	end)
end

return RushService
