-- Digging on the player's screen.
--   1. Take out the shovel and stand next to a sparkling dig spot. The text
--      under the middle of the screen tells you if you can dig there.
--   2. Click to dig down. Walking away stops digging.
--   3. The dig minigame: a marker slides along a bar. Tap while it is in the
--      green to dig deeper; the gold middle is a perfect hit and makes the find
--      worth more. Tapping outside the green cracks the find.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Finds = require(Shared.Finds)
local Dig = require(Shared.Dig)
local Format = require(Shared.Format)
local Config = require(Shared.Config)
local Zones = require(Shared.Zones)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Notifications = require(script.Parent.Notifications)
local State = require(script.Parent.State)
local CameraController = require(script.Parent.CameraController)
local T = UI.Theme

local Digging = {}

local SHOVEL_NAME = "Shovel"
local WAIT_TIMEOUT = 30 -- give up if the server never answers

local MESSAGES = {
	cracked = "CRACK! Your find broke. Tap while the marker is in the green.",
	walked = "You walked away, so you stopped digging.",
	timeout = "You took too long and the find sank too deep.",
}

local player = Players.LocalPlayer
local screenGui
local statusLabel
local aimLabel
local highlight

local phase = "idle" -- idle, starting, digging, minigame, done
local digId = nil
local digSpot = nil
local token = 0

local spots = {} -- [spot] = true for every dig spot this player's game has loaded
local hiddenUntil = {} -- [spot] = os.clock() when this player can dig it again

local sounds = {}
local function sound(name, id, volume)
	local s = Instance.new("Sound")
	s.Name = "Dig" .. name
	s.SoundId = id
	s.Volume = volume or 0.6
	s.Parent = SoundService
	sounds[name] = s
end
local function play(name, pitch)
	local s = sounds[name]
	if s then
		s.PlaybackSpeed = pitch or 1
		SoundService:PlayLocalSound(s)
	end
end

local function setStatus(text)
	statusLabel.Text = text or ""
	statusLabel.Visible = text ~= nil
end

-- While digging the player stands still. Trying to walk stops digging.
local rooted = nil
local function setRooted(on)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if on and humanoid and not rooted then
		rooted = { humanoid = humanoid, speed = humanoid.WalkSpeed }
		humanoid.WalkSpeed = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	elseif not on and rooted then
		if rooted.humanoid.Parent then
			rooted.humanoid.WalkSpeed = rooted.speed > 0 and rooted.speed or 16
			rooted.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
		rooted = nil
	end
end

-- Closes the dig minigame if one is on screen (set while it runs)
local closeMinigame = nil

local function reset()
	if closeMinigame then
		closeMinigame()
	end
	setRooted(false)
	phase = "idle"
	digId = nil
	digSpot = nil
	token += 1
	setStatus(nil)
end

------------------------------------------------------------------ Dig spots

-- A spot you just dug looks empty (for you only) until you can dig it again
local function hideSpot(spot)
	local untilTime = os.clock() + Config.SpotCooldown
	hiddenUntil[spot] = untilTime
	spot.Transparency = 0.75
	local sparkle = spot:FindFirstChild("Sparkle")
	if sparkle then
		sparkle.Enabled = false
	end
	task.delay(Config.SpotCooldown, function()
		if hiddenUntil[spot] == untilTime and spot.Parent then
			hiddenUntil[spot] = nil
			spot.Transparency = 0
			if sparkle then
				sparkle.Enabled = true
			end
		end
	end)
end

local function isHidden(spot)
	local untilTime = hiddenUntil[spot]
	return untilTime ~= nil and os.clock() < untilTime
end

