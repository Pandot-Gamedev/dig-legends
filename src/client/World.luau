-- Things in the world that only this player sees: weather, opened zone gates,
-- the VIP door, and ambient life (seagulls).

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Events = require(Shared.Events)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local Panels = require(script.Parent.Panels)

local World = {}

local LOOKS = {
	Clear = { ClockTime = 14, Brightness = 2.5, Density = 0.25, Color = Color3.fromRGB(200, 220, 255), Rain = 0 },
	Rain = { ClockTime = 13, Brightness = 1.2, Density = 0.4, Color = Color3.fromRGB(150, 160, 175), Rain = 300 },
	Fog = { ClockTime = 9, Brightness = 1.5, Density = 0.62, Color = Color3.fromRGB(200, 205, 210), Rain = 0 },
	Storm = { ClockTime = 19, Brightness = 0.8, Density = 0.5, Color = Color3.fromRGB(90, 95, 120), Rain = 700 },
	GoldenHour = { ClockTime = 17.6, Brightness = 2.2, Density = 0.3, Color = Color3.fromRGB(255, 190, 120), Rain = 0 },
}

local atmosphere
local rainEmitter

local function setupWeatherEffects()
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Parent = Lighting

	local rainPart = Instance.new("Part")
	rainPart.Name = "RainCloud"
	rainPart.Anchored = true
	rainPart.CanCollide = false
	rainPart.CanQuery = false
	rainPart.CanTouch = false
	rainPart.Transparency = 1
	rainPart.Size = Vector3.new(120, 1, 120)
	rainEmitter = Instance.new("ParticleEmitter")
	rainEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	rainEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 200, 255))
	rainEmitter.Size = NumberSequence.new(0.15)
	rainEmitter.Lifetime = NumberRange.new(1.2)
	rainEmitter.Speed = NumberRange.new(50)
	rainEmitter.EmissionDirection = Enum.NormalId.Bottom
	rainEmitter.Rate = 0
	rainEmitter.Parent = rainPart
	rainPart.Parent = Workspace

	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if camera then
			rainPart.Position = camera.CFrame.Position + Vector3.new(0, 40, 0)
		end
	end)
end

local currentWeather = nil
local function applyWeather()
	local weather = Events.GetWeather()
	if weather.id == currentWeather then
		return
	end
	currentWeather = weather.id
	local look = LOOKS[weather.id] or LOOKS.Clear
	local info = TweenInfo.new(5)
	TweenService:Create(Lighting, info, { ClockTime = look.ClockTime, Brightness = look.Brightness }):Play()
	TweenService:Create(atmosphere, info, { Density = look.Density, Color = look.Color }):Play()
	rainEmitter.Rate = look.Rain
end

local function updateGates()
	local data = State.data
	if not data then
		return
	end
	local vip = State.HasPass("VIP")
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") then
			local zoneId = item:GetAttribute("ZoneGate")
			if zoneId then
				local open = data.zones[zoneId] == true
				item.CanCollide = not open
				item.Transparency = open and 0.9 or 0
				local prompt = item:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Enabled = not open
				end
				for _, gui in ipairs(item:GetChildren()) do
					if gui:IsA("SurfaceGui") then
						gui.Enabled = not open
					end
				end
			elseif item:GetAttribute("VipDoor") then
				item.CanCollide = not vip
				item.Transparency = vip and 0.8 or 0.5
			end
		end
	end
end

------------------------------------------------------------------ Ambient life

-- Seagulls circling over the islands
local function seagulls()
	local birds = {}
	local centers = { Vector3.new(0, 0, 0), Vector3.new(230, 0, 0), Vector3.new(460, 0, 0), Vector3.new(690, 0, 0) }
	for i = 1, 8 do
		local model = Instance.new("Model")
		model.Name = "Seagull"
		local function bit(size, color)
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Size = size
			p.Color = color
			p.Parent = model
			return p
		end
		local body = bit(Vector3.new(0.7, 0.7, 2), Color3.fromRGB(245, 245, 245))
		local left = bit(Vector3.new(2.4, 0.15, 0.9), Color3.fromRGB(200, 200, 205))
		local right = bit(Vector3.new(2.4, 0.15, 0.9), Color3.fromRGB(200, 200, 205))
		model.Parent = Workspace
		table.insert(birds, {
			body = body,
			left = left,
			right = right,
			center = centers[(i - 1) % #centers + 1] + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30)),
			radius = 25 + math.random() * 30,
			height = 30 + math.random() * 15,
			speed = (0.15 + math.random() * 0.15) * (math.random() < 0.5 and -1 or 1),
			phase = math.random() * math.pi * 2,
		})
	end
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for _, bird in ipairs(birds) do
			local a = bird.phase + now * bird.speed
			local position = bird.center + Vector3.new(math.cos(a) * bird.radius, bird.height + math.sin(now * 0.7 + bird.phase) * 2, math.sin(a) * bird.radius)
			local tangent = Vector3.new(-math.sin(a), 0, math.cos(a)) * math.sign(bird.speed)
			local frame = CFrame.lookAt(position, position + tangent) * CFrame.Angles(0, 0, -0.3 * math.sign(bird.speed))
			local flap = math.sin(now * 8 + bird.phase) * 0.5
			bird.body.CFrame = frame
			bird.left.CFrame = frame * CFrame.new(-0.35, 0, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(-1.2, 0, 0)
			bird.right.CFrame = frame * CFrame.new(0.35, 0, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(1.2, 0, 0)
		end
	end)
end

function World.Init()
	seagulls()

	setupWeatherEffects()
	applyWeather()
	task.spawn(function()
		while true do
			task.wait(2)
			applyWeather()
		end
	end)

	State.Changed:Connect(updateGates)
	updateGates()

	Remotes.OpenPanel.OnClientEvent:Connect(function(name)
		local panel = Panels[name]
		if panel then
			panel.open()
		end
	end)
end

return World
