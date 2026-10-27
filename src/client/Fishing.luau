-- Fishing on the player's screen.
--   1. Equip the rod and click the water to cast. The dot in the middle of the
--      screen tells you if you can fish where you're aiming. Walking reels in.
--   2. Watch the bobber. Little nibbles are fish testing the bait: don't strike!
--   3. When it plunges and "!" appears, click fast to strike, or the fish
--      steals your bait.
--   4. The fight: hold to reel. Watch the tension so the line doesn't snap, and
--      let go when the fish thrashes. Don't let go for too long or it swims off.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Fish = require(Shared.Fish)
local Fight = require(Shared.Fight)
local Format = require(Shared.Format)
local Config = require(Shared.Config)
local Zones = require(Shared.Zones)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Notifications = require(script.Parent.Notifications)
local State = require(script.Parent.State)
local CameraController = require(script.Parent.CameraController)
local T = UI.Theme

local Fishing = {}

local ROD_NAME = "Fishing Rod"
local WAIT_TIMEOUT = 30 -- give up if the server never answers

local MESSAGES = {
	early = "Too soon! You struck at a nibble and scared the fish away.",
	stolen = "Too slow! The fish stole your bait.",
	snapped = "SNAP! The line broke. Let go when the tension bar goes red.",
	escaped = "It got away! Don't let go for too long.",
	walked = "You walked away, so you reeled your line in.",
}

local player = Players.LocalPlayer
local screenGui
local statusLabel
local alertLabel
local aimLabel

local phase = "idle" -- idle, casting, waiting, bite, fight, done
local castId = nil
local token = 0

local sounds = {}
local function sound(name, id, volume)
	local s = Instance.new("Sound")
	s.Name = "Reel" .. name
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

local function flashAlert(text, color, seconds)
	alertLabel.Text = text
	alertLabel.TextColor3 = color
	alertLabel.Visible = true
	alertLabel.Size = UDim2.fromOffset(160, 160)
	TweenService:Create(alertLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(220, 220) }):Play()
	local mine = os.clock()
	alertLabel:SetAttribute("Shown", mine)
	task.delay(seconds, function()
		if alertLabel:GetAttribute("Shown") == mine then
			alertLabel.Visible = false
		end
	end)
end

-- While the line is out the player stands still. Trying to walk reels it in.
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

local function reset()
	setRooted(false)
	phase = "idle"
	castId = nil
	token += 1
	setStatus(nil)
	alertLabel.Visible = false
end

local function fishingLine()
	local bobber = Workspace:FindFirstChild(player.Name .. "Bobber")
	return bobber and bobber:FindFirstChildOfClass("Beam")
end

local function isWater(result)
	if not result then
		return false
	end
	if result.Instance == Workspace.Terrain then
		return result.Material == Enum.Material.Water
	end
	return result.Instance:GetAttribute("FishingZone") ~= nil
end

-- Where the bobber should land: where the player aims if that is water,
-- otherwise a spot in front of them.
local function castTarget(root)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = false

	local ray
	if CameraController.IsActive() then
		ray = CameraController.AimRay()
	else
		ray = player:GetMouse().UnitRay
	end
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	if isWater(hit) then
		return hit.Position
	end

	local look = root.CFrame.LookVector
	local ahead = root.Position + Vector3.new(look.X, 0, look.Z).Unit * 25
	return Vector3.new(ahead.X, 0.5, ahead.Z)
end

local function cast()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	phase = "casting"
	local ok, id = pcall(function()
		return Remotes.Cast:InvokeServer(castTarget(root))
	end)
	if not ok or not id then
		reset()
		return
	end
	phase = "waiting"
	castId = id
	setRooted(true)
	play("splash", 1.2)
	setStatus("Wait for the bite (!)... don't strike at nibbles")
	token += 1
	local mine = token
	task.delay(WAIT_TIMEOUT, function()
		if token == mine and (phase == "waiting" or phase == "bite") then
			reset()
		end
	end)
end

-- Click / tap with the rod out
local function onActivated()
	if phase == "idle" then
		cast()
	elseif phase == "waiting" or phase == "bite" then
		Remotes.Hook:FireServer(castId)
		if phase == "bite" then
			setStatus("Hooked...")
		end
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
		if child:IsA("Tool") and child.Name == ROD_NAME then
			hookTool(child)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == ROD_NAME and (phase == "waiting" or phase == "bite") then
			Remotes.CancelCast:FireServer()
			reset()
		end
	end)
end

------------------------------------------------------------------ The fight

local function bar(parent, y, label)
	UI.label(label, { Position = UDim2.fromOffset(20, y), Size = UDim2.fromOffset(90, 22), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, ZIndex = 22, Parent = parent })
	local back = UI.new("Frame", {
		Position = UDim2.fromOffset(110, y),
		Size = UDim2.new(1, -130, 0, 22),
		BackgroundColor3 = T.Card,
		ZIndex = 22,
		Parent = parent,
	}, { UI.corner(6) })
	local fill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Good, ZIndex = 23, Parent = back }, { UI.corner(6) })
	return back, fill
