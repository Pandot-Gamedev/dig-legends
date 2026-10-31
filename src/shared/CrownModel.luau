-- Builds a real-looking crown out of parts: a gold band with a rim, tall and
-- short points with pearls, gems on the front, a red velvet cap and a little
-- cross on top. Used for the VIP crown and the Sunken King's Crown find.
--
-- CrownModel.AddTo(model, radius, options) adds the crown parts to a model and
-- returns the invisible center part ("Core" unless options.coreName says
-- otherwise). Every other part is welded to that center, so moving or welding
-- the center moves the whole crown. The crown stands upright along the
-- center's +Y, with the band centered on it.

local CrownModel = {}

local SEGMENTS = 8 -- sides of the band (each one gets a point)
local BASE_RADIUS = 0.55 -- the sizes below are for this radius and scale with it

local GEM_COLORS = {
	Color3.fromRGB(220, 30, 60), -- ruby
	Color3.fromRGB(40, 110, 255), -- sapphire
	Color3.fromRGB(30, 200, 110), -- emerald
	Color3.fromRGB(170, 60, 255), -- amethyst
}

local function newPart(className, model, name, size, color, material)
	local p = Instance.new(className)
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
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function attach(core, p, offset)
	p.CFrame = core.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = core
	weld.Part1 = p
	weld.Parent = p
	return p
end

-- A flat triangle (two wedges) standing on its base. `at` is the middle of the
-- base, the triangle rises along at's +Y and its flat faces look along at's Z.
function CrownModel.Triangle(model, core, name, baseWidth, height, thickness, at, color, material)
	-- A WedgePart turned a quarter turn about Y is a right triangle in X/Y with
	-- its upright side on +X (or -X when turned the other way).
	local halves = {
		{ x = -baseWidth / 4, turn = CFrame.Angles(0, math.rad(90), 0) },
		{ x = baseWidth / 4, turn = CFrame.Angles(0, math.rad(-90), 0) },
	}
	local wedges = {}
	for _, half in ipairs(halves) do
		local wedge = newPart("WedgePart", model, name, Vector3.new(thickness, height, baseWidth / 2), color, material)
		attach(core, wedge, at * CFrame.new(half.x, height / 2, 0) * half.turn)
		table.insert(wedges, wedge)
	end
	return wedges
end

local function defaults(options)
	options = options or {}
	return {
		gold = options.color or Color3.fromRGB(255, 196, 45),
		material = options.material or Enum.Material.Metal,
		coreName = options.coreName or "Core",
		velvet = options.velvet ~= false,
	}
end

function CrownModel.AddTo(model, radius, options)
	local o = defaults(options)
	local k = radius / BASE_RADIUS
	local gold = o.gold
	local darkGold = gold:Lerp(Color3.new(0, 0, 0), 0.25)

	local core = newPart("Part", model, o.coreName, Vector3.one * 0.2 * k, gold, o.material)
	core.Transparency = 1

	local bandHeight = 0.42 * k
	local thickness = 0.1 * k
	local side = 2 * radius * math.tan(math.pi / SEGMENTS) -- width of one side of the band

	for i = 0, SEGMENTS - 1 do
		local around = CFrame.Angles(0, i * 2 * math.pi / SEGMENTS, 0)
		local tall = i % 2 == 0

		-- Band side and the thicker rim along its bottom edge
		attach(core, newPart("Part", model, "Band", Vector3.new(side * 1.04, bandHeight, thickness), gold, o.material), around * CFrame.new(0, 0, -radius))
		attach(
			core,
			newPart("Part", model, "Rim", Vector3.new(side * 1.12, bandHeight * 0.28, thickness * 1.8), darkGold, o.material),
			around * CFrame.new(0, -bandHeight * 0.42, -radius)
		)

		-- A point on top of every side: tall ones with a pearl, short ones with a bead
		local pointHeight = (tall and 0.62 or 0.32) * k
		local top = around * CFrame.new(0, bandHeight / 2, -radius)
		CrownModel.Triangle(model, core, "Point", side * 0.98, pointHeight, thickness * 0.9, top, gold, o.material)
		local pearlSize = (tall and 0.17 or 0.11) * k
		attach(
			core,
			newPart("Part", model, tall and "Pearl" or "Bead", Vector3.one * pearlSize, tall and Color3.fromRGB(250, 245, 235) or gold, tall and Enum.Material.SmoothPlastic or o.material),
			top * CFrame.new(0, pointHeight + pearlSize * 0.25, 0)
		).Shape = Enum.PartType.Ball

		-- A gem on the band below each tall point
		if tall then
			local gem = newPart("Part", model, "Gem", Vector3.new(0.17, 0.17, 0.08) * k, GEM_COLORS[(i / 2) % #GEM_COLORS + 1], Enum.Material.Neon)
			attach(core, gem, around * CFrame.new(0, bandHeight * 0.05, -radius - thickness * 0.55) * CFrame.Angles(0, 0, math.rad(45)))
		end
	end

	if o.velvet then
		-- Red velvet cap filling the band, with a gold orb and cross on top
		local capHeight = bandHeight * 1.9
		local cap = newPart("Part", model, "Velvet", Vector3.new(radius * 1.9, capHeight, radius * 1.9), Color3.fromRGB(150, 20, 45), Enum.Material.Fabric)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = cap
		attach(core, cap, CFrame.new(0, bandHeight * 0.05, 0))
		local orbY = bandHeight * 0.05 + capHeight / 2 + 0.06 * k
		local orb = newPart("Part", model, "Orb", Vector3.one * 0.18 * k, gold, o.material)
		orb.Shape = Enum.PartType.Ball
		attach(core, orb, CFrame.new(0, orbY, 0))
		attach(core, newPart("Part", model, "Cross", Vector3.new(0.06, 0.26, 0.06) * k, gold, o.material), CFrame.new(0, orbY + 0.2 * k, 0))
		attach(core, newPart("Part", model, "Cross", Vector3.new(0.18, 0.06, 0.06) * k, gold, o.material), CFrame.new(0, orbY + 0.24 * k, 0))
	end

	return core
end

return CrownModel
