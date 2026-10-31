-- Dig Up a Legendary! player script. Builds the screen and starts digging controls.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local UI = require(script.UI)
local Notifications = require(script.Notifications)
local CameraController = require(script.CameraController)
local Panels = require(script.Panels)
local Hud = require(script.Hud)
local Digging = require(script.Digging)
local World = require(script.World)
local Guide = require(script.Guide)
local Community = require(script.Community)

local player = Players.LocalPlayer

local screenGui = UI.new("ScreenGui", {
	Name = "DigLegendsUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

-- Shrink the whole UI on small screens (phones)
local scale = UI.new("UIScale", { Parent = screenGui })
local function rescale()
	local camera = Workspace.CurrentCamera
	if camera then
		local size = camera.ViewportSize
		scale.Scale = math.clamp(math.min(size.X / 1100, size.Y / 700), 0.55, 1.2)
	end
end
while not Workspace.CurrentCamera do
	task.wait()
end
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
rescale()

-- The dig minigame gets its own unscaled screen so its tap area covers everything
local diggingGui = UI.new("ScreenGui", {
	Name = "DigMinigameUI",
	ResetOnSpawn = false,
	DisplayOrder = 5,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player.PlayerGui,
})

Notifications.Init(screenGui)
CameraController.Init(diggingGui)
Panels.Init(screenGui)
Community.Init(screenGui, {
	gameId = "dig",
	rewardText = "the Crew Shovel Skin and the Pandot Crew title",
	key = Enum.KeyCode.G,
})
Panels.Community = Community.window
Hud.Init(screenGui)
Digging.Init(diggingGui)
World.Init()
Guide.Init(screenGui)