local function flatDistance(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- The closest spot in reach that this player can dig, plus the closest spot in
-- reach of any kind (to explain why you can't dig it)
local function spotsNear(root)
	local best, bestDistance = nil, math.huge
	local any, anyDistance = nil, math.huge
	for spot in pairs(spots) do
		if spot.Parent then
			local distance = flatDistance(spot.Position, root.Position)
			if distance <= Config.DigRange then
				if distance < anyDistance then
					any, anyDistance = spot, distance
				end
				local zoneId = spot:GetAttribute("DigSpot")
				local unlocked = State.data and State.data.zones[zoneId]
				if unlocked and not isHidden(spot) and distance < bestDistance then
					best, bestDistance = spot, distance
				end
			end
		end
	end
	return best, any
end

local function startDig()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local spot, any = spotsNear(root)
	if not spot then
		if any and isHidden(any) then
			Notifications.Show("You already dug here. Try another spot!", "warning")
		elseif any then
			local zone = Zones.ById[any:GetAttribute("DigSpot")]
			Notifications.Show("Unlock " .. (zone and zone.name or "this zone") .. " to dig here.", "warning")
		else
			Notifications.Show("Stand next to a sparkling dig spot to dig.", "info")
		end
		return
	end

	phase = "starting"
	local ok, id = pcall(function()
		return Remotes.StartDig:InvokeServer(spot)
	end)
	if not ok or not id then
		reset()
		return
	end
	phase = "digging"
	digId = id
	digSpot = spot
	setRooted(true)
	play("dig", 1)
	setStatus("Digging...")
	token += 1
	local mine = token
	task.delay(WAIT_TIMEOUT, function()
		if token == mine and phase == "digging" then
			reset()
		end
	end)
end

-- Click / tap with the shovel out
local function onActivated()
	if phase == "idle" then
		startDig()
	end
end

local hookedTools = setmetatable({}, { __mode = "k" })
local function hookTool(tool)
	if not hookedTools[tool] then
		hookedTools[tool] = true
		tool.Activated:Connect(onActivated)
	end
end

local function watchCharacter(character)
	reset()
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == SHOVEL_NAME then
			hookTool(child)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == SHOVEL_NAME and (phase == "digging" or phase == "minigame") then
			if phase == "minigame" and digSpot then
				hideSpot(digSpot) -- the server uses up the spot too
			end
			Remotes.CancelDig:FireServer()
			reset()
		end
	end)
end

------------------------------------------------------------------ The dig minigame

local function startMinigame(id, params)
	phase = "minigame"
	setStatus(nil)
	local rarity = Finds.RarityById[params.rarity]
	local random = Random.new()
	local connections = {}
	local finished = false
	local hits, perfects, cracks = 0, 0, 0
	local center = Dig.NextCenter(random, params)
	local elapsed = 0
	local lastTap = -math.huge

	local box = UI.new("Frame", {
		Name = "DigGame",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.fromOffset(460, 160),
		BackgroundColor3 = T.Background,
		ZIndex = 21,
		Parent = screenGui,
	}, { UI.corner(14) })
	local outline = UI.stroke(rarity.color, 3)
	outline.Parent = box
	UI.label(string.format("??? (%s)", rarity.id), { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 26), TextColor3 = rarity.color, ZIndex = 22, Parent = box })

	local barBack = UI.new("Frame", {
		Position = UDim2.fromOffset(20, 44),
		Size = UDim2.new(1, -40, 0, 34),
		BackgroundColor3 = Color3.fromRGB(95, 65, 40),
		ZIndex = 22,
		Parent = box,
	}, { UI.corner(8) })
	local sweet = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromScale(params.zone, 1),
		BackgroundColor3 = T.Good,
		ZIndex = 23,
		Parent = barBack,
	}, { UI.corner(6) })
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(params.perfect / params.zone, 1),
		BackgroundColor3 = T.Gold,
		ZIndex = 24,
		Parent = sweet,
	})
	local marker = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(0, 6, 1, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 25,
		Parent = barBack,
	}, { UI.corner(3), UI.stroke(Color3.new(0, 0, 0), 1) })

	local depth = UI.label("", { Position = UDim2.fromOffset(20, 86), Size = UDim2.new(0.5, -20, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22, Parent = box })
	local crackLine = UI.label("", { Position = UDim2.new(0.5, 0, 0, 86), Size = UDim2.new(0.5, -20, 0, 24), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.Bad, ZIndex = 22, Parent = box })
	local mood = UI.label("Tap in the green!", { Position = UDim2.new(0, 0, 1, -42), Size = UDim2.new(1, 0, 0, 22), ZIndex = 22, Parent = box })
	UI.label("Click / tap / Space when the marker is in the green", { Position = UDim2.new(0, 0, 1, -18), Size = UDim2.new(1, 0, 0, 14), Font = T.BodyFont, TextColor3 = T.Muted, ZIndex = 22, Parent = box })

	local function refreshLines()
		depth.Text = string.format("Depth %d/%d", hits, params.strikes)
		crackLine.Text = string.rep("X ", cracks) .. string.rep("- ", params.cracks - cracks)
		sweet.Position = UDim2.fromScale(center, 0)
	end
	refreshLines()

	local function close()
		finished = true
		closeMinigame = nil
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		box:Destroy()
	end
	closeMinigame = close

	local function finish(outcome)
		if finished then
			return
		end
		close()
		phase = "done"
		if outcome == "cracked" then
			CameraController.Shake(4, 0.3)
		end
		Remotes.DigDone:FireServer(id, outcome, perfects)
		setStatus(outcome == "found" and "Digging it out..." or nil)
		task.delay(5, function()
			if phase == "done" and digId == id then
				reset()
			end
		end)
	end

	local function tap()
		if elapsed - lastTap < Dig.MinTapGap then
			return -- too soon after the last tap; doesn't count either way
		end
		lastTap = elapsed
		local result = Dig.Judge(Dig.MarkerAt(elapsed, params.speed), center, params)
		if result == "miss" then
			cracks += 1
			play("crack", 1.2)
			CameraController.Shake(2.5, 0.15)
			mood.Text = "CRACK! Careful!"
			mood.TextColor3 = T.Bad
			outline.Color = T.Bad
			if cracks >= params.cracks then
				finish("cracked")
				return
			end
		else
			hits += 1
			if result == "perfect" then
				perfects += 1
				play("ping", 1.5)
				mood.Text = "PERFECT!"
				mood.TextColor3 = T.Gold
			else
				mood.Text = "Nice dig!"
				mood.TextColor3 = T.Good
			end
			play("dig", 0.9 + hits * 0.08)
			outline.Color = rarity.color
			CameraController.Shake(1, 0.08)
			if hits >= params.strikes then
				refreshLines()
				finish("found")
				return
			end
			center = Dig.NextCenter(random, params)
		end
		refreshLines()
	end

	local function isTapInput(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.Space
			or input.KeyCode == Enum.KeyCode.ButtonR2
			or input.KeyCode == Enum.KeyCode.ButtonA
	end
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if isTapInput(input) and not (processed and input.UserInputType == Enum.UserInputType.Touch) then
			tap()
		end
	end))

	table.insert(connections, RunService.RenderStepped:Connect(function(dt)
		elapsed += math.min(dt, 0.1)
		marker.Position = UDim2.fromScale(Dig.MarkerAt(elapsed, params.speed), 0.5)
		if elapsed > Dig.MaxSeconds then
			finish("cracked")
		end
	end))
