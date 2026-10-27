-- Old Pete's first-day guide. Each step points at a place in the world (a part
-- with the matching "GuideTarget" attribute) and finishes on a game event.

local Tutorial = {}

Tutorial.Steps = {
	{ event = "EquipRod", text = "Welcome, sailor! Take out your rod: press 1, or tap the rod at the bottom of the screen.", target = nil },
	{ event = "Cast", text = "Walk to the end of the dock and click the water to cast. Bubbles mean fish!", target = "Dock" },
	{ event = "Catch", text = "Wait for the big \"!\" and strike. Then hold to reel, and ease off when the line gets tight!", target = "Dock" },
	{ event = "Sell", text = "Nice catch! Bring it to Marina at the Fish Market and sell it.", target = "Sell" },
	{ event = "Bounties", text = "Come see me at the bounty board. I pay extra for the fish I need!", target = "Bounties" },
}

Tutorial.Done = #Tutorial.Steps + 1
Tutorial.RewardCoins = 250
Tutorial.RewardBait = { id = "worms", amount = 10 }

return Tutorial
