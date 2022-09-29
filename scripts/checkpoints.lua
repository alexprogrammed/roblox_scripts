-- Obby checkpoint system, requested by a friend.

if not config then config = {set = Enum.KeyCode.E, teleport = Enum.KeyCode.R, unset = Enum.KeyCode.Q} end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local clock = os.clock()

local checkpoints = {}
local checkpointf = {}

function checkpointf.unset()
	if #checkpoints > 0 then
		local checkpoint = checkpoints[#checkpoints]
		
		if checkpoint[2] then
			checkpoint[2]:Destroy()
		end
		
		table.remove(checkpoints, #checkpoints)
	end
end

function checkpointf.set()
	if character then
		local root = character.PrimaryPart
		if root then
			local part = Instance.new("Part")
			part.CFrame, part.Size, part.Color, part.Material, part.Transparency, part.CanCollide, part.Anchored = root.CFrame, root.Size, CFrame.new(1, 0, 0), Enum.Material.Neon, 0.5, false, true
			table.insert(checkpoints, {[1] = root.CFrame, [2] = part})
			part.Parent = Workspace
		end
	end
end

function checkpointf.teleport()
	if #checkpoints > 0 then
		if character then
			local root = character.PrimaryPart
			if root then
				character:PivotTo(checkpoints[#checkpoints][1])
			end
		end
	end
end

function _hook()
	local indexA, funcA, funcB
	indexA = hookmetamethod(game, "__index", function(Self, Key)
		if not checkcaller() and Self == Workspace then
			for _, checkpoint in pairs(checkpoints) do
				if Key == checkpoint[3].Name then
					return nil
				end
			end
		end
		
		return indexA(Self, Key)
	end)
	
	funcA = hookfunction(Workspace.ChildAdded, newcclosure(function(event, ...)
		if not checkcaller() then
			local args = {...}
			local instance = args[1]
			if instance then
				for _, checkpoint in pairs(checkpoints) do
					if instance.Name == checkpoint[3].Name then
						return
					end
				end
			end
		end
		
		return funcA(event, ...)
	end))
	
	funcB = hookfunction(Workspace.ChildRemoved, newcclosure(function(event, ...)
		if not checkcaller() then
			local args = {...}
			local instance = args[1]
			if instance then
				for _, checkpoint in pairs(checkpoints) do
					if instance.Name == checkpoint[3].Name then
						return
					end
				end
			end
		end
		
		return funcB(event, ...)
	end))
end

function characterAdded()
	character = player.Character
end

function inputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == config.set then checkpointf.set() end
	if input.KeyCode == config.unset then checkpointf.unset() end
	if input.KeyCode == config.teleport then checkpointf.teleport() end
end

UserInputService.InputBegan:Connect(inputBegan)
player.CharacterAdded:Connect(characterAdded)

if syn then
	_hook()
end
