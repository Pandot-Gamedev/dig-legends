-- While a menu window is open the player can't walk, jump, switch tools or use
-- prompts. Everything comes back when the window closes. (Digging already
-- won't start while a window is open, see Digging.luau.)

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")

local UI = require(script.Parent.UI)

local MenuLock = {}

local player = Players.LocalPlayer
local controls = nil
local locked = false

local function getControls()
	if controls then
		return controls
	end
	local ok, result = pcall(function()
		local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
		return module and require(module):GetControls()
	end)
	if ok and result then
		controls = result
	end
	return controls
end

local function setBackpack(on)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, on)
	end)
end

local function apply()
	local open = UI.IsWindowOpen()
	if open == locked then
		return
	end
	locked = open
	local c = getControls()
	if c then
		if open then
			c:Disable()
		else
			c:Enable()
		end
	end
	ProximityPromptService.Enabled = not open
	setBackpack(not open)
end

function MenuLock.IsLocked()
	return locked
end

function MenuLock.Init()
	task.spawn(getControls)
	-- Deferred so switching straight from one window to another doesn't unlock in between
	UI.WindowChanged:Connect(function()
		task.defer(apply)
	end)
end

return MenuLock
