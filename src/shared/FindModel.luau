-- Builds a simple 3D find out of parts. Used when a player holds up what they
-- dug up.

local Finds = require(script.Parent.Finds)

local FindModel = {}

-- Each find gets its own color from its id (unless it sets one), tinted by rarity
local function colorFor(find)
	if find.color then
		return find.color
	end
	local hash = 0
	for i = 1, #find.id do
		hash = (hash * 31 + string.byte(find.id, i)) % 360
	end
	local base = Color3.fromHSV(hash / 360, 0.55, 0.95)
	local rarity = Finds.RarityById[find.rarity]
	return base:Lerp(rarity.color, 0.35)
end
FindModel.ColorFor = colorFor

-- Size in studs for a find of this weight (kg)
function FindModel.SizeFor(weight)
	return math.clamp(1 + math.log(weight + 1) * 0.8, 1, 4)
end

local function piece(model, name, size, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.CastShadow = false
	p.Parent = model
	return p
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

-- Adds a part placed relative to the body and welds it on
local function extra(model, body, name, size, offset, color, material, shape)
	local p = piece(model, name, size, color, material, shape)
	p.CFrame = body.CFrame * offset
	weld(body, p)
	return p
end

local BUILDERS = {}

function BUILDERS.coin(model, s, color, material)
	return piece(model, "Body", Vector3.new(s * 0.15, s * 0.8, s * 0.8), color, material, Enum.PartType.Cylinder)
end

function BUILDERS.ring(model, s, color, material)
	local body = piece(model, "Body", Vector3.new(s * 0.12, s * 0.7, s * 0.7), color, material, Enum.PartType.Cylinder)
	extra(model, body, "Gem", Vector3.one * s * 0.25, CFrame.new(0, s * 0.38, 0), Color3.fromRGB(120, 200, 255), Enum.Material.Neon, Enum.PartType.Ball)
	return body
end

function BUILDERS.orb(model, s, color, material)
	return piece(model, "Body", Vector3.one * s * 0.8, color, material, Enum.PartType.Ball)
end

function BUILDERS.egg(model, s, color, material)
	local body = piece(model, "Body", Vector3.new(s * 0.7, s, s * 0.7), color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body
	return body
end

function BUILDERS.shell(model, s, color, material)
	local body = piece(model, "Body", Vector3.new(s * 0.9, s * 0.35, s * 0.7), color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body
	for i = -1, 1 do
		extra(model, body, "Ridge", Vector3.new(s * 0.08, s * 0.3, s * 0.72), CFrame.new(i * s * 0.22, s * 0.04, 0), color:Lerp(Color3.new(0, 0, 0), 0.2), material)
	end
	return body
end

function BUILDERS.gem(model, s, color)
	local body = piece(model, "Body", Vector3.one * s * 0.55, color, Enum.Material.Glass)
	body.Transparency = 0.15
	body.CFrame = CFrame.Angles(math.rad(45), 0, math.rad(45))
	extra(model, body, "Glow", Vector3.one * s * 0.3, CFrame.new(), color:Lerp(Color3.new(1, 1, 1), 0.4), Enum.Material.Neon)
	return body
end

function BUILDERS.bone(model, s, color, material)
	local body = piece(model, "Body", Vector3.new(s, s * 0.2, s * 0.2), color, material, Enum.PartType.Cylinder)
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			extra(model, body, "Knob", Vector3.one * s * 0.24, CFrame.new(side * s * 0.5, 0, z * s * 0.1), color, material, Enum.PartType.Ball)
		end
	end
	return body
end

function BUILDERS.tooth(model, s, color, material)
	local body = piece(model, "Body", Vector3.new(s * 0.35, s * 0.5, s * 0.35), color, material)
	local tip = Instance.new("WedgePart")
	tip.Name = "Tip"
	tip.Size = Vector3.new(s * 0.35, s * 0.5, s * 0.35)
	tip.Color = color
	tip.Material = material
	tip.CanCollide = false
	tip.CanQuery = false
	tip.CanTouch = false
	tip.Massless = true
	tip.CastShadow = false
	tip.CFrame = body.CFrame * CFrame.new(0, s * 0.5, 0)
	tip.Parent = model
	weld(body, tip)
	return body
end

function BUILDERS.relic(model, s, color, material)
	local body = piece(model, "Body", Vector3.new(s * 0.9, s * 0.6, s * 0.6), color, material)
	extra(model, body, "Band", Vector3.new(s * 0.94, s * 0.12, s * 0.64), CFrame.new(0, s * 0.1, 0), color:Lerp(Color3.fromRGB(255, 210, 80), 0.6), Enum.Material.Metal)
	return body
end

-- Returns a Model whose PrimaryPart is "Body"
function FindModel.Build(findId, weight, shiny)
	local find = Finds.ById[findId]
	if not find then
		return nil
	end
	local size = FindModel.SizeFor(weight or 1)
	local color = colorFor(find)
	local material = shiny and Enum.Material.Neon or Enum.Material.SmoothPlastic

	local model = Instance.new("Model")
	model.Name = "Find_" .. find.id
	local build = BUILDERS[find.shape] or BUILDERS.relic
	local body = build(model, size, color, material)
	model.PrimaryPart = body

	if shiny then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 240, 150)
		sparkles.Parent = body
	end
	return model
end

return FindModel
