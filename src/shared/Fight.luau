-- The reeling fight, shared by server and player so both agree on the rules.
--
-- Hold to reel: the catch bar fills, but line tension rises.
-- Let go: tension drops, but the fish pulls the catch bar back.
-- Every few seconds the fish thrashes (with a short warning first). Still reeling
-- when it starts jolts the line, and reeling during a thrash barely helps.
-- Catch bar full = caught. Tension full = line snaps. Catch bar empty = it got away.

local Fight = {}

Fight.StartProgress = 0.25
Fight.TensionUp = 0.42 -- per second while reeling (before rod control)
Fight.ThrashTension = 1.1 -- extra per second while reeling during a thrash, times strength
Fight.ThrashJolt = 0.3 -- instant tension if you are still reeling when a thrash starts (weak fish jolt less)
Fight.TensionDown = 0.7 -- per second while not reeling
Fight.PullBack = 0.03 -- catch bar lost per second while not reeling, times strength
Fight.ThrashPullBack = 0.07 -- same, during a thrash
Fight.ThrashReelFactor = 0.3 -- reeling speed during a thrash
Fight.WarningSeconds = 0.45
Fight.MaxSeconds = 120

function Fight.Params(rarity, rod)
	local control = rod and rod.control or 0
	return {
		rarity = rarity.id,
		strength = rarity.strength,
		gain = rarity.reel * (1 + control * 2),
		tensionUp = Fight.TensionUp * (1 - control),
		calm = { 1.3 / math.sqrt(rarity.strength), 3.4 / math.sqrt(rarity.strength) },
		thrash = { 0.6 * math.sqrt(rarity.strength), 1.3 * math.sqrt(rarity.strength) },
	}
end

-- The quickest a perfect player could possibly land this fish
function Fight.MinSeconds(params)
	return (1 - Fight.StartProgress) / params.gain
end

-- Advance the fight by dt. state = { progress, tension, phase, phaseLeft, reeling }
-- phase is "calm", "warning" or "thrash". random is a Random object.
function Fight.Step(state, params, dt, random)
	state.phaseLeft -= dt
	if state.phaseLeft <= 0 then
		if state.phase == "calm" then
			state.phase = "warning"
			state.phaseLeft = Fight.WarningSeconds
		elseif state.phase == "warning" then
			state.phase = "thrash"
			state.phaseLeft = random:NextNumber(params.thrash[1], params.thrash[2])
			if state.reeling then
				state.tension += Fight.ThrashJolt * (params.strength - 0.4)
			end
		else
			state.phase = "calm"
			state.phaseLeft = random:NextNumber(params.calm[1], params.calm[2])
		end
	end

	local thrashing = state.phase == "thrash"
	if state.reeling then
		local gain = params.gain * (thrashing and Fight.ThrashReelFactor or 1)
		state.progress += gain * dt
		state.tension += (params.tensionUp + (thrashing and Fight.ThrashTension * params.strength or 0)) * dt
	else
		local pull = thrashing and Fight.ThrashPullBack or Fight.PullBack
		state.progress -= pull * params.strength * dt
		state.tension -= Fight.TensionDown * dt
	end
	state.tension = math.max(0, state.tension)

	if state.progress >= 1 then
		return "caught"
	elseif state.tension >= 1 then
		return "snapped"
	elseif state.progress <= 0 then
		return "escaped"
	end
	return nil
end

function Fight.NewState(params, random)
	return {
		progress = Fight.StartProgress,
		tension = 0,
		phase = "calm",
		phaseLeft = random:NextNumber(params.calm[1], params.calm[2]),
		reeling = false,
	}
end

return Fight
