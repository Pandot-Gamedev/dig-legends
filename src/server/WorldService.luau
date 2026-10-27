-- Connects the world to the game: shop and market prompts, zone gates,
-- the global leaderboard board and the weekly event board.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Zones = require(Shared.Zones)
local Events = require(Shared.Events)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local EconomyService = require(script.Parent.EconomyService)
local TutorialService = require(script.Parent.TutorialService)

local WorldService = {}

local LEADERBOARD_REFRESH = 120

local function hookPrompt(prompt)
	local holder = prompt.Parent
	if not holder then
		return
	end
	local station = holder:GetAttribute("Station")
	local gateZone = holder:GetAttribute("ZoneGate")
	local panels = { Sell = "Market", Rods = "Rods", Bait = "Bait", Bounties = "Bounties" }
	if station and panels[station] then
		prompt.Triggered:Connect(function(player)
			Remotes.OpenPanel:FireClient(player, panels[station])
			if station == "Bounties" then
				TutorialService.Event(player, "Bounties")
			end
		end)
	elseif gateZone then
		prompt.Triggered:Connect(function(player)
			local ok, message = EconomyService.UnlockZone(player, gateZone)
			if not ok and message then
				Remotes.Notify:FireClient(player, message, "warning")
			end
		end)
	end
end

local function makeBoardFace(boardPart, titleText, face)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = gui
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.16, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = Color3.fromRGB(255, 220, 120)
	title.Parent = gui
	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Position = UDim2.new(0, 0, 0.18, 0)
	body.Size = UDim2.new(1, 0, 0.8, 0)
	body.BackgroundTransparency = 1
	body.Text = "Loading..."
	body.TextScaled = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Font = Enum.Font.GothamMedium
	body.TextColor3 = Color3.new(1, 1, 1)
	body.Parent = gui
	gui.Parent = boardPart
	return body
end

-- Boards show the same text on both sides. Returns a function that sets the text.
local function makeBoardGui(boardPart, titleText)
	local front = makeBoardFace(boardPart, titleText, Enum.NormalId.Front)
	local back = makeBoardFace(boardPart, titleText, Enum.NormalId.Back)
	return function(text)
		front.Text = text
		back.Text = text
	end
end

local function findStation(name)
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("Station") == name then
			return item
		end
	end
	return nil
end

local nameCache = {}
local function nameFor(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = ok and name or ("Player " .. userId)
	return nameCache[userId]
end

local function runLeaderboard(boardPart)
	local setText = makeBoardGui(boardPart, "Most Fish Caught")
	local store = DataStoreService:GetOrderedDataStore(Config.LeaderboardStoreName)
	while true do
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, 10)
		end)
		if ok then
			local lines = {}
			for rank, entry in ipairs(pages:GetCurrentPage()) do
				table.insert(lines, string.format("%d. %s  -  %s", rank, nameFor(tonumber(entry.key)), Format.Number(entry.value)))
			end
			setText(#lines > 0 and table.concat(lines, "\n") or "No catches yet. Be the first!")
		else
			setText("Leaderboard unavailable right now.")
		end
		task.wait(LEADERBOARD_REFRESH)
	end
end

local function runEventBoard(boardPart)
	local setText = makeBoardGui(boardPart, "This Week's Legend")
	while true do
		local fish, weekLeft = Events.GetEventFish()
		local weather, weatherLeft = Events.GetWeather()
		local zone = Zones.ById[fish.zone]
		setText(string.format(
			"%s\nonly in %s\nends in %s\n\nWeather: %s\n%s\n(changes in %s)",
			fish.name,
			zone and zone.name or fish.zone,
			Format.Duration(weekLeft),
			weather.name,
			weather.description,
			Format.Duration(weatherLeft)
		))
		task.wait(1)
	end
end

function WorldService.Start()
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("ProximityPrompt") then
			hookPrompt(item)
		end
	end
	Workspace.DescendantAdded:Connect(function(item)
		if item:IsA("ProximityPrompt") then
			task.defer(hookPrompt, item)
		end
	end)

	local leaderboard = findStation("Leaderboard")
	if leaderboard then
		task.spawn(runLeaderboard, leaderboard)
	end
	local eventBoard = findStation("EventBoard")
	if eventBoard then
		task.spawn(runEventBoard, eventBoard)
	end
end

return WorldService
