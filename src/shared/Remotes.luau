-- All the messages between server and players. The server creates them;
-- players wait for them to appear.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"DataUpdate", -- server -> player: the player's full save data
	"Notify", -- server -> player: a toast message
	"OpenPanel", -- server -> player: open a menu (e.g. the rod shop)
	"CancelCast", -- player -> server: stop fishing
	"Nibble", -- server -> player: a fish is nibbling (don't strike yet!)
	"Bite", -- server -> player: the real bite, strike now
	"Hook", -- player -> server: the player struck
	"Fight", -- server -> player: the fish is hooked, start the reeling fight
	"Reel", -- player -> server: how the fight ended
	"CatchResult", -- server -> player: what was caught, or why it got away
}

local FUNCTIONS = {
	"Action", -- player -> server: buy rod, unlock zone, rebirth, teleport, equip...
	"Cast", -- player -> server: cast at a position, returns the cast id if the bobber landed
}

local Remotes = {}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in ipairs(EVENTS) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	for _, name in ipairs(FUNCTIONS) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

for _, name in ipairs(EVENTS) do
	Remotes[name] = folder:WaitForChild(name)
end
for _, name in ipairs(FUNCTIONS) do
	Remotes[name] = folder:WaitForChild(name)
end

return Remotes
