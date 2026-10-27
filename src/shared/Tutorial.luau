-- Grandpa Gus's first-day guide. Each step points at a place in the world (a part
-- with the matching "GuideTarget" attribute) and finishes on a game event.

local Tutorial = {}

Tutorial.Steps = {
	{ event = "EquipShovel", text = "Welcome, digger! Take out your shovel: press 1, or tap it at the bottom of the screen.", target = nil },
	{ event = "Dig", text = "See the sparkling dirt? Stand next to it and click to dig.", target = "DigPatch" },
	{ event = "Find", text = "Tap when the marker is in the green. Hit the gold middle for a better find!", target = "DigPatch" },
	{ event = "Sell", text = "Great find! Bring it to Ruby at the Trading Post and sell it.", target = "Sell" },
	{ event = "Bounties", text = "Come see me at the bounty board. I pay extra for the finds I need!", target = "Bounties" },
}

Tutorial.Done = #Tutorial.Steps + 1
Tutorial.RewardCoins = 250
Tutorial.RewardCharm = { id = "clover", amount = 10 }

return Tutorial
