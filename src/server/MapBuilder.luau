-- Builds a simple starter world (Dig Town + one island per zone) when the place
-- has no folder called "Map" in Workspace. That means the game is playable the
-- moment you press Play. To use your own scenery later, the game only cares
-- about parts with these attributes:
--   DigSpot     = "backyard"   a patch of dirt you can dig (players stand next to it)
--   ZoneGate    = "desert"     wall that blocks a locked zone
--   ZoneSpawn   = "backyard"   where the teleporter drops players
--   Station     = "Sell" / "Shovels" / "Charms" / "Bounties" / "Leaderboard" / "EventBoard"
--   VipDoor     = true         door only VIP players can walk through
--   Npc         = "Gus"        where a shopkeeper stands (see NpcService)
--   GuideTarget = "DigPatch"   where Grandpa Gus's guide arrow points
--   RushSite    = true         where the Treasure Rush dig site pops up (see RushService)

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Zones = require(Shared.Zones)
local Format = require(Shared.Format)

local MapBuilder = {}

local GROUND_Y = 3

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		if key ~= "Parent" then
			p[key] = value
		end
	end
	p.Parent = props.Parent
	return p
end

local function sign(parentPart, text, face, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = parentPart
	return label
end

local function prompt(parentPart, action, object, distance)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object or ""
	p.MaxActivationDistance = distance or 12
	p.RequiresLineOfSight = false
	p.HoldDuration = 0
	p.Parent = parentPart
	return p
end

local function island(folder, name, center, size, topColor, topMaterial)
	part({
		Name = name .. "Beach",
		Size = Vector3.new(size.X + 16, 6, size.Z + 16),
		Position = Vector3.new(center.X, GROUND_Y - 4, center.Z),
		Material = Enum.Material.Sand,
		Color = Color3.fromRGB(235, 215, 160),
		Parent = folder,
	})
	part({
		Name = name .. "Ground",
		Size = Vector3.new(size.X, 1, size.Z),
		Position = Vector3.new(center.X, GROUND_Y - 0.5, center.Z),
		Material = topMaterial or Enum.Material.Grass,
		Color = topColor,
		Parent = folder,
	})
end

local function tree(folder, position, leafColor, random)
	local height = random:NextNumber(10, 16)
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 2, 2),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(110, 80, 50),
		Parent = folder,
	})
	part({
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * random:NextNumber(8, 12),
		Position = position + Vector3.new(0, height + 2, 0),
		Material = Enum.Material.Grass,
		Color = leafColor,
		CanCollide = false,
		Parent = folder,
	})
end

local function stall(folder, name, position, color, title)
	local model = Instance.new("Model")
	model.Name = name
	local counter = part({
		Name = "Counter",
		Size = Vector3.new(14, 4, 4),
		Position = position + Vector3.new(0, 2, 0),
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(160, 110, 70),
		Parent = model,
	})
	for _, x in ipairs({ -6.5, 6.5 }) do
		part({
			Name = "Post",
			Size = Vector3.new(1, 10, 1),
			Position = position + Vector3.new(x, 5, -3),
			Material = Enum.Material.Wood,
			Color = Color3.fromRGB(110, 80, 50),
			Parent = model,
		})
	end
	part({
		Name = "Roof",
		Size = Vector3.new(16, 1, 8),
		Position = position + Vector3.new(0, 10.5, -1.5),
		Material = Enum.Material.Fabric,
		Color = color,
		Parent = model,
	})
	local board = part({
		Name = "Sign",
		Size = Vector3.new(12, 3, 0.5),
		Position = position + Vector3.new(0, 12.5, 2),
		Color = Color3.fromRGB(60, 40, 30),
		Parent = model,
	})
	sign(board, title, Enum.NormalId.Front)
	sign(board, title, Enum.NormalId.Back)
	model.Parent = folder
	return counter
end

local function board(folder, name, cframe, size, station)
	local p = part({
		Name = name,
		Size = size,
		CFrame = cframe,
		Color = Color3.fromRGB(30, 40, 60),
		Material = Enum.Material.SmoothPlastic,
		Parent = folder,
	})
	p:SetAttribute("Station", station)
	return p
end