end

------------------------------------------------------------------ Aiming

-- What happens if the player digs right now
local function aimInfo(root)
	if not State.data then
		return "Loading...", T.Muted, nil
	end
	local spot, any = spotsNear(root)
	if spot then
		return "Click to dig!", T.Good, spot
	end
	if any and isHidden(any) then
		return "Dug out. Try another spot", T.Gold, nil
	elseif any then
		local zone = Zones.ById[any:GetAttribute("DigSpot")]
		return "Locked: unlock " .. (zone and zone.name or "this zone") .. " first", T.Bad, nil
	end
	return "Walk to a sparkling dig spot", T.Muted, nil
end

local function updateAim()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local holding = character and character:FindFirstChild(SHOVEL_NAME)
	if phase ~= "idle" or not holding or not root or UI.IsWindowOpen() then
		aimLabel.Visible = false
		highlight.Adornee = nil
		CameraController.SetCrosshairColor(nil)
		return
	end
	local text, color, spot = aimInfo(root)
	if not UserInputService.MouseEnabled then
		text = text:gsub("Click", "Tap")
	end
	aimLabel.Text = text
	aimLabel.TextColor3 = color
	aimLabel.Visible = true
	highlight.Adornee = spot
	CameraController.SetCrosshairColor(color)
end

------------------------------------------------------------------ Results

