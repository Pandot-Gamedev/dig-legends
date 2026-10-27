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

print("[Dig Legends] Server ready")
