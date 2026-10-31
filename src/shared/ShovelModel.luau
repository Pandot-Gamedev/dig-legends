-- Builds the shovel the player holds: a round shaft with a D-grip on top, a
-- metal collar with rivets, a shaped blade with a foot step, a center ridge and
-- sharpened edges. Every shovel in Shovels.List has its own look, and the
-- better ones glow, sparkle or smoke.
--
-- ShovelModel.Build(tool, shovel, length) adds the parts to the tool and
-- returns its Handle (the shaft, from +length/2 at the top to -length/2 where
-- the blade starts). Blade parts get the attribute Blade = true and edge/glow
-- parts Trim = true, so shovel skins can recolor them.

local CrownModel = require(script.Parent.CrownModel)

local ShovelModel = {}

local WOOD = Color3.fromRGB(150, 105, 62)
local DARK_WOOD = Color3.fromRGB(95, 60, 35)
local IRON = Color3.fromRGB(85, 88, 95)

-- shape: "pointed" (round-point digging shovel) or "square" (garden spade)
local LOOKS = {
	trowel = {
		shape = "pointed",
		shaft = { WOOD, Enum.Material.Wood },
		grip = { DARK_WOOD, Enum.Material.Wood },
		collar = { IRON, Enum.Material.Metal },
		blade = { Color3.fromRGB(150, 100, 70), Enum.Material.CorrodedMetal },
		edge = { Color3.fromRGB(190, 175, 160), Enum.Material.Metal },
	},
	spade = {
		shape = "square",
		shaft = { WOOD, Enum.Material.Wood },
		grip = { Color3.fromRGB(70, 130, 70), Enum.Material.SmoothPlastic },
		collar = { Color3.fromRGB(60, 100, 60), Enum.Material.Metal },
		blade = { Color3.fromRGB(110, 160, 95), Enum.Material.Metal },
		edge = { Color3.fromRGB(210, 215, 220), Enum.Material.Metal },
	},
	steel = {
		shape = "pointed",
		shaft = { Color3.fromRGB(55, 58, 64), Enum.Material.Metal },
		grip = { Color3.fromRGB(25, 25, 28), Enum.Material.SmoothPlastic },
		collar = { Color3.fromRGB(150, 155, 165), Enum.Material.DiamondPlate },
		blade = { Color3.fromRGB(200, 205, 215), Enum.Material.Metal },
		edge = { Color3.fromRGB(240, 245, 250), Enum.Material.Metal },
		reflectance = 0.15,
	},
	golden = {
		shape = "pointed",
		shaft = { Color3.fromRGB(80, 40, 20), Enum.Material.Wood },
		grip = { Color3.fromRGB(255, 200, 40), Enum.Material.Foil },
		collar = { Color3.fromRGB(255, 200, 40), Enum.Material.Foil },
		blade = { Color3.fromRGB(255, 200, 40), Enum.Material.Foil },
		edge = { Color3.fromRGB(255, 240, 170), Enum.Material.Foil },
		reflectance = 0.2,
		glint = true,
	},
	crystal = {
		shape = "pointed",
		shaft = { Color3.fromRGB(55, 35, 85), Enum.Material.SmoothPlastic },
		grip = { Color3.fromRGB(190, 150, 255), Enum.Material.Neon },
		collar = { Color3.fromRGB(210, 190, 255), Enum.Material.Glass },
		blade = { Color3.fromRGB(170, 120, 255), Enum.Material.Glass, 0.2 },
		edge = { Color3.fromRGB(215, 190, 255), Enum.Material.Neon },
		light = Color3.fromRGB(170, 120, 255),
		shards = true,
		glint = true,
	},
	magma = {
		shape = "pointed",
		shaft = { Color3.fromRGB(40, 34, 34), Enum.Material.Basalt },
		grip = { Color3.fromRGB(255, 100, 30), Enum.Material.Neon },
		collar = { Color3.fromRGB(60, 50, 48), Enum.Material.Basalt },
		blade = { Color3.fromRGB(50, 38, 36), Enum.Material.Basalt },
		edge = { Color3.fromRGB(255, 110, 30), Enum.Material.Neon },
		light = Color3.fromRGB(255, 110, 40),
		embers = true,
	},
}
ShovelModel.Looks = LOOKS

