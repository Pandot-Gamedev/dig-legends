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

MapBuilder.Build()

-- Services that react to players loading must start before DataService
ShopService.Start()
TutorialService.Start()
EconomyService.Start()
CosmeticService.Start()
DigService.Start()
WorldService.Start()
NpcService.Start()
DataService.Start()

-- Test helpers for Roblox Studio only (never in the live game). In the command
-- bar, with the Server view selected:
--   game.ServerStorage.DigLegendsTest:Invoke("coins", 5000)
--   game.ServerStorage.DigLegendsTest:Invoke("xp", 10000)
if game:GetService("RunService"):IsStudio() then
	local test = Instance.new("BindableFunction")
	test.Name = "DigLegendsTest"
	test.OnInvoke = function(command, amount)
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			DataService.Update(player, function(data)
				if command == "coins" then
					data.coins += amount
				elseif command == "xp" then
					data.xp += amount
				end
			end)
		end
		return "ok"
	end
	test.Parent = game:GetService("ServerStorage")
end

print("[Dig Legends] Server ready")
