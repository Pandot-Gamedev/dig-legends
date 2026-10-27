-- All the messages between server and players. The server creates them;
-- players wait for them to appear.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"DataUpdate", -- server -> player: the player's full save data
	"Notify", -- server -> player: a toast message
	"OpenPanel", -- server -> player: open a menu (e.g. the shovel shop)
	"CancelDig", -- player -> server: stop digging
	"DigReady", -- server -> player: something is down there, start the dig minigame
	"DigDone", -- player -> server: how the minigame ended
	"DigResult", -- server -> player: what was found, or why it broke
}

local FUNCTIONS = {
	"Action", -- player -> server: buy shovel, unlock zone, rebirth, teleport, equip...
	"StartDig", -- player -> server: dig at a dig spot, returns the dig id if it started
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
