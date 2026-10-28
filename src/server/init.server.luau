-- Dig Legends server. Starts every service in order.

local MapBuilder = require(script.MapBuilder)
local DataService = require(script.DataService)
local ShopService = require(script.ShopService)
local TutorialService = require(script.TutorialService)
local NpcService = require(script.NpcService)
local EconomyService = require(script.EconomyService)
local CosmeticService = require(script.CosmeticService)
local DigService = require(script.DigService)
local WorldService = require(script.WorldService)
local RushService = require(script.RushService)
local BuddyService = require(script.BuddyService)
local Finds = require(game:GetService("ReplicatedStorage").Shared.Finds)

MapBuilder.Build()

-- Services that react to players loading must start before DataService
ShopService.Start()
TutorialService.Start()
EconomyService.Start()
CosmeticService.Start()
DigService.Start()
WorldService.Start()
RushService.Start(DigService.GiveRushLoot)
BuddyService.Start()
NpcService.Start()
DataService.Start()

-- Test helpers for Roblox Studio only (never in the live game). In the command
-- bar, with the Server view selected:
--   game.ServerStorage.DigLegendsTest:Invoke("coins", 5000)
--   game.ServerStorage.DigLegendsTest:Invoke("xp", 10000)
--   game.ServerStorage.DigLegendsTest:Invoke("book", "desert") -- fills that Collection page
--   game.ServerStorage.DigLegendsTest:Invoke("rush") -- starts a Treasure Rush now
if game:GetService("RunService"):IsStudio() then
	local test = Instance.new("BindableFunction")
	test.Name = "DigLegendsTest"
	test.OnInvoke = function(command, amount)
		if command == "rush" then
			RushService.Begin()
			return "ok"
		end
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			DataService.Update(player, function(data)
				if command == "coins" then
					data.coins += amount
				elseif command == "xp" then
					data.xp += amount
				elseif command == "book" then
					for _, find in ipairs(Finds.ByZone[amount] or {}) do
						data.book[find.id] = data.book[find.id] or { count = 1, best = 0.1, shiny = 0 }
					end
				end
			end)
		end
		return "ok"
	end
	test.Parent = game:GetService("ServerStorage")
end

print("[Dig Legends] Server ready")
