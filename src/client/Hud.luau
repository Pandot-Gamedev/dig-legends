-- Always-on screen info: coins, bag, the weekly event, and the menu buttons.

local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Market = require(Shared.Market)
local Zones = require(Shared.Zones)
local Events = require(Shared.Events)
local Charms = require(Shared.Charms)
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
	local levelLine = UI.label("Lv 1 Digger", { Size = UDim2.new(1, 0, 0, 22), TextColor3 = Color3.fromRGB(150, 220, 255), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = stats })
	local xpBack = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = T.Card, LayoutOrder = 0, Parent = stats }, { UI.corner(3) })
	local xpFill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(150, 220, 255), Parent = xpBack }, { UI.corner(3) })
	levelLine.LayoutOrder = -2
	xpBack.LayoutOrder = -1
	local coins = UI.label("0 coins", { Size = UDim2.new(1, 0, 0, 30), TextColor3 = T.Gold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = stats })
	local bag = UI.label("Backpack 0/20", { Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = stats })
	local charmLine = UI.label("Charm: none", { Size = UDim2.new(1, 0, 0, 18), Font = T.BodyFont, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3, Parent = stats })
	local bonus = UI.label("", { Size = UDim2.new(1, 0, 0, 18), Font = T.BodyFont, TextColor3 = T.Muted, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4, Parent = stats })

	local function update(data, runtime)
		local progress, level = Level.Progress(data.xp or 0)
		levelLine.Text = string.format("Lv %d Digger", level)
		xpFill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
		coins.Text = Format.Number(data.coins) .. " coins"
		local size = runtime.bagSize or Config.BagSize
		bag.Text = string.format("Backpack %d/%d", #data.bag, size)
		bag.TextColor3 = #data.bag >= size and T.Bad or T.Text
		local charm = Charms.ById[data.charms.equipped] or Charms.ById[Charms.Default]
		charmLine.Text = charm.free and "Charm: none" or string.format("Charm: %s x%d", charm.name, data.charms.owned[charm.id] or 0)
		charmLine.TextColor3 = charm.color
		local extra = math.floor((Market.Multiplier(data) - 1) * 100 + 0.5)
		if extra > 0 then
			bonus.Text = string.format("Coin bonus: +%d%%", extra)
		else
			bonus.Text = "Sell finds at the Trading Post"
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
			local find, weekLeft = Events.GetEventFind()
			local zone = Zones.ById[find.zone]
			eventLine.Text = string.format("Weekly legend: %s in %s (%s left)", find.name, zone and zone.name or "", Format.Duration(weekLeft))
			local weather, weatherLeft = Events.GetWeather()
			weatherLine.Text = string.format("%s: %s (%s)", weather.name, weather.description, Format.Duration(weatherLeft))
			task.wait(1)
		end
	end)

	-- Menu buttons, left side under the stats, with keyboard shortcuts. On short
	-- screens (phones) they wrap into a second column, and shrink only if needed.
	local MENU_TOP, CELL_HEIGHT, GAP = 186, 42, 6
	local menu = UI.new("Frame", {
		Name = "Menu",
		Position = UDim2.fromOffset(16, MENU_TOP),
		Size = UDim2.fromOffset(130 * 2 + GAP, 8 * (CELL_HEIGHT + GAP)),
		BackgroundTransparency = 1,
		Parent = screenGui,
	})
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(130, CELL_HEIGHT)
	grid.CellPadding = UDim2.fromOffset(GAP, GAP)
	grid.FillDirection = Enum.FillDirection.Vertical
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = menu
	local menuScale = Instance.new("UIScale")
	menuScale.Parent = menu
	local function fitMenu()
		local room = screenGui.AbsoluteSize.Y - MENU_TOP - 16
		local rows = math.clamp(math.floor((room + GAP) / (CELL_HEIGHT + GAP)), 4, 8)
		grid.FillDirectionMaxCells = rows
		menuScale.Scale = math.clamp(room / (rows * (CELL_HEIGHT + GAP) - GAP), 0.6, 1)
	end
	screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitMenu)
	fitMenu()

	local buttons = {
		{ "Backpack", "Bag", Color3.fromRGB(90, 140, 220), Enum.KeyCode.Q },
		{ "Collection", "Book", Color3.fromRGB(80, 160, 255), Enum.KeyCode.B },
		{ "Bounties", "Bounties", Color3.fromRGB(200, 150, 70), Enum.KeyCode.N },
		{ "Shovels", "Shovels", Color3.fromRGB(230, 140, 60), Enum.KeyCode.R },
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
