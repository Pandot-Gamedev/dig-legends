-- Dig buddies: digging within 20 studs of a Roblox friend gives both of you
-- +10% coins for everything you dig up there. Each player's current buddy is
-- kept in their "DigBuddy" attribute (the friend's display name), which
-- DigService reads when a find comes up and the HUD shows on screen.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local BuddyService = {}

local CHECK_SECONDS = 1
local TIP_COOLDOWN = 120 -- seconds between "dig buddy" toasts for one player

local friends = {} -- ["lowId:highId"] = true / false (nil while Roblox hasn't answered)
local asking = {}
local lastTip = {} -- [player] = os.clock()

local function pairKey(a, b)
	return math.min(a.UserId, b.UserId) .. ":" .. math.max(a.UserId, b.UserId)
end

local function areFriends(a, b)
	-- Test players in Studio are never real friends, so count everyone there
	if RunService:IsStudio() then
		return true
	end
	local key = pairKey(a, b)
	if friends[key] == nil and not asking[key] then
		asking[key] = true
		task.spawn(function()
			local ok, result = pcall(a.IsFriendsWith, a, b.UserId)
			if ok then
				friends[key] = result
			end
			-- If Roblox didn't answer, ask again on a later check
			task.delay(ok and 0 or 30, function()
				asking[key] = nil
			end)
		end)
	end
	return friends[key] == true
end

local function rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 then
		return root
	end
	return nil
end

local function check()
	local players = Players:GetPlayers()
	for _, player in ipairs(players) do
		local root = rootOf(player)
		local buddy, closest = nil, Config.BuddyRange
		if root then
			for _, other in ipairs(players) do
				local otherRoot = other ~= player and rootOf(other)
				if otherRoot then
					local distance = (otherRoot.Position - root.Position).Magnitude
					if distance <= closest and areFriends(player, other) then
						buddy, closest = other, distance
					end
				end
			end
		end
		local name = buddy and buddy.DisplayName or nil
		if name and not player:GetAttribute("DigBuddy") and os.clock() - (lastTip[player] or -math.huge) > TIP_COOLDOWN then
			lastTip[player] = os.clock()
			Remotes.Notify:FireClient(player, string.format("Dig buddy! Digging near %s gives you both +%d%% coins.", name, math.floor(Config.BuddyBonus * 100 + 0.5)), "success")
		end
		if player:GetAttribute("DigBuddy") ~= name then
			player:SetAttribute("DigBuddy", name)
		end
	end
end

-- The coin multiplier for a find this player digs up right now
function BuddyService.Multiplier(player)
	return player:GetAttribute("DigBuddy") and 1 + Config.BuddyBonus or 1
end

function BuddyService.Start()
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			check()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastTip[player] = nil
		local id = tostring(player.UserId)
		for key in pairs(friends) do
			local low, high = key:match("^(-?%d+):(-?%d+)$")
			if low == id or high == id then
				friends[key] = nil
			end
		end
	end)
end

return BuddyService
