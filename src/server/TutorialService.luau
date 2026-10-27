-- Moves players through Old Pete's first-day guide (see Shared/Tutorial).
-- Other services call TutorialService.Event(player, "Cast") etc.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tutorial = require(Shared.Tutorial)
local Bait = require(Shared.Bait)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)

local TutorialService = {}

function TutorialService.Event(player, event)
	local data = DataService.Get(player)
	if not data or data.tutorial >= Tutorial.Done then
		return
	end
	local step = Tutorial.Steps[data.tutorial]
	if not step or step.event ~= event then
		return
	end
	local finished = data.tutorial + 1 >= Tutorial.Done
	DataService.Update(player, function(saved)
		saved.tutorial += 1
		if finished then
			saved.coins += Tutorial.RewardCoins
			local reward = Tutorial.RewardBait
			saved.bait.owned[reward.id] = (saved.bait.owned[reward.id] or 0) + reward.amount
		end
	end)
	if finished then
		Remotes.Notify:FireClient(player, string.format("Old Pete: You're a natural! Here's %s coins and %d %s. Good luck out there!", Format.Number(Tutorial.RewardCoins), Tutorial.RewardBait.amount, Bait.ById[Tutorial.RewardBait.id].name), "success")
	end
end

function TutorialService.Start()
	-- The "take out your rod" step: watch for the rod appearing in the character
	DataService.OnLoaded(function(player)
		local function watch(character)
			character.ChildAdded:Connect(function(child)
				if child:IsA("Tool") then
					TutorialService.Event(player, "EquipRod")
				end
			end)
		end
		if player.Character then
			watch(player.Character)
		end
		player.CharacterAdded:Connect(watch)
	end)
end

return TutorialService