end

local function startFight(id, params)
	phase = "fight"
	setStatus(nil)
	alertLabel.Visible = false
	local rarity = Fish.RarityById[params.rarity]
	local random = Random.new()
	local state = Fight.NewState(params, random)
	local holding = false
	local connections = {}
	local finished = false


	local box = UI.new("Frame", {
		Name = "Fight",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.fromOffset(460, 150),
		BackgroundColor3 = T.Background,
		ZIndex = 21,
		Parent = screenGui,
	}, { UI.corner(14) })
	local outline = UI.stroke(rarity.color, 3)
	outline.Parent = box
	UI.label(string.format("??? (%s)", rarity.id), { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 26), TextColor3 = rarity.color, ZIndex = 22, Parent = box })
	local _, catchFill = bar(box, 44, "Catch")
	local tensionBack, tensionFill = bar(box, 74, "Tension")
	UI.new("Frame", { Position = UDim2.fromScale(0.8, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = T.Bad, ZIndex = 24, Parent = tensionBack })
	local mood = UI.label("Hold to reel!", { Position = UDim2.new(0, 0, 1, -40), Size = UDim2.new(1, 0, 0, 22), ZIndex = 22, Parent = box })
	UI.label("Hold click / tap / Space to reel", { Position = UDim2.new(0, 0, 1, -18), Size = UDim2.new(1, 0, 0, 14), Font = T.BodyFont, TextColor3 = T.Muted, ZIndex = 22, Parent = box })

	local function finish(outcome)
		if finished then
			return
		end
		finished = true
		phase = "done"
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		box:Destroy()
		if outcome == "snapped" then
			CameraController.Shake(4, 0.3)
		end
		Remotes.Reel:FireServer(id, outcome)
		setStatus(outcome == "caught" and "Landing it..." or nil)
		task.delay(5, function()
			if phase == "done" and castId == id then
				reset()
			end
		end)
	end

	local function isReelInput(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.Space
			or input.KeyCode == Enum.KeyCode.ButtonR2
			or input.KeyCode == Enum.KeyCode.ButtonA
	end
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if isReelInput(input) and not (processed and input.UserInputType == Enum.UserInputType.Touch) then
			holding = true
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if isReelInput(input) then
			holding = false
		end
	end))

	local lastPhase = state.phase
	local clickTimer = 0
	table.insert(connections, RunService.RenderStepped:Connect(function(dt)
		state.reeling = holding
		local outcome = Fight.Step(state, params, math.min(dt, 0.1), random)

		catchFill.Size = UDim2.fromScale(math.clamp(state.progress, 0, 1), 1)
		tensionFill.Size = UDim2.fromScale(math.clamp(state.tension, 0, 1), 1)
		local danger = state.tension >= 0.8
		tensionFill.BackgroundColor3 = danger and T.Bad or (state.tension > 0.55 and T.Gold or T.Good)
		local line = fishingLine()
		if line then
			line.Color = ColorSequence.new(Color3.new(1, 1, 1):Lerp(T.Bad, state.tension))
		end

		if state.phase ~= lastPhase then
			lastPhase = state.phase
			if state.phase == "thrash" then
				play("splash", 0.8)
			end
		end
		if state.phase == "warning" then
			mood.Text = "It's about to thrash... LET GO!"
			mood.TextColor3 = T.Gold
			outline.Color = T.Gold
		elseif state.phase == "thrash" then
			mood.Text = "THRASHING! Don't reel!"
			mood.TextColor3 = T.Bad
			outline.Color = T.Bad
			CameraController.Shake(1.5 * params.strength, 0.1)
		elseif danger then
			mood.Text = "Line's too tight! Ease off!"
			mood.TextColor3 = T.Bad
			outline.Color = rarity.color
		else
			mood.Text = holding and "Reeling..." or "Hold to reel!"
			mood.TextColor3 = T.Text
			outline.Color = rarity.color
		end

		if holding then
			clickTimer -= dt
			if clickTimer <= 0 then
				clickTimer = 0.18
				play("tick", 1 + state.tension * 0.6)
			end
		end

		if outcome then
			finish(outcome)
		end
	end))
end

------------------------------------------------------------------ Aiming

local hotspots = {}
local function nearHotspot(position)
	for _, spot in ipairs(hotspots) do
		if spot.Parent and Vector3.new(spot.Position.X - position.X, 0, spot.Position.Z - position.Z).Magnitude <= 12 then
			return true
		end
	end
	return false
end

