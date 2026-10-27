-- Grandpa Gus's first-day guide on screen: the current goal at the top, a golden
-- line from you to where you need to go, and Gus talking above his head.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tutorial = require(Shared.Tutorial)

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local T = UI.Theme

local Guide = {}

local GUS_TIPS = {
	"Bring me the finds on my board and I'll pay you three times what Ruby would!",
	"Sparkling dirt means treasure. Each spot takes a little while to refill after you dig it.",
	"Hit the gold middle of the green for perfect digs. Perfect finds are worth more!",
	"Finds that are in demand sell for double. Check Ruby's Trading Post!",
	"Clover at the Charm Cart turns your spare finds into lucky charms.",
	"A legendary find is buried somewhere every week. Check the event board!",
}

local player = Players.LocalPlayer
local card, cardText
local beam, beamFrom, beamTo, marker, follower
local gusBubble, gusText

local function findTarget(name)
	if not name then
		return nil
	end
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and (item:GetAttribute("GuideTarget") == name or item:GetAttribute("Station") == name) then
			return item
		end
	end
	return nil
end

local function findGus()
	for _, item in ipairs(Workspace:GetChildren()) do
		if item:IsA("Model") and item:GetAttribute("NpcId") == "Gus" then
			return item
		end
	end
	return nil
end

local function currentStep()
	local data = State.data
	if not data or not data.tutorial or data.tutorial >= Tutorial.Done then
		return nil, nil
	end
	return Tutorial.Steps[data.tutorial], data.tutorial
end

local function update()
	local step, index = currentStep()
	card.Visible = step ~= nil
	if not step then
		beam.Enabled = false
		marker.Enabled = false
		return
	end
	cardText.Text = string.format("Grandpa Gus (%d/%d): %s", index, #Tutorial.Steps, step.text)

	local target = findTarget(step.target)
	if target then
		beamTo.Parent = target
		beam.Enabled = true
		marker.Adornee = target
		marker.Enabled = true
	else
		beam.Enabled = false
		marker.Enabled = false
	end
end

local function setupGus()
	gusBubble = UI.new("BillboardGui", {
		Name = "GusSays",
		Size = UDim2.fromOffset(260, 90),
		StudsOffset = Vector3.new(0, 5.5, 0),
		MaxDistance = 70,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local bubble = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = gusBubble }, { UI.corner(12), UI.padding(8) })
	gusText = UI.label("", { Size = UDim2.fromScale(1, 1), TextColor3 = Color3.fromRGB(30, 30, 40), Font = T.BodyFont, TextWrapped = true, Parent = bubble })

	task.spawn(function()
		local tip = 1
		while true do
			local gus = findGus()
			gusBubble.Adornee = gus and gus:FindFirstChild("Head")
			local step = currentStep()
			if step then
				gusText.Text = step.text
			else
				gusText.Text = GUS_TIPS[tip]
				tip = tip % #GUS_TIPS + 1
			end
			task.wait(step and 1 or 8)
		end
	end)
end

function Guide.Init(screenGui)
	card = UI.new("Frame", {
		Name = "GuideCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.fromOffset(560, 56),
		BackgroundColor3 = Color3.fromRGB(255, 244, 214),
		Visible = false,
		Parent = screenGui,
	}, { UI.corner(12), UI.stroke(T.Gold, 3), UI.padding(8) })
	cardText = UI.label("", { Size = UDim2.fromScale(1, 1), TextColor3 = Color3.fromRGB(60, 40, 20), Font = T.BodyFont, TextWrapped = true, Parent = card })

	-- An invisible part that follows the player carries the start of the line
	follower = Instance.new("Part")
	follower.Name = "GuideFollower"
	follower.Anchored = true
	follower.CanCollide = false
	follower.CanQuery = false
	follower.CanTouch = false
	follower.Transparency = 1
	follower.Size = Vector3.one * 0.2
	follower.Parent = Workspace
	beamFrom = Instance.new("Attachment")
	beamFrom.Name = "GuideFrom"
	beamFrom.Parent = follower
	beamTo = Instance.new("Attachment")
	beamTo.Name = "GuideTo"
	beamTo.Position = Vector3.new(0, 3, 0)
	beam = Instance.new("Beam")
	beam.Attachment0 = beamFrom
	beam.Attachment1 = beamTo
	beam.Width0 = 0.6
	beam.Width1 = 0.6
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(T.Gold)
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0.1) })
	beam.LightEmission = 1
	beam.Enabled = false
	beam.Parent = beamFrom

	marker = UI.new("BillboardGui", {
		Name = "GuideMarker",
		Size = UDim2.fromOffset(80, 80),
		StudsOffset = Vector3.new(0, 6, 0),
		AlwaysOnTop = true,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local arrow = UI.label("V", { Size = UDim2.fromScale(1, 1), TextColor3 = T.Gold, TextStrokeTransparency = 0, Parent = marker })

	RunService.RenderStepped:Connect(function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			follower.Position = root.Position - Vector3.new(0, 1.5, 0)
		end
		if marker.Enabled then
			marker.StudsOffset = Vector3.new(0, 6 + math.sin(os.clock() * 4) * 0.6, 0)
			arrow.TextTransparency = 0
		end
	end)

	State.Changed:Connect(update)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		update()
	end)
	update()
	setupGus()
end

return Guide
