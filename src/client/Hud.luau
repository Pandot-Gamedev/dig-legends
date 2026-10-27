-- Always-on screen info: coins, bag, the weekly event, and the menu buttons.

local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Zones = require(Shared.Zones)
local Events = require(Shared.Events)
local Bait = require(Shared.Bait)
local Level = require(Shared.Level)
local Format = require(Shared.Format)

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local Panels = require(script.Parent.Panels)
local CameraController = require(script.Parent.CameraController)
local T = UI.Theme

local Hud = {}

function Hud.Init(screenGui)
	-- Stats, top left
	local stats = UI.new("Frame", {
		Name = "Stats",
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(230, 160),
		BackgroundColor3 = T.Background,
		BackgroundTransparency = 0.15,
		Parent = screenGui,
	}, { UI.corner(12), UI.padding(10), UI.list(4) })
	local levelLine = UI.label("Lv 1 Angler", { Size = UDim2.new(1, 0, 0, 22), TextColor3 = Color3.fromRGB(150, 220, 255), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = stats })
	local xpBack = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = T.Card, LayoutOrder = 0, Parent = stats }, { UI.corner(3) })
	local xpFill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(150, 220, 255), Parent = xpBack }, { UI.corner(3) })
	levelLine.LayoutOrder = -2
	xpBack.LayoutOrder = -1
	local coins = UI.label("0 coins", { Size = UDim2.new(1, 0, 0, 30), TextColor3 = T.Gold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = stats })
	local bag = UI.label("Bag 0/20", { Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = stats })
	local baitLine = UI.label("Bait: Bread", { Size = UDim2.new(1, 0, 0, 18), Font = T.BodyFont, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3, Parent = stats })
	local bonus = UI.label("", { Size = UDim2.new(1, 0, 0, 18), Font = T.BodyFont, TextColor3 = T.Muted, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4, Parent = stats })

	local function update(data, runtime)
		local progress, level = Level.Progress(data.xp or 0)
		levelLine.Text = string.format("Lv %d Angler", level)
		xpFill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
		coins.Text = Format.Number(data.coins) .. " coins"
		local size = runtime.bagSize or Config.BagSize
		bag.Text = string.format("Bag %d/%d", #data.bag, size)
		bag.TextColor3 = #data.bag >= size and T.Bad or T.Text
		local bait = Bait.ById[data.bait.equipped] or Bait.ById[Bait.Default]
		baitLine.Text = bait.free and "Bait: Bread" or string.format("Bait: %s x%d", bait.name, data.bait.owned[bait.id] or 0)
		baitLine.TextColor3 = bait.color
		if data.rebirths > 0 then
			bonus.Text = string.format("Rebirth %d: +%d%% coins", data.rebirths, math.floor((Config.SellMultiplier(data.rebirths) - 1) * 100 + 0.5))
		else
			bonus.Text = "Sell fish at the Fish Market"
		end
	end
	State.Changed:Connect(update)
	if State.data then
		update(State.data, State.runtime)
	end

	-- Event and weather banner, top center
	local banner = UI.new("Frame", {
		Name = "EventBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(520, 52),
		BackgroundColor3 = T.Background,
		BackgroundTransparency = 0.15,
		Parent = screenGui,
	}, { UI.corner(12), UI.padding(6), UI.list(2) })
	local eventLine = UI.label("", { Size = UDim2.new(1, 0, 0, 20), TextColor3 = T.Gold, Parent = banner })
	local weatherLine = UI.label("", { Size = UDim2.new(1, 0, 0, 16), Font = T.BodyFont, TextColor3 = T.Muted, Parent = banner })
	task.spawn(function()
		while true do
			local fish, weekLeft = Events.GetEventFish()
			local zone = Zones.ById[fish.zone]
			eventLine.Text = string.format("Weekly legend: %s in %s (%s left)", fish.name, zone and zone.name or "", Format.Duration(weekLeft))
			local weather, weatherLeft = Events.GetWeather()
			weatherLine.Text = string.format("%s: %s (%s)", weather.name, weather.description, Format.Duration(weatherLeft))
			task.wait(1)
		end
	end)

	-- Menu buttons, left side, with keyboard shortcuts
	local menu = UI.new("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 30),
		Size = UDim2.fromOffset(130, 420),
		BackgroundTransparency = 1,
		Parent = screenGui,
	}, { UI.list(6) })
	local buttons = {
		{ "Bag", "Bag", Color3.fromRGB(90, 140, 220), Enum.KeyCode.Q },
		{ "Fish Book", "Book", Color3.fromRGB(80, 160, 255), Enum.KeyCode.B },
		{ "Bounties", "Bounties", Color3.fromRGB(200, 150, 70), Enum.KeyCode.N },
		{ "Rods", "Rods", Color3.fromRGB(230, 140, 60), Enum.KeyCode.R },
		{ "Shop", "Shop", Color3.fromRGB(70, 200, 110), Enum.KeyCode.P },
		{ "Travel", "Teleport", Color3.fromRGB(170, 100, 255), Enum.KeyCode.T },
		{ "Rebirth", "Rebirth", Color3.fromRGB(255, 90, 160), nil },
	}
	local shortcuts = {}
	for index, info in ipairs(buttons) do
		local keyName = info[4] and (" (" .. info[4].Name .. ")") or ""
		UI.button(info[1] .. keyName, info[3], function()
			Panels[info[2]].toggle()
		end, { Size = UDim2.fromOffset(130, 42), LayoutOrder = index, Parent = menu })
		if info[4] then
			shortcuts[info[4]] = info[2]
		end
	end
	if CameraController.IsActive() then
		UI.label("Alt: free the mouse", { Size = UDim2.fromOffset(130, 18), Font = T.BodyFont, TextColor3 = T.Muted, LayoutOrder = 99, Parent = menu })
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local panel = shortcuts[input.KeyCode]
		if panel then
			Panels[panel].toggle()
		end
	end)
end

return Hud
