-- Over-the-shoulder camera for mouse players: moving the mouse turns the camera
-- and your character, like most action games. The mouse is free again whenever
-- a menu is open, or when you press Alt (press again to lock it).
-- Phones and tablets keep Roblox's normal touch camera.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local UI = require(script.Parent.UI)

local CameraController = {}

local SENSITIVITY = 0.0035 -- radians per pixel of mouse movement
local GAMEPAD_SPEED = 3 -- radians per second at full stick
local SHOULDER = Vector3.new(1.6, 0.9, 0) -- camera sits over the right shoulder
local MIN_PITCH, MAX_PITCH = math.rad(-75), math.rad(60)
local MIN_ZOOM, MAX_ZOOM = 5, 28

local player = Players.LocalPlayer
local enabled = false
local cursorFree = false
local yaw, pitch, zoom = 0, math.rad(-15), 12
local stick = Vector2.zero
local shakeUntil, shakeAmount = 0, 0
local crosshair

function CameraController.IsActive()
	return enabled
end

function CameraController.IsLocked()
	return enabled and not cursorFree and not UI.IsWindowOpen()
end

-- Shake the camera (used when a fish thrashes)
function CameraController.Shake(amount, seconds)
	shakeAmount = math.max(shakeAmount, amount)
	shakeUntil = math.max(shakeUntil, os.clock() + seconds)
end

-- Colors the aiming dot (nil = plain white)
function CameraController.SetCrosshairColor(color)
	if crosshair then
		crosshair.BackgroundColor3 = color or Color3.new(1, 1, 1)
	end
end

-- The ray the player is aiming along: screen center when locked, else the mouse
function CameraController.AimRay()
	local camera = Workspace.CurrentCamera
	if CameraController.IsLocked() then
		local size = camera.ViewportSize
		return camera:ViewportPointToRay(size.X / 2, size.Y / 2)
	end
	local mouse = UserInputService:GetMouseLocation()
	return camera:ViewportPointToRay(mouse.X, mouse.Y)
end

local function update(dt)
	local camera = Workspace.CurrentCamera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not camera or not root or not humanoid then
		return
	end

	local locked = CameraController.IsLocked()
	UserInputService.MouseBehavior = locked and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = not locked
	crosshair.Visible = locked

	if stick.Magnitude > 0.15 then
		yaw -= stick.X * GAMEPAD_SPEED * dt
		pitch = math.clamp(pitch + stick.Y * GAMEPAD_SPEED * dt, MIN_PITCH, MAX_PITCH)
	end

	-- Character faces where the camera looks
	if humanoid.Health > 0 and not humanoid.Sit then
		humanoid.AutoRotate = false
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
	end

	camera.CameraType = Enum.CameraType.Scriptable
	local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	local focus = root.Position + Vector3.new(0, 1.5, 0)
	local offset = rotation:VectorToWorldSpace(SHOULDER + Vector3.new(0, 0, zoom))

	-- Don't let the camera go through walls
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true
	local position = focus + offset
	local hit = Workspace:Raycast(focus, offset, params)
	if hit then
		position = hit.Position - offset.Unit * 0.5
	end

	local shake = CFrame.new()
	if os.clock() < shakeUntil then
		local s = shakeAmount
		shake = CFrame.Angles(math.rad((math.random() - 0.5) * s), math.rad((math.random() - 0.5) * s), 0)
	else
		shakeAmount = 0
	end
	camera.CFrame = CFrame.new(position) * rotation * shake
	camera.Focus = CFrame.new(focus)
end

function CameraController.Init(screenGui)
	-- Touch-only devices keep the normal camera
	if not UserInputService.MouseEnabled then
		return
	end
	enabled = true

	crosshair = UI.new("Frame", {
		Name = "Crosshair",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = screenGui,
	}, { UI.corner(4), UI.stroke(Color3.new(0, 0, 0), 1) })

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and CameraController.IsLocked() then
			yaw -= input.Delta.X * SENSITIVITY
			pitch = math.clamp(pitch - input.Delta.Y * SENSITIVITY, MIN_PITCH, MAX_PITCH)
		elseif input.UserInputType == Enum.UserInputType.MouseWheel and not UI.IsWindowOpen() then
			zoom = math.clamp(zoom - input.Position.Z * 2, MIN_ZOOM, MAX_ZOOM)
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
			stick = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
			cursorFree = not cursorFree
		end
	end)

	local function onCharacter(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root then
			local look = root.CFrame.LookVector
			yaw = math.atan2(-look.X, -look.Z)
		end
	end
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)

	RunService:BindToRenderStep("ReelShoulderCamera", Enum.RenderPriority.Camera.Value + 1, update)
end

return CameraController
