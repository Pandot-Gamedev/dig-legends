-- Weekly legendary fish and rotating weather. Both are worked out from the
-- clock, so every server (and every player's screen) agrees without talking.

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local Fish = require(script.Parent.Fish)

local Events = {}

local WEEK = 7 * 24 * 60 * 60
local MONDAY_OFFSET = 4 * 24 * 60 * 60 -- 1 Jan 1970 was a Thursday; weeks start Monday 00:00 UTC

-- Weather is free for everyone and only gives small, temporary boosts.
Events.Weathers = {
	{ id = "Clear", name = "Clear Skies", description = "A calm day on the water." },
	{ id = "Rain", name = "Rain", description = "Fish bite 20% faster.", biteMultiplier = 0.8 },
	{ id = "Fog", name = "Fog", description = "Rare and better fish are 20% more likely.", luckMultiplier = 1.2 },
	{ id = "Storm", name = "Storm", description = "Legendary and Mythic fish are twice as likely.", legendaryMultiplier = 2 },
	{ id = "GoldenHour", name = "Golden Hour", description = "Shiny fish are twice as likely.", shinyMultiplier = 2 },
}

function Events.Now()
	return Workspace:GetServerTimeNow()
end

function Events.GetWeek(now)
	now = now or Events.Now()
	local week = math.floor((now - MONDAY_OFFSET) / WEEK)
	local secondsLeft = WEEK - ((now - MONDAY_OFFSET) % WEEK)
	return week, secondsLeft
end

-- The legendary fish featured this week.
function Events.GetEventFish(now)
	local week, secondsLeft = Events.GetWeek(now)
	local fish = Fish.EventFish[(week % #Fish.EventFish) + 1]
	return fish, secondsLeft
end

function Events.GetWeather(now)
	now = now or Events.Now()
	local slot = math.floor(now / Config.WeatherSeconds)
	local secondsLeft = Config.WeatherSeconds - (now % Config.WeatherSeconds)
	-- Clear weather half the time, a random special weather otherwise
	local roll = Random.new(slot):NextInteger(1, (#Events.Weathers - 1) * 2)
	local weather = Events.Weathers[1]
	if roll < #Events.Weathers then
		weather = Events.Weathers[roll + 1]
	end
	return weather, secondsLeft
end

return Events
