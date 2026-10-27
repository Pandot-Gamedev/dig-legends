-- Shows each player's name tag (name, angler level, title, VIP) and cosmetics:
-- trails, rod skins and VIP extras.
-- Also hands out free titles players earn by playing.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Fish = require(Shared.Fish)
local Shop = require(Shared.Shop)
local Remotes = require(Shared.Remotes)
local Level = require(Shared.Level)

local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)

local CosmeticService = {}

local VIP_GOLD = Color3.fromRGB(255, 200, 40)
local applied = {} -- [player] = signature of what is shown, to skip needless rebuilds

local function equippedItem(data, kind)
	local id = data.cosmetics.equipped[kind]
	return id and data.cosmetics.owned[id] and Shop.CosmeticById[id] or nil
end

function CosmeticService.StyleRod(player, handle)
	local data = DataService.Get(player)
	local skin = data and equippedItem(data, "rodSkin")
	if skin then
		handle.Color = skin.color
		handle.Material = skin.material
	end
end

function CosmeticService.DecorateBobber(player, bobber)
	if ShopService.HasPass(player, "VIP") then
		bobber.Color = VIP_GOLD
		bobber.Material = Enum.Material.Neon
	end
end

local function clearOld(character)
	for _, name in ipairs({ "ReelTitle", "ReelTrail", "ReelCrown", "ReelTrailTop", "ReelTrailBottom" }) do
		for _, item in ipairs(character:GetDescendants()) do
			if item.Name == name then
				item:Destroy()
			end
		end
	end
end

local function applyToCharacter(player)
	local data = DataService.Get(player)
	local character = player.Character
	if not data or not character then
		return
	end
	local head = character:WaitForChild("Head", 5)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not head or not root then
		return
	end
	clearOld(character)

	local vip = ShopService.HasPass(player, "VIP")
	local title = equippedItem(data, "title")

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "ReelTitle"
	gui.Size = UDim2.fromOffset(240, 72)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 90
	gui.Adornee = head
	local layout = Instance.new("UIListLayout")
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui
	local order = 0
	local function line(text, color, height)
		order += 1
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, height or 22)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextStrokeTransparency = 0.4
		label.LayoutOrder = order
		label.Parent = gui
	end
	if title then
		line(title.text, title.color, 18)
	end
	line(player.DisplayName, vip and VIP_GOLD or Color3.new(1, 1, 1), 24)
	line(string.format("%sLv %d Angler", vip and "VIP  " or "", Level.FromXp(data.xp)), Color3.fromRGB(150, 220, 255), 18)
	gui.Parent = head

	if vip then
		local crown = Instance.new("Part")
		crown.Name = "ReelCrown"
		crown.Size = Vector3.new(1.1, 0.5, 1.1)
		crown.Color = VIP_GOLD
		crown.Material = Enum.Material.Neon
		crown.CanCollide = false
		crown.CanQuery = false
		crown.Massless = true
		local weld = Instance.new("Weld")
		weld.Part0 = head
		weld.Part1 = crown
		weld.C0 = CFrame.new(0, head.Size.Y / 2 + 0.3, 0)
		weld.Parent = crown
		crown.Parent = character
	end

	local trailItem = equippedItem(data, "trail")
	if trailItem then
		local top = Instance.new("Attachment")
		top.Name = "ReelTrailTop"
		top.Position = Vector3.new(0, 0.8, 0.5)
		top.Parent = root
		local bottom = Instance.new("Attachment")
		bottom.Name = "ReelTrailBottom"
		bottom.Position = Vector3.new(0, -0.8, 0.5)
		bottom.Parent = root
		local keypoints = {}
		for index, color in ipairs(trailItem.colors) do
			table.insert(keypoints, ColorSequenceKeypoint.new((index - 1) / math.max(1, #trailItem.colors - 1), color))
		end
		local trail = Instance.new("Trail")
		trail.Name = "ReelTrail"
		trail.Attachment0 = top
		trail.Attachment1 = bottom
		trail.Color = ColorSequence.new(keypoints)
		trail.Lifetime = 0.6
		trail.LightEmission = 0.6
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Parent = root
	end
end

local function signature(data, runtime)
	local equipped = data.cosmetics.equipped
	return table.concat({
		tostring(equipped.title),
		tostring(equipped.trail),
		tostring(runtime.passes and runtime.passes.VIP),
		tostring(Level.FromXp(data.xp)),
	}, "|")
end

local function earnedTitleUnlocked(rule, data)
	if rule.rule == "zoneBook" then
		for _, fish in ipairs(Fish.ByZone[rule.zone] or {}) do
			if not data.book[fish.id] then
				return false
			end
		end
		return true
	elseif rule.rule == "eventFish" then
		for _, fish in ipairs(Fish.EventFish) do
			if data.book[fish.id] then
				return true
			end
		end
	elseif rule.rule == "rebirth" then
		return data.rebirths >= 1
	end
	return false
end

local function checkEarnedTitles(player, data)
	local newTitles = {}
	for _, title in ipairs(Shop.EarnedTitles) do
		if not data.cosmetics.owned[title.id] and earnedTitleUnlocked(title, data) then
			table.insert(newTitles, title)
		end
	end
	if #newTitles == 0 then
		return
	end
	DataService.Update(player, function(saved)
		for _, title in ipairs(newTitles) do
			saved.cosmetics.owned[title.id] = true
		end
	end)
	for _, title in ipairs(newTitles) do
		Remotes.Notify:FireClient(player, "New title unlocked: " .. title.text .. "! Equip it in the Shop.", "rare")
	end
end

function CosmeticService.Start()
	DataService.OnChanged(function(player, data, runtime)
		checkEarnedTitles(player, data)
		local current = signature(data, runtime)
		if applied[player] ~= current then
			applied[player] = current
			applyToCharacter(player)
		end
	end)

	local function watch(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			applyToCharacter(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		applied[player] = nil
	end)
end

return CosmeticService
