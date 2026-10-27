-- Moves players through Grandpa Gus's first-day guide (see Shared/Tutorial).
-- Other services call TutorialService.Event(player, "Dig") etc.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tutorial = require(Shared.Tutorial)
local Charms = require(Shared.Charms)
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
			local reward = Tutorial.RewardCharm
			saved.charms.owned[reward.id] = (saved.charms.owned[reward.id] or 0) + reward.amount
		end
	end)
	if finished then
		Remotes.Notify:FireClient(player, string.format("Grandpa Gus: You're a natural! Here's %s coins and %d %s charms. Happy digging!", Format.Number(Tutorial.RewardCoins), Tutorial.RewardCharm.amount, Charms.ById[Tutorial.RewardCharm.id].name), "success")
	end
end

function TutorialService.Start()
	-- The "take out your shovel" step: watch for the shovel appearing in the character
	DataService.OnLoaded(function(player)
		local function watch(character)
			character.ChildAdded:Connect(function(child)
				if child:IsA("Tool") then
					TutorialService.Event(player, "EquipShovel")
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
