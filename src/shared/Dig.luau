-- The dig minigame, shared by server and player so both agree on the rules.
--
-- A marker slides back and forth along a bar. Tap while it is inside the green
-- sweet spot to dig deeper; the gold middle is a "perfect" hit. After every hit
-- the sweet spot moves. Tapping outside it cracks the find, and too many cracks
-- break it. Perfect hits make the find worth more.

local Dig = {}

Dig.MaxCracks = 3
Dig.PerfectShare = 0.35 -- the gold middle, as a share of the sweet spot
Dig.PerfectBonus = 0.3 -- all perfect hits = +30% value
Dig.MinTapGap = 0.2 -- seconds; nobody can dig out a find faster than this per strike
Dig.MaxSeconds = 60

function Dig.Params(rarity, shovel)
	local power = shovel and shovel.power or 0
	local zone = math.min(0.6, rarity.zone * (1 + power))
	return {
		rarity = rarity.id,
		strikes = rarity.strikes,
		zone = zone,
		perfect = zone * Dig.PerfectShare,
		speed = rarity.speed,
		cracks = Dig.MaxCracks,
	}
end

-- The quickest anyone could possibly finish this dig
function Dig.MinSeconds(params)
	return params.strikes * Dig.MinTapGap
end

-- Where the marker is (0 to 1) after t seconds
function Dig.MarkerAt(t, speed)
	local x = (t * speed) % 2
	if x > 1 then
		return 2 - x
	end
	return x
end

-- A new middle for the sweet spot, keeping it inside the bar
function Dig.NextCenter(random, params)
	local half = params.zone / 2
	return random:NextNumber(half, 1 - half)
end

-- "perfect", "hit" or "miss" for a tap with the marker at this spot
function Dig.Judge(marker, center, params)
	local distance = math.abs(marker - center)
	if distance <= params.perfect / 2 then
		return "perfect"
	elseif distance <= params.zone / 2 then
		return "hit"
	end
	return "miss"
end

function Dig.ValueMultiplier(perfects, strikes)
	return 1 + Dig.PerfectBonus * math.clamp(perfects / math.max(1, strikes), 0, 1)
end

return Dig