-- What happens if the player casts where they are aiming right now
local function aimInfo(root)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = false
	local ray = CameraController.IsActive() and CameraController.AimRay() or player:GetMouse().UnitRay
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	if not hit then
		return "Aim at the water", T.Muted
	end
	local zoneId = hit.Instance:GetAttribute("FishingZone")
	if not zoneId then
		if hit.Instance == Workspace.Terrain and hit.Material == Enum.Material.Water then
			return "No fish out here. Try near an island", T.Muted
		end
		return "Aim at the water", T.Muted
	end
	local flat = Vector3.new(hit.Position.X - root.Position.X, 0, hit.Position.Z - root.Position.Z)
	if flat.Magnitude > Config.MaxCastDistance then
		return "Too far. Get closer to the water", T.Gold
	end
	local data = State.data
	if data and not data.zones[zoneId] then
		local zone = Zones.ById[zoneId]
		return "Locked: unlock " .. (zone and zone.name or zoneId) .. " first", T.Bad
	end
	if nearHotspot(hit.Position) then
		return "Hotspot! Click to cast (faster bites)", Color3.fromRGB(90, 230, 255)
	end
	return "Click to cast", T.Good
end

local function updateAim()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local holding = character and character:FindFirstChild(ROD_NAME)
	if phase ~= "idle" or not holding or not root then
		aimLabel.Visible = false
		CameraController.SetCrosshairColor(nil)
		return
	end
	local text, color = aimInfo(root)
	if not UserInputService.MouseEnabled then
		text = text:gsub("Click", "Tap")
	end
	aimLabel.Text = text
	aimLabel.TextColor3 = color
	aimLabel.Visible = true
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


local function showCatch(result)
	local fish = Fish.ById[result.id]
	local rarity = Fish.RarityById[fish.rarity]
	local card = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(380, 130),
		BackgroundColor3 = T.Background,
		Parent = screenGui,
	}, { UI.corner(16), UI.stroke(rarity.color, 4), UI.padding(10), UI.list(4) })
	local top = "Caught!"
	if result.isNew then
		top = "NEW FISH! Added to your Fish Book"
	elseif result.isRecord then
		top = "NEW PERSONAL RECORD!"
	end
	UI.label(top, { Size = UDim2.new(1, 0, 0, 22), TextColor3 = (result.isNew or result.isRecord) and T.Gold or T.Muted, Parent = card })
	UI.label((result.shiny and "Shiny " or "") .. fish.name, { Size = UDim2.new(1, 0, 0, 36), TextColor3 = rarity.color, Parent = card })
	if result.isNew or result.isRecord or rarity.order >= 4 then
		confetti({ rarity.color, T.Gold, Color3.new(1, 1, 1), T.Accent })
		play("ping", 1.3)
	end
	UI.label(string.format("%s  -  %s  -  %s coins  -  +%d XP", fish.rarity, Format.Weight(result.weight), Format.Number(result.value), result.xp or 0), {
		Size = UDim2.new(1, 0, 0, 22),
		Font = T.BodyFont,
		Parent = card,
	})
	task.delay(2.5, function()
		local tween = TweenService:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		card:Destroy()
	end)
end

function Fishing.Init(gui)
	screenGui = gui
	sound("splash", "rbxasset://sounds/impact_water.mp3", 0.7)
	sound("ping", "rbxasset://sounds/electronicpingshort.wav", 0.6)
	sound("tick", "rbxasset://sounds/button.wav", 0.25)

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
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("Hotspot") then
			table.insert(hotspots, item)
		end
	end
	local aimClock = 0
	RunService.Heartbeat:Connect(function(dt)
		-- Trying to walk while the line is out reels it in
		if rooted and (phase == "waiting" or phase == "bite") and rooted.humanoid.MoveDirection.Magnitude > 0.1 then
			Remotes.CancelCast:FireServer()
			reset()
			Notifications.Show(MESSAGES.walked, "info")
		end
		aimClock += dt
		if aimClock >= 0.1 then
			aimClock = 0
			updateAim()
		end
	end)

	alertLabel = UI.label("!", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromOffset(220, 220),
		Visible = false,
		TextStrokeTransparency = 0,
		ZIndex = 30,
		Parent = gui,
	})

	if player.Character then
		watchCharacter(player.Character)
		local tool = player.Character:FindFirstChild(ROD_NAME)
		if tool then
			hookTool(tool)
		end
	end
	player.CharacterAdded:Connect(watchCharacter)

	Remotes.Nibble.OnClientEvent:Connect(function(id)
		if id == castId and phase == "waiting" then
			play("splash", 1.8)
			flashAlert("nibble...", T.Muted, 0.4)
		end
	end)

	Remotes.Bite.OnClientEvent:Connect(function(id, info)
		if id ~= castId or phase ~= "waiting" then
			return
		end
		phase = "bite"
		play("ping")
		play("splash", 0.9)
		CameraController.Shake(2, 0.2)
		flashAlert("!", T.Gold, info.window)
		setStatus("STRIKE! Click now!")
	end)

	Remotes.Fight.OnClientEvent:Connect(function(id, params)
		if id == castId then
			startFight(id, params)
		end
	end)

	Remotes.CatchResult.OnClientEvent:Connect(function(id, result, reason)
		if id ~= castId then
			return
		end
		reset()
		if result then
			showCatch(result)
		else
			Notifications.Show(MESSAGES[reason] or MESSAGES.escaped, "warning")
		end
	end)
end

return Fishing