local function confetti(colors)
	for _ = 1, 40 do
		local size = math.random(8, 14)
		local piece = UI.new("Frame", {
			Position = UDim2.new(math.random(), 0, 0, -20),
			Size = UDim2.fromOffset(size, size * 0.6),
			Rotation = math.random(0, 360),
			BackgroundColor3 = colors[math.random(1, #colors)],
			BorderSizePixel = 0,
			ZIndex = 40,
			Parent = screenGui,
		})
		local fall = TweenService:Create(piece, TweenInfo.new(math.random(15, 28) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(piece.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.1, 0),
			Rotation = piece.Rotation + math.random(-360, 360),
		})
		fall:Play()
		fall.Completed:Connect(function()
			piece:Destroy()
		end)
	end
end

local function showFind(result)
	local find = Finds.ById[result.id]
	local rarity = Finds.RarityById[find.rarity]
	local card = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(400, 150),
		BackgroundColor3 = T.Background,
		Parent = screenGui,
	}, { UI.corner(16), UI.stroke(rarity.color, 4), UI.padding(10), UI.list(4) })
	local top = "Found!"
	if result.isNew then
		top = "NEW FIND! Added to your Collection"
	elseif result.isRecord then
		top = "NEW PERSONAL RECORD!"
	end
	UI.label(top, { Size = UDim2.new(1, 0, 0, 22), TextColor3 = (result.isNew or result.isRecord) and T.Gold or T.Muted, Parent = card })
	UI.label((result.shiny and "Shiny " or "") .. find.name, { Size = UDim2.new(1, 0, 0, 36), TextColor3 = rarity.color, Parent = card })
	if result.isNew or result.isRecord or rarity.order >= 4 then
		confetti({ rarity.color, T.Gold, Color3.new(1, 1, 1), T.Accent })
		play("ping", 1.3)
	end
	UI.label(string.format("%s  -  %s  -  %s coins  -  +%d XP", find.rarity, Format.Weight(result.weight), Format.Number(result.value), result.xp or 0), {
		Size = UDim2.new(1, 0, 0, 22),
		Font = T.BodyFont,
		Parent = card,
	})
	local bonus = math.floor((Dig.ValueMultiplier(result.perfects or 0, result.strikes or 1) - 1) * 100 + 0.5)
	UI.label(string.format("Perfect hits %d/%d  (+%d%% value)", result.perfects or 0, result.strikes or 0, bonus), {
		Size = UDim2.new(1, 0, 0, 20),
		Font = T.BodyFont,
		TextColor3 = bonus > 0 and T.Gold or T.Muted,
		Parent = card,
	})
	task.delay(2.5, function()
		local tween = TweenService:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		card:Destroy()
	end)
end

function Digging.Init(gui)
	screenGui = gui
	sound("dig", "rbxasset://sounds/collide.wav", 0.5)
	sound("crack", "rbxasset://sounds/glassbreak.wav", 0.5)
	sound("ping", "rbxasset://sounds/electronicpingshort.wav", 0.6)

	statusLabel = UI.label("", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -120),
		Size = UDim2.fromOffset(520, 30),
		Visible = false,
		TextStrokeTransparency = 0.4,
		Parent = gui,
	})
	aimLabel = UI.label("", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 16),
		Size = UDim2.fromOffset(420, 22),
		Visible = false,
		TextStrokeTransparency = 0.3,
		Parent = gui,
	})
	highlight = Instance.new("Highlight")
	highlight.Name = "DigSpotHighlight"
	highlight.FillColor = T.Gold
	highlight.FillTransparency = 0.6
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = Workspace

	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("DigSpot") then
			spots[item] = true
		end
	end
	Workspace.DescendantAdded:Connect(function(item)
		if item:IsA("BasePart") and item:GetAttribute("DigSpot") then
			spots[item] = true
		end
	end)

	local aimClock = 0
	RunService.Heartbeat:Connect(function(dt)
		-- Trying to walk while digging down stops digging
		if rooted and phase == "digging" and rooted.humanoid.MoveDirection.Magnitude > 0.1 then
			Remotes.CancelDig:FireServer()
			reset()
			Notifications.Show(MESSAGES.walked, "info")
		end
		aimClock += dt
		if aimClock >= 0.1 then
			aimClock = 0
			updateAim()
		end
	end)

	if player.Character then
		watchCharacter(player.Character)
		local tool = player.Character:FindFirstChild(SHOVEL_NAME)
		if tool then
			hookTool(tool)
		end
	end
	player.CharacterAdded:Connect(watchCharacter)

	Remotes.DigReady.OnClientEvent:Connect(function(id, params)
		if id == digId and phase == "digging" then
			play("ping")
			CameraController.Shake(1.5, 0.2)
			startMinigame(id, params)
		end
	end)

	Remotes.DigResult.OnClientEvent:Connect(function(id, result, reason)
		if id ~= digId then
			return
		end
		local spot = digSpot
		reset()
		if spot and (result or reason ~= "walked") then
			hideSpot(spot)
		end
		if result then
			showFind(result)
		else
			Notifications.Show(MESSAGES[reason] or MESSAGES.cracked, "warning")
		end
	end)
end

return Digging