local function part(parent, name, size, style, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.Color = style[1]
	p.Material = style[2]
	p.Transparency = style[3] or 0
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function attach(handle, p, offset)
	p.CFrame = handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	return p
end

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- turns a cylinder (long along X) to stand along Y

function ShovelModel.Build(tool, shovel, length)
	local look = LOOKS[shovel.id] or LOOKS.trowel
	local half = length / 2
	local reflect = look.reflectance or 0

	-- The Handle is the shaft's invisible core, so the hand grips stay the same
	local handle = part(tool, "Handle", Vector3.new(0.3, length, 0.3), look.shaft)
	handle.Transparency = 1
	handle.CFrame = CFrame.new()

	local function add(name, size, style, offset, shape)
		return attach(handle, part(tool, name, size, style, shape), offset)
	end
	local function blade(p)
		p:SetAttribute("Blade", true)
		p.Reflectance = reflect
		return p
	end
	local function trim(p)
		p:SetAttribute("Trim", true)
		return p
	end

	-- Shaft and D-grip
	add("Shaft", Vector3.new(length, 0.26, 0.26), look.shaft, UPRIGHT, Enum.PartType.Cylinder)
	for _, side in ipairs({ -1, 1 }) do
		add("GripPost", Vector3.new(0.1, 0.62, 0.12), look.grip, CFrame.new(side * 0.13, half + 0.27, 0) * CFrame.Angles(0, 0, math.rad(-24 * side)))
	end
	add("GripBar", Vector3.new(0.66, 0.17, 0.17), look.grip, CFrame.new(0, half + 0.56, 0), Enum.PartType.Cylinder)

	-- Collar with two rivets
	add("Collar", Vector3.new(0.62, 0.36, 0.36), look.collar, CFrame.new(0, -half + 0.05, 0) * UPRIGHT, Enum.PartType.Cylinder)
	for _, y in ipairs({ 0.12, -0.12 }) do
		add("Rivet", Vector3.one * 0.09, look.edge, CFrame.new(0, -half + 0.05 + y, -0.17), Enum.PartType.Ball)
	end

	-- Blade: foot step along the top, the flat body, a center ridge and the tip
	local top = -half - 0.22
	local bodyHeight = look.shape == "square" and 1.3 or 0.95
	local width = 1.3
	local bladeColor = look.blade[1]
	local ridgeStyle = { bladeColor:Lerp(Color3.new(0, 0, 0), 0.2), look.blade[2], look.blade[3] }
	blade(add("Step", Vector3.new(width + 0.06, 0.12, 0.26), look.blade, CFrame.new(0, top, 0)))
	blade(add("Blade", Vector3.new(width, bodyHeight, 0.12), look.blade, CFrame.new(0, top - bodyHeight / 2, 0)))
	blade(add("Ridge", Vector3.new(0.2, bodyHeight * 0.8, 0.2), ridgeStyle, CFrame.new(0, top - bodyHeight * 0.4, 0)))
	local bottom = top - bodyHeight

	if look.shape == "square" then
		trim(add("Edge", Vector3.new(width + 0.02, 0.08, 0.14), look.edge, CFrame.new(0, bottom, 0)))
	else
		local tipHeight = 0.6
		-- The tip is a triangle pointing down (the frame is flipped upside down)
		local wedges = CrownModel.Triangle(tool, handle, "Tip", width, tipHeight, 0.11, CFrame.new(0, bottom, 0) * CFrame.Angles(0, 0, math.pi), look.blade[1], look.blade[2])
		for _, wedge in ipairs(wedges) do
			wedge.Transparency = look.blade[3] or 0
			blade(wedge)
		end
		-- Sharpened edges along both sides of the tip
		local slant = math.sqrt((width / 2) ^ 2 + tipHeight ^ 2)
		local angle = math.atan2(width / 2, tipHeight)
		for _, side in ipairs({ -1, 1 }) do
			trim(add("Edge", Vector3.new(0.08, slant, 0.14), look.edge, CFrame.new(side * width / 4, bottom - tipHeight / 2, 0) * CFrame.Angles(0, 0, -side * angle)))
		end
	end

	-- Extras for the fancy shovels
	local bladePart = tool:FindFirstChild("Blade")
	if look.shards then
		-- Three crystals growing out of the collar, the middle one tallest
		for _, shard in ipairs({ { x = -0.2, tilt = 30, size = 0.36 }, { x = 0, tilt = 0, size = 0.5 }, { x = 0.2, tilt = -30, size = 0.36 } }) do
			local offset = CFrame.new(shard.x, -half + 0.3 + shard.size / 2, 0.05) * CFrame.Angles(0, 0, math.rad(shard.tilt)) * CFrame.Angles(0, math.rad(45), 0)
			trim(add("Shard", Vector3.new(0.13, shard.size, 0.13), look.edge, offset))
		end
	end
	if look.light then
		local light = Instance.new("PointLight")
		light.Color = look.light
		light.Range = 7
		light.Brightness = 0.8
		light.Parent = bladePart
	end
	if look.glint then
		local glint = Instance.new("ParticleEmitter")
		glint.Name = "Glint"
		glint.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		glint.Color = ColorSequence.new(look.edge[1])
		glint.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
		glint.Lifetime = NumberRange.new(0.4, 0.7)
		glint.Rate = 4
		glint.Speed = NumberRange.new(0.2, 0.6)
		glint.LightEmission = 1
		glint.Parent = bladePart
	end
	if look.embers then
		local embers = Instance.new("ParticleEmitter")
		embers.Name = "Embers"
		embers.Texture = "rbxasset://textures/particles/fire_main.dds"
		embers.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 60, 20))
		embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		embers.Transparency = NumberSequence.new(0.2, 1)
		embers.Lifetime = NumberRange.new(0.4, 0.8)
		embers.Rate = 8
		embers.Speed = NumberRange.new(0.8, 1.6)
		embers.EmissionDirection = Enum.NormalId.Top
		embers.LightEmission = 1
		embers.Parent = bladePart
	end

	return handle
end

-- Recolors the blade for a shovel skin (color + material from Shop.Cosmetics)
function ShovelModel.ApplySkin(tool, skin)
	for _, p in ipairs(tool:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("Blade") then
			p.Color = skin.color
			p.Material = skin.material
			p.Transparency = 0
		elseif p:IsA("BasePart") and p:GetAttribute("Trim") then
			p.Color = skin.color:Lerp(Color3.new(1, 1, 1), 0.45)
		end
	end
end

return ShovelModel
