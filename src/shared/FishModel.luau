-- Builds a simple 3D fish out of parts. Used when a player holds up a catch
-- and for the fish that jump out of the water.

local Fish = require(script.Parent.Fish)

local FishModel = {}

-- Each fish gets its own color from its id, tinted by rarity
local function colorFor(fish)
	local hash = 0
	for i = 1, #fish.id do
		hash = (hash * 31 + string.byte(fish.id, i)) % 360
	end
	local base = Color3.fromHSV(hash / 360, 0.55, 0.95)
	local rarity = Fish.RarityById[fish.rarity]
	return base:Lerp(rarity.color, 0.35)
end
FishModel.ColorFor = colorFor

-- Length in studs for a fish of this weight (kg)
function FishModel.LengthFor(weight)
	return math.clamp(1.2 + math.log(weight + 1) * 0.55, 1.2, 6)
end

local function piece(model, name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
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

-- Returns a Model whose PrimaryPart ("Body") faces along -Z (its LookVector)
function FishModel.Build(fishId, weight, shiny)
	local fish = Fish.ById[fishId]
	if not fish then
		return nil
	end
	local length = FishModel.LengthFor(weight or 1)
	local color = colorFor(fish)
	local material = shiny and Enum.Material.Neon or Enum.Material.SmoothPlastic

	local model = Instance.new("Model")
	model.Name = "Fish_" .. fish.id

	local body = piece(model, "Body", Vector3.new(length * 0.35, length * 0.45, length), color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body
	model.PrimaryPart = body

	local tail = piece(model, "Tail", Vector3.new(length * 0.05, length * 0.45, length * 0.32), color:Lerp(Color3.new(0, 0, 0), 0.15), material)
	tail.CFrame = body.CFrame * CFrame.new(0, 0, length * 0.58) * CFrame.Angles(math.rad(45), 0, 0)
	weld(body, tail)

	local fin = piece(model, "Fin", Vector3.new(length * 0.04, length * 0.22, length * 0.3), color:Lerp(Color3.new(1, 1, 1), 0.2), material)
	fin.CFrame = body.CFrame * CFrame.new(0, length * 0.24, 0.05 * length) * CFrame.Angles(math.rad(-20), 0, 0)
	weld(body, fin)

	for _, side in ipairs({ -1, 1 }) do
		local eye = piece(model, "Eye", Vector3.one * length * 0.08, Color3.new(0.05, 0.05, 0.05), Enum.Material.SmoothPlastic)
		eye.Shape = Enum.PartType.Ball
		eye.CFrame = body.CFrame * CFrame.new(side * length * 0.15, length * 0.07, -length * 0.36)
		weld(body, eye)
	end

	if shiny then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 240, 150)
		sparkles.Parent = body
	end
	return model
end

return FishModel