local function lamp(folder, position)
	part({ Name = "LampPost", Size = Vector3.new(0.6, 9, 0.6), Position = position + Vector3.new(0, 4.5, 0), Color = Color3.fromRGB(50, 50, 55), Material = Enum.Material.Metal, Parent = folder })
	local bulb = part({ Name = "LampBulb", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.4, Position = position + Vector3.new(0, 9.4, 0), Color = Color3.fromRGB(255, 220, 150), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 210, 150)
	light.Parent = bulb
end

local function crate(folder, position, random)
	local size = random:NextNumber(2.5, 4)
	part({ Name = "Crate", Size = Vector3.one * size, CFrame = CFrame.new(position + Vector3.new(0, size / 2, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(170, 125, 75), Parent = folder })
end

local function barrel(folder, position)
	part({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.5, 2.6, 2.6), CFrame = CFrame.new(position + Vector3.new(0, 1.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 80, 45), Parent = folder })
end

-- A sparkling patch of dirt. Players stand next to it and dig.
local function digSpot(folder, position, zoneId, random)
	local spot = part({
		Name = "DigSpot",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 5, 5),
		CFrame = CFrame.new(position.X, GROUND_Y + 0.1, position.Z) * CFrame.Angles(0, random:NextNumber(0, math.pi), math.rad(90)),
		Material = Enum.Material.Ground,
		Color = Color3.fromRGB(105, 75, 45),
		CanCollide = false,
		Parent = folder,
	})
	spot:SetAttribute("DigSpot", zoneId)
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkle"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 230, 140))
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(0.8, 1.4)
	sparkles.Speed = NumberRange.new(1, 3)
	sparkles.SpreadAngle = Vector2.new(60, 60)
	sparkles.EmissionDirection = Enum.NormalId.Right -- the cylinder lies on its side, so +X points up
	sparkles.Rate = 4
	sparkles.Parent = spot
	return spot
end

-- Places dig spots inside an area, at least 9 studs apart and away from the middle path
local function scatterSpots(folder, center, half, count, zoneId, random, placed)
	local tries = 0
	while count > 0 and tries < 400 do
		tries += 1
		local at = Vector3.new(center.X + random:NextNumber(-half.X, half.X), 0, center.Z + random:NextNumber(-half.Z, half.Z))
		local clear = math.abs(at.Z - center.Z) > 8
		for _, other in ipairs(placed) do
			if (other - at).Magnitude < 9 then
				clear = false
				break
			end
		end
		if clear then
			table.insert(placed, at)
			digSpot(folder, at, zoneId, random)
			count -= 1
		end
	end
end

local function fence(folder, from, to)
	local length = (to - from).Magnitude
	local middle = (from + to) / 2
	local look = CFrame.lookAt(middle, to)
	part({ Name = "FenceRail", Size = Vector3.new(0.4, 0.5, length), CFrame = look * CFrame.new(0, 2.2, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(235, 230, 215), Parent = folder })
	for i = 0, math.floor(length / 4) do
		part({ Name = "FencePost", Size = Vector3.new(0.5, 3, 0.5), CFrame = look * CFrame.new(0, 1.5, -length / 2 + i * length / math.max(1, math.floor(length / 4))), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(235, 230, 215), Parent = folder })
	end
end

local function shed(folder, position, color)
	part({ Name = "Shed", Size = Vector3.new(10, 8, 8), Position = position + Vector3.new(0, 4, 0), Material = Enum.Material.WoodPlanks, Color = color, Parent = folder })
	for _, side in ipairs({ -1, 1 }) do
		local roof = Instance.new("WedgePart")
		roof.Name = "ShedRoof"
		roof.Anchored = true
		roof.Size = Vector3.new(11, 3, 4.5)
		roof.CFrame = CFrame.new(position + Vector3.new(0, 9.5, side * 2.25)) * CFrame.Angles(0, side > 0 and math.pi or 0, 0)
		roof.Material = Enum.Material.Slate
		roof.Color = Color3.fromRGB(120, 60, 50)
		roof.Parent = folder
	end
	part({ Name = "ShedDoor", Size = Vector3.new(3, 6, 0.2), Position = position + Vector3.new(0, 3, 4.05), Material = Enum.Material.Wood, Color = Color3.fromRGB(90, 60, 40), Parent = folder })
end

local function gnome(folder, position, hatColor)
	part({ Name = "GnomeBody", Size = Vector3.new(1.2, 1.4, 1.2), Position = position + Vector3.new(0, 0.7, 0), Color = Color3.fromRGB(60, 90, 200), Parent = folder })
	part({ Name = "GnomeHead", Shape = Enum.PartType.Ball, Size = Vector3.one, Position = position + Vector3.new(0, 1.9, 0), Color = Color3.fromRGB(234, 184, 146), Parent = folder })
	part({ Name = "GnomeBeard", Size = Vector3.new(0.8, 0.6, 0.3), Position = position + Vector3.new(0, 1.55, -0.5), Color = Color3.fromRGB(245, 245, 245), Parent = folder })
	part({ Name = "GnomeHat", Size = Vector3.new(0.9, 0.6, 0.9), Position = position + Vector3.new(0, 2.6, 0), Color = hatColor, Parent = folder })
	part({ Name = "GnomeHatTip", Size = Vector3.new(0.45, 0.6, 0.45), Position = position + Vector3.new(0, 3.2, 0), Color = hatColor, Parent = folder })
end

local function rock(folder, position, color, random)
	local size = random:NextNumber(2, 5)
	part({ Name = "Rock", Size = Vector3.new(size, size * 0.7, size * 0.9), CFrame = CFrame.new(position + Vector3.new(0, size * 0.3, 0)) * CFrame.Angles(random:NextNumber(-0.3, 0.3), random:NextNumber(0, math.pi), random:NextNumber(-0.3, 0.3)), Material = Enum.Material.Slate, Color = color, Parent = folder })
end

local function lighthouse(folder, position)
	for i = 0, 4 do
		part({
			Name = "LighthouseBand",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(8, 10 - i * 0.8, 10 - i * 0.8),
			CFrame = CFrame.new(position + Vector3.new(0, 4 + i * 8, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = i % 2 == 0 and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(200, 50, 50),
			Parent = folder,
		})
	end
	local lamp = part({ Name = "LighthouseLamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 5, Position = position + Vector3.new(0, 42.5, 0), Color = Color3.fromRGB(255, 240, 170), Material = Enum.Material.Neon, Parent = folder })
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 2
	light.Parent = lamp
	part({ Name = "LighthouseRoof", Size = Vector3.new(7, 1, 7), Position = position + Vector3.new(0, 45.5, 0), Color = Color3.fromRGB(60, 60, 70), Parent = folder })
end

-- True when a spot of this size at "at" keeps clear of the dig spots
local function clearOf(placed, at, radius)
	for _, spot in ipairs(placed) do
		if (Vector3.new(at.X, 0, at.Z) - Vector3.new(spot.X, 0, spot.Z)).Magnitude < radius then
			return false
		end
	end
	return true
end

local function cactus(folder, position, random)
	local height = random:NextNumber(6, 10)
	local green = Color3.fromRGB(70, 140, 70)
	part({ Name = "Cactus", Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, 1.8, 1.8), CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Grass, Color = green, Parent = folder })
	for _, side in ipairs({ -1, 1 }) do
		local armY = random:NextNumber(height * 0.4, height * 0.7)
		part({ Name = "CactusArm", Size = Vector3.new(2, 1.2, 1.2), Position = position + Vector3.new(side * 1.4, armY, 0), Material = Enum.Material.Grass, Color = green, Parent = folder })
		part({ Name = "CactusArm", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 1.2, 1.2), CFrame = CFrame.new(position + Vector3.new(side * 2.2, armY + 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Grass, Color = green, Parent = folder })
	end
end

local function pyramid(folder, position, base)
	local steps = 5
	for i = 0, steps - 1 do
		local width = base * (1 - i / steps)
		part({ Name = "PyramidStep", Size = Vector3.new(width, 2.4, width), Position = position + Vector3.new(0, 1.2 + i * 2.4, 0), Material = Enum.Material.Sandstone, Color = Color3.fromRGB(225, 190, 120), Parent = folder })
	end
	part({ Name = "PyramidTop", Size = Vector3.new(2, 1.5, 2), Position = position + Vector3.new(0, steps * 2.4 + 0.75, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 210, 80), Parent = folder })
end

local function crystal(folder, position, color, random)
	local first
	for _ = 1, random:NextInteger(3, 5) do
		local height = random:NextNumber(3, 8)
		local width = random:NextNumber(0.8, 1.6)
		local piece = part({
			Name = "Crystal",
			Size = Vector3.new(width, height, width),
			CFrame = CFrame.new(position + Vector3.new(random:NextNumber(-1.5, 1.5), height * 0.4, random:NextNumber(-1.5, 1.5))) * CFrame.Angles(random:NextNumber(-0.5, 0.5), random:NextNumber(0, math.pi), random:NextNumber(-0.5, 0.5)),
			Material = Enum.Material.Glass,
			Color = color,
			Transparency = 0.2,
			Parent = folder,
		})
		first = first or piece
	end
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Range = 14
	glow.Brightness = 1.5
	glow.Parent = first
end

local function column(folder, position, height, broken, random)
	local marble = Color3.fromRGB(225, 225, 215)
	part({ Name = "ColumnBase", Size = Vector3.new(3.2, 0.8, 3.2), Position = position + Vector3.new(0, 0.4, 0), Material = Enum.Material.Marble, Color = marble, Parent = folder })
	part({ Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, 2.2, 2.2), CFrame = CFrame.new(position + Vector3.new(0, 0.8 + height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Marble, Color = marble, Parent = folder })
	if not broken then
		part({ Name = "ColumnTop", Size = Vector3.new(3.2, 0.8, 3.2), Position = position + Vector3.new(0, 1.2 + height, 0), Material = Enum.Material.Marble, Color = marble, Parent = folder })
	else
		part({ Name = "ColumnPiece", Shape = Enum.PartType.Cylinder, Size = Vector3.new(random:NextNumber(3, 5), 2.2, 2.2), CFrame = CFrame.new(position + Vector3.new(random:NextNumber(2.5, 4), 1.1, random:NextNumber(-2, 2))) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0), Material = Enum.Material.Marble, Color = marble, Parent = folder })
	end
end

-- An archway over the path where the bridge reaches an island
local function arch(folder, position, color, material)
	for _, z in ipairs({ -6, 6 }) do
		part({ Name = "ArchPillar", Size = Vector3.new(3, 14, 3), Position = position + Vector3.new(0, 7, z), Material = material, Color = color, Parent = folder })
	end
	part({ Name = "ArchTop", Size = Vector3.new(4, 3, 17), Position = position + Vector3.new(0, 15.5, 0), Material = material, Color = color, Parent = folder })
end

local function lavaPool(folder, position, size)
	local pool = part({ Name = "LavaPool", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, size, size), CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 100, 20), CanCollide = false, Parent = folder })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 40)
	light.Range = size * 1.5
	light.Brightness = 2
	light.Parent = pool
end

-- A smoking volcano out in the sea behind the last island
local function volcanoMountain(folder, position)
	for i = 0, 5 do
		local width = 70 - i * 10
		part({ Name = "VolcanoSlope", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, width, width), CFrame = CFrame.new(position + Vector3.new(0, -4 + i * 8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Basalt, Color = Color3.fromRGB(55, 45, 45), Parent = folder })
	end
	local crater = part({ Name = "VolcanoCrater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 16, 16), CFrame = CFrame.new(position + Vector3.new(0, 40.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 90, 20), Parent = folder })
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(70, 60, 60))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 25) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(6, 9)
	smoke.Speed = NumberRange.new(8, 14)
	smoke.Rate = 3
	smoke.EmissionDirection = Enum.NormalId.Right -- the cylinder lies on its side, so +X points up
	smoke.Parent = crater
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 110, 40)
	light.Range = 40
	light.Brightness = 3
	light.Parent = crater
end

-- Props that give each zone island its own look, kept away from the dig spots, trees and rocks in placed
local function decorateZone(folder, zoneId, centerX, placed, random)
	local function each(count, radius, place)
		local tries = 0
		while count > 0 and tries < 200 do
			tries += 1
			local at = Vector3.new(centerX + random:NextNumber(-42, 42), GROUND_Y, random:NextNumber(-42, 42))
			if math.abs(at.Z) > 9 and clearOf(placed, at, radius) then
				place(at)
				table.insert(placed, Vector3.new(at.X, 0, at.Z))
				count -= 1
			end
		end
	end
	local entrance = Vector3.new(centerX - 45, GROUND_Y, 0) -- the island's west edge, clear of the dig spots
	if zoneId == "backyard" then
		shed(folder, Vector3.new(centerX + 30, GROUND_Y, -36), Color3.fromRGB(170, 70, 60))
		gnome(folder, Vector3.new(centerX - 20, GROUND_Y, 14), Color3.fromRGB(60, 160, 60))
	elseif zoneId == "desert" then
		each(1, 12, function(at)
			pyramid(folder, at, 14)
		end)
		each(6, 5, function(at)
			cactus(folder, at, random)
		end)
	elseif zoneId == "caves" then
		arch(folder, entrance, Color3.fromRGB(80, 70, 100), Enum.Material.Slate)
		local colors = { Color3.fromRGB(180, 120, 255), Color3.fromRGB(110, 230, 255), Color3.fromRGB(255, 130, 220) }
		each(7, 6, function(at)
			crystal(folder, at, colors[random:NextInteger(1, #colors)], random)
		end)
	elseif zoneId == "ruins" then
		arch(folder, entrance, Color3.fromRGB(215, 215, 200), Enum.Material.Marble)
		each(7, 6, function(at)
			column(folder, at, random:NextNumber(5, 12), random:NextNumber() < 0.5, random)
		end)
	elseif zoneId == "volcano" then
		each(5, 7, function(at)
			lavaPool(folder, at, random:NextNumber(4, 7))
		end)
		volcanoMountain(folder, Vector3.new(centerX + 95, GROUND_Y, 0))
	end
end

-- Where a shopkeeper stands. By default they face +Z (the front of the stalls).
local function npcSpot(folder, npc, position, turn)
	local spot = part({ Name = npc .. "Spot", Size = Vector3.new(2, 1, 2), CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, turn or math.pi, 0), Transparency = 1, CanCollide = false, CanQuery = false, Parent = folder })
	spot:SetAttribute("Npc", npc)
end

function MapBuilder.Build()
	if Workspace:FindFirstChild("Map") then
		return -- the creator made their own map
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = map
	local spots = Instance.new("Folder")
	spots.Name = "DigSpots"
	spots.Parent = map

	local random = Random.new(42)

	-- Ocean
	local terrain = Workspace.Terrain
	terrain:FillBlock(CFrame.new(500, -22, 0), Vector3.new(1700, 8, 700), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(500, -9, 0), Vector3.new(1700, 18, 700), Enum.Material.Water)
	terrain.WaterColor = Color3.fromRGB(40, 150, 200)
	terrain.WaterTransparency = 0.6
	terrain.WaterWaveSize = 0.15

	-- Dig Town (the hub island)
	island(scenery, "Hub", Vector3.new(0, 0, 0), Vector3.new(140, 0, 140), Color3.fromRGB(110, 190, 90))
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "HubSpawn"
	spawnLocation.Anchored = true
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = Vector3.new(0, GROUND_Y + 0.5, 30)
	spawnLocation.Material = Enum.Material.Wood
	spawnLocation.Color = Color3.fromRGB(190, 150, 100)
	spawnLocation.Duration = 0
	spawnLocation.Parent = map

	local hubSpawn = part({ Name = "HubTeleport", Size = Vector3.new(4, 1, 4), Position = Vector3.new(0, GROUND_Y + 0.5, 20), Transparency = 1, CanCollide = false, Parent = map })
	hubSpawn:SetAttribute("ZoneSpawn", "hub")

	local sellCounter = stall(scenery, "TradingPost", Vector3.new(-35, GROUND_Y, -25), Color3.fromRGB(200, 60, 80), "TRADING POST")
	sellCounter:SetAttribute("Station", "Sell")
	prompt(sellCounter, "Sell finds", "Trading Post")

	local shovelCounter = stall(scenery, "ShovelShop", Vector3.new(35, GROUND_Y, -25), Color3.fromRGB(230, 150, 40), "SHOVEL SHOP")
	shovelCounter:SetAttribute("Station", "Shovels")
	prompt(shovelCounter, "Browse shovels", "Shovel Shop")

	local charmCounter = stall(scenery, "CharmCart", Vector3.new(-35, GROUND_Y, 8), Color3.fromRGB(90, 180, 90), "CHARM CART")
	charmCounter:SetAttribute("Station", "Charms")
	prompt(charmCounter, "Buy & make charms", "Charm Cart")

	local bountyBoard = board(map, "BountyBoard", CFrame.new(-30, GROUND_Y + 6, 48), Vector3.new(14, 10, 1), "Bounties")
	bountyBoard.Color = Color3.fromRGB(120, 85, 55)
	bountyBoard.Material = Enum.Material.WoodPlanks
	sign(bountyBoard, "GRANDPA GUS'S\nBOUNTIES", Enum.NormalId.Front, Color3.fromRGB(255, 230, 160))
	sign(bountyBoard, "GRANDPA GUS'S\nBOUNTIES", Enum.NormalId.Back, Color3.fromRGB(255, 230, 160))
	prompt(bountyBoard, "Check bounties", "Bounty Board")

	board(map, "GlobalBoard", CFrame.new(0, GROUND_Y + 10, -60), Vector3.new(28, 18, 1), "Leaderboard")
	board(map, "EventBoard", CFrame.new(-55, GROUND_Y + 7, 25) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(20, 12, 1), "EventBoard")

	-- The starter patch: a fenced garden in town with Backyard dig spots, so new players can dig right away
	local patchCenter = Vector3.new(40, 0, 44)
	local corners = {
		Vector3.new(26, GROUND_Y, 31),
		Vector3.new(56, GROUND_Y, 31),
		Vector3.new(56, GROUND_Y, 58),
		Vector3.new(26, GROUND_Y, 58),
	}
	fence(scenery, corners[2], corners[3])
	fence(scenery, corners[3], corners[4])
	fence(scenery, corners[4], corners[1])
	fence(scenery, corners[1], Vector3.new(36, GROUND_Y, 31)) -- a gap in the fence is the way in
	fence(scenery, Vector3.new(46, GROUND_Y, 31), corners[2])
	part({ Name = "PatchSoil", Size = Vector3.new(28, 0.2, 25), Position = patchCenter + Vector3.new(0, GROUND_Y + 0.05, 0.5), Material = Enum.Material.Ground, Color = Color3.fromRGB(130, 100, 65), CanCollide = false, Parent = scenery })
	local patchSign = part({ Name = "PatchSign", Size = Vector3.new(10, 2.4, 0.4), Position = Vector3.new(41, GROUND_Y + 7, 30.5), Color = Color3.fromRGB(60, 40, 30), CanCollide = false, Parent = scenery })
	for _, x in ipairs({ 36, 46 }) do
		part({ Name = "SignPole", Size = Vector3.new(0.4, 7, 0.4), Position = Vector3.new(x, GROUND_Y + 3.5, 30.5), Color = Color3.fromRGB(100, 70, 45), Parent = scenery })
	end
	sign(patchSign, "STARTER PATCH", Enum.NormalId.Front, Color3.fromRGB(255, 230, 160))
	sign(patchSign, "STARTER PATCH", Enum.NormalId.Back, Color3.fromRGB(255, 230, 160))
	local patchTarget = part({ Name = "PatchTarget", Size = Vector3.new(4, 1, 4), Position = patchCenter + Vector3.new(0, GROUND_Y + 0.5, 0), Transparency = 1, CanCollide = false, CanQuery = false, Parent = map })
	patchTarget:SetAttribute("GuideTarget", "DigPatch")
	local placed = {}
	for _, at in ipairs({ Vector3.new(32, 0, 38), Vector3.new(44, 0, 37), Vector3.new(51, 0, 45), Vector3.new(38, 0, 51), Vector3.new(30, 0, 50), Vector3.new(48, 0, 53) }) do
		table.insert(placed, at)
		digSpot(spots, at, Zones.Default, random)
	end

	lighthouse(scenery, Vector3.new(-62, GROUND_Y, -62))

	-- The open square between the shops and the starter patch, where Treasure Rushes pop up
	local rushSite = part({ Name = "RushSite", Size = Vector3.new(4, 1, 4), Position = Vector3.new(20, GROUND_Y, 8), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = map })
	rushSite:SetAttribute("RushSite", true)

	npcSpot(scenery, "Ruby", Vector3.new(-35, GROUND_Y, -27.6))
	npcSpot(scenery, "Digby", Vector3.new(35, GROUND_Y, -27.6))
	npcSpot(scenery, "Clover", Vector3.new(-35, GROUND_Y, 5.4))
	npcSpot(scenery, "Gus", Vector3.new(-20, GROUND_Y, 46), math.rad(-50))

	-- Paths, lamps and clutter so the town feels lived in
	for _, path in ipairs({
		{ Vector3.new(0, 0, -15), Vector3.new(8, 0.2, 90) },
		{ Vector3.new(0, 0, -10), Vector3.new(110, 0.2, 8) },
		{ Vector3.new(20, 0, 26), Vector3.new(40, 0.2, 6) },
	}) do
		part({ Name = "Path", Size = path[2], Position = path[1] + Vector3.new(0, GROUND_Y + 0.05, 0), Material = Enum.Material.Pebble, Color = Color3.fromRGB(200, 185, 150), CanCollide = false, Parent = scenery })
	end
	for _, at in ipairs({ Vector3.new(6, 0, 10), Vector3.new(-6, 0, -30), Vector3.new(-20, 0, -14), Vector3.new(20, 0, -14), Vector3.new(50, 0, -5), Vector3.new(-50, 0, -5), Vector3.new(22, 0, 32) }) do
		lamp(scenery, at + Vector3.new(0, GROUND_Y, 0))
	end
	for _, at in ipairs({ Vector3.new(-46, 0, -22), Vector3.new(-44, 0, -18), Vector3.new(46, 0, -18), Vector3.new(-46, 0, 12) }) do
		crate(scenery, at + Vector3.new(0, GROUND_Y, 0), random)
	end
	for _, at in ipairs({ Vector3.new(-25, 0, -22), Vector3.new(26, 0, -14), Vector3.new(-24, 0, 12), Vector3.new(46, 0, -22) }) do
		barrel(scenery, at + Vector3.new(0, GROUND_Y, 0))
	end
	gnome(scenery, Vector3.new(58, GROUND_Y, 34), Color3.fromRGB(210, 50, 50))

	-- VIP lounge (cosmetic perk: a nice private spot by town, no extra dig spots)
	part({ Name = "VipLounge", Size = Vector3.new(30, 1, 44), Position = Vector3.new(-10, GROUND_Y - 0.5, 98), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(200, 160, 60), Parent = scenery })
	for _, x in ipairs({ -20, 0 }) do
		part({ Name = "VipBench", Size = Vector3.new(8, 1, 2.5), Position = Vector3.new(x, GROUND_Y + 1, 108), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 80, 45), Parent = scenery })
	end
	part({ Name = "VipFountain", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 8, 8), CFrame = CFrame.new(-10, GROUND_Y + 1, 96) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Marble, Color = Color3.fromRGB(240, 235, 220), Parent = scenery })
	lamp(scenery, Vector3.new(2, GROUND_Y, 112))
	lamp(scenery, Vector3.new(-22, GROUND_Y, 112))
	local vipDoor = part({ Name = "VipDoor", Size = Vector3.new(32, 12, 1), Position = Vector3.new(-10, GROUND_Y + 6, 77), Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Neon, Transparency = 0.5, Parent = map })
	vipDoor:SetAttribute("VipDoor", true)
	sign(vipDoor, "VIP LOUNGE", Enum.NormalId.Front, Color3.fromRGB(255, 240, 180))
	sign(vipDoor, "VIP LOUNGE", Enum.NormalId.Back, Color3.fromRGB(255, 240, 180))
	for _, x in ipairs({ -25.5, 5.5 }) do
		part({ Name = "VipWall", Size = Vector3.new(1, 12, 42), Position = Vector3.new(x, GROUND_Y + 6, 98.5), Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Neon, Transparency = 0.7, Parent = map })
	end

	for _ = 1, 14 do
		local x = random:NextNumber(-64, 64)
		local z = random:NextNumber(-64, 64)
		local clear = math.abs(z) > 8 and math.abs(x) > 12 and not (x < -45 and z < -45) and not (x > 20 and z > 24)
		if (math.abs(x) > 52 or math.abs(z) > 52) and clear then
			tree(scenery, Vector3.new(x, GROUND_Y, z), Color3.fromRGB(60, 160, 60), random)
		end
	end

	-- One island per zone, in a row going east
	local looks = {
		backyard = { ground = Color3.fromRGB(120, 190, 90), material = Enum.Material.Grass, leaves = Color3.fromRGB(70, 170, 60), rock = Color3.fromRGB(140, 140, 140), trees = 6 },
		desert = { ground = Color3.fromRGB(235, 200, 130), material = Enum.Material.Sand, leaves = Color3.fromRGB(120, 170, 70), rock = Color3.fromRGB(200, 140, 90), trees = 2 },
		caves = { ground = Color3.fromRGB(90, 80, 110), material = Enum.Material.Slate, leaves = Color3.fromRGB(170, 120, 255), rock = Color3.fromRGB(150, 110, 220), trees = 0 },
		ruins = { ground = Color3.fromRGB(120, 150, 130), material = Enum.Material.Cobblestone, leaves = Color3.fromRGB(60, 130, 90), rock = Color3.fromRGB(170, 170, 150), trees = 3 },
		volcano = { ground = Color3.fromRGB(60, 50, 50), material = Enum.Material.Basalt, leaves = Color3.fromRGB(255, 120, 40), rock = Color3.fromRGB(40, 35, 35), trees = 0 },
	}
	local previousEdge = 78
	for index, zone in ipairs(Zones.List) do
		local centerX = 230 * index
		local look = looks[zone.id] or looks.backyard
		island(scenery, zone.name, Vector3.new(centerX, 0, 0), Vector3.new(90, 0, 90), look.ground, look.material)

		local zonePlaced = {}
		scatterSpots(spots, Vector3.new(centerX, 0, 0), Vector3.new(38, 0, 38), 12, zone.id, random, zonePlaced)

		for _ = 1, look.trees do
			local x = centerX + random:NextNumber(-38, 38)
			local z = random:NextNumber(-38, 38)
			local clear = math.abs(z) > 12
			for _, at in ipairs(zonePlaced) do
				if (Vector3.new(x, 0, z) - at).Magnitude < 7 then
					clear = false
				end
			end
			if clear then
				tree(scenery, Vector3.new(x, GROUND_Y, z), look.leaves, random)
				table.insert(zonePlaced, Vector3.new(x, 0, z))
			end
		end
		for _ = 1, 5 do
			local at = Vector3.new(centerX + random:NextNumber(-42, 42), GROUND_Y, random:NextNumber(-42, 42))
			local clear = math.abs(at.Z) > 10
			for _, spot in ipairs(zonePlaced) do
				if (Vector3.new(at.X, 0, at.Z) - spot).Magnitude < 8 then
					clear = false
				end
			end
			if clear then
				rock(scenery, at, look.rock, random)
				table.insert(zonePlaced, Vector3.new(at.X, 0, at.Z))
			end
		end
		decorateZone(scenery, zone.id, centerX, zonePlaced, random)

		local zoneSign = part({ Name = "ZoneSign", Size = Vector3.new(24, 6, 1), Position = Vector3.new(centerX, GROUND_Y + 14, -40), Color = Color3.fromRGB(30, 40, 60), Parent = scenery })
		sign(zoneSign, zone.name, Enum.NormalId.Front, zone.color)
		sign(zoneSign, zone.name, Enum.NormalId.Back, zone.color)

		-- Bridge from the previous island
		local islandEdge = centerX - 53
		local bridgeLength = islandEdge - previousEdge
		part({
			Name = "Bridge",
			Size = Vector3.new(bridgeLength, 1, 10),
			Position = Vector3.new(previousEdge + bridgeLength / 2, GROUND_Y - 0.5, 0),
			Material = Enum.Material.WoodPlanks,
			Color = Color3.fromRGB(150, 110, 70),
			Parent = scenery,
		})
		previousEdge = centerX + 53

		if zone.price > 0 then
			local gate = part({
				Name = zone.name .. "Gate",
				Size = Vector3.new(2, 14, 12),
				Position = Vector3.new(islandEdge - bridgeLength + 6, GROUND_Y + 7, 0),
				Color = zone.color,
				Material = Enum.Material.ForceField,
				Parent = map,
			})
			gate:SetAttribute("ZoneGate", zone.id)
			local text = string.format("%s\nLevel %d\n%s coins", zone.name, zone.level, Format.Number(zone.price))
			sign(gate, text, Enum.NormalId.Left)
			sign(gate, text, Enum.NormalId.Right)
			prompt(gate, "Unlock", zone.name, 14)
		end

		local zoneSpawn = part({ Name = zone.name .. "Spawn", Size = Vector3.new(4, 1, 4), Position = Vector3.new(centerX, GROUND_Y + 0.5, 0), Transparency = 1, CanCollide = false, Parent = map })
		zoneSpawn:SetAttribute("ZoneSpawn", zone.id)
	end

	map.Parent = Workspace
end

return MapBuilder
