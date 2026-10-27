-- Shopkeepers and Old Pete. They stand on parts with an "Npc" attribute
-- (MapBuilder places them at each stall) and face the way that part faces.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local NpcService = {}

local SKIN = Color3.fromRGB(234, 184, 146)

local LOOKS = {
	OldPete = { name = "Old Pete", role = "Bounties", shirt = Color3.fromRGB(40, 60, 110), pants = Color3.fromRGB(90, 70, 50), hat = Color3.fromRGB(240, 200, 60), beard = true },
	Marina = { name = "Marina", role = "Fish Market", shirt = Color3.fromRGB(40, 160, 170), pants = Color3.fromRGB(50, 50, 70), hat = Color3.fromRGB(210, 60, 60) },
	TackleTom = { name = "Tackle Tom", role = "Bait & Tackle", shirt = Color3.fromRGB(90, 150, 70), pants = Color3.fromRGB(70, 60, 50), hat = Color3.fromRGB(60, 90, 50) },
	Rodney = { name = "Rodney", role = "Rod Shop", shirt = Color3.fromRGB(220, 120, 50), pants = Color3.fromRGB(60, 60, 60), hat = Color3.fromRGB(30, 30, 30) },
}

local function accessory(model, head, name, size, offset, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.CanCollide = false
	p.Massless = true
	p.Shape = shape or Enum.PartType.Block
	p.CFrame = head.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = p
	weld.Parent = p
	p.Parent = model
end

local function makeNpc(spot)
	local look = LOOKS[spot:GetAttribute("Npc")]
	if not look then
		return
	end
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = SKIN
	description.LeftArmColor = SKIN
	description.RightArmColor = SKIN
	description.TorsoColor = look.shirt
	description.LeftLegColor = look.pants
	description.RightLegColor = look.pants

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[NpcService] Couldn't create " .. look.name .. ": " .. tostring(model))
		return
	end
	model.Name = look.name
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = look.name
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true

	local height = humanoid.HipHeight + root.Size.Y / 2
	model:PivotTo(CFrame.new(spot.Position + Vector3.new(0, spot.Size.Y / 2 + height, 0)) * spot.CFrame.Rotation)

	local head = model:FindFirstChild("Head")
	if head then
		local brim = CFrame.new(0, head.Size.Y / 2 + 0.05, 0) * CFrame.Angles(0, 0, math.rad(90))
		accessory(model, head, "HatBrim", Vector3.new(0.15, 2, 2), brim, look.hat, Enum.PartType.Cylinder)
		accessory(model, head, "HatTop", Vector3.new(1.1, 0.5, 1.1), CFrame.new(0, head.Size.Y / 2 + 0.35, 0), look.hat)
		if look.beard then
			accessory(model, head, "Beard", Vector3.new(0.9, 0.5, 0.3), CFrame.new(0, -head.Size.Y / 2 + 0.05, -head.Size.Z / 2), Color3.fromRGB(235, 235, 235))
		end

		local tag = Instance.new("BillboardGui")
		tag.Size = UDim2.fromOffset(200, 50)
		tag.StudsOffset = Vector3.new(0, 2.8, 0)
		tag.MaxDistance = 80
		local name = Instance.new("TextLabel")
		name.Size = UDim2.fromScale(1, 0.6)
		name.BackgroundTransparency = 1
		name.Text = look.name
		name.TextScaled = true
		name.Font = Enum.Font.FredokaOne
		name.TextColor3 = Color3.new(1, 1, 1)
		name.TextStrokeTransparency = 0.3
		name.Parent = tag
		local role = name:Clone()
		role.Position = UDim2.fromScale(0, 0.6)
		role.Size = UDim2.fromScale(1, 0.4)
		role.Text = look.role
		role.TextColor3 = Color3.fromRGB(255, 220, 120)
		role.Parent = tag
		tag.Parent = head
	end

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	model:SetAttribute("NpcId", spot:GetAttribute("Npc"))
	model.Parent = Workspace
end

function NpcService.Start()
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("Npc") then
			task.spawn(makeNpc, item)
		end
	end
end

return NpcService
