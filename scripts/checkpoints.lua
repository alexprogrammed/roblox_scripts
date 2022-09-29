-- Obby checkpoint system, requested by a friend.

if not config then config = {set = Enum.KeyCode.E, teleport = Enum.KeyCode.R, unset = Enum.KeyCode.Q} end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

function randomString()
	local str = ""
	for i = 1, 100 do str = str .. string.char(math.random(1,127)) end
	return str
end

local checkpoints = {}
local checkpointf = {}

function checkpointf:gui()
	local gui, detector, text, frame = Instance.new("ScreenGui"), Instance.new("Frame"), Instance.new("TextLabel"), Instance.new("Frame")
	gui.DisplayOrder, gui.Name, gui.IgnoreGuiInset = 2147483647, randomString(), true
	detector.BackgroundTransparency, detector.Position, detector.Size, detector.Name, detector.Parent = 1, UDim2.new(0, 0, 0.8, 0), UDim2.new(1, 0, 0.2, 0), randomString(), gui
	frame.Size, frame.Position, frame.Name, frame.BackgroundTransparency, frame.Parent = UDim2.new(1, 0, 0.2, 0), UDim2.new(0, 0, 1, 0), randomString(), 1, gui
	text.Size, text.Position, text.Name, text.BackgroundTransparency, text.Text, text.TextScaled, text.Font, text.TextColor3, text.TextStrokeTransparency, text.TextStrokeColor3, text.Parent = UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 0, 0.5, 0), randomString(), 1, "", true, Enum.Font.Ubuntu, Color3.new(1, 1, 1), 0, Color3.new(0, 0, 0), frame
	
	local connections = {
		
	}
	
	local messages = {
		config.set.Name..": set",
		config.unset.Name..": unset",
		config.teleport.Name..": teleport"
	}
	
	detector.MouseEnter:Connect(function()
		for _, connection in pairs(connections) do
			connection:Disconnect()
		end

		local lerpStart = os.clock()
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if os.clock() - lerpStart > 0.5 then
				connection:Disconnect()
				frame.Position = UDim2.new(0, 0, 0.9, 0)
			else
				frame.Position = UDim2.new(0, 0, 1, 0):Lerp(UDim2.new(0, 0, 0.9, 0), os.clock() - lerpStart)
			end
		end)
		table.insert(connections, connection)
	end)
	
	detector.MouseLeave:Connect(function()
		for _, connection in pairs(connections) do
			connection:Disconnect()
		end
		
		local lerpStart = os.clock()
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if os.clock() - lerpStart > 0.5 then
				connection:Disconnect()
				frame.Position = UDim2.new(0, 0, 1, 0)
			else
				frame.Position = UDim2.new(0, 0, 0.9, 0):Lerp(UDim2.new(0, 0, 1, 0), os.clock() - lerpStart)
			end
		end)
		table.insert(connections, connection)
	end)
	
	task.spawn(function()
		while true do
			for i = 1, #messages do
				local message = messages[i]
				text.Text = message
				
				local tweenStartA = os.clock()
				while os.clock() - tweenStartA < 0.5 do
					text.Position = UDim2.new(0, 0, 0.5, 0):Lerp(UDim2.new(0, 0, -0.1, 0), (os.clock() - tweenStartA) * 2)
					task.wait()
				end
				
				text.Position = UDim2.new(0, 0, -0.1, 0)
				task.wait(0.5)
				
				local tweenStartB = os.clock()
				while os.clock() - tweenStartB < 0.5 do
					text.Position = UDim2.new(0, 0, -0.1, 0):Lerp(UDim2.new(0, 0, 0.5, 0), (os.clock() - tweenStartB) * 2)
					task.wait()
				end
				
				text.Position = UDim2.new(0, 0, 0.5, 0)
			end
		end
	end)
	
	if syn then
		syn.protect_gui(gui)
		gui.Parent = game:GetService("CoreGui")
	else
		gui.Parent = player:FindFirstChildOfClass("PlayerGui")
	end
end

function checkpointf:unset()
	if #checkpoints > 0 then
		local checkpoint = checkpoints[#checkpoints]
		
		if checkpoint[2] then
			checkpoint[2]:Destroy()
		end
		
		table.remove(checkpoints, #checkpoints)
	end
end

function checkpointf:set()
	if character then
		local root = character.PrimaryPart
		if root then
			local part = Instance.new("Part")
			part.CFrame, part.Size, part.Color, part.Material, part.Transparency, part.CanCollide, part.Anchored = root.CFrame, root.Size, Color3.new(1, 0, 0), Enum.Material.Neon, 0.5, false, true
			table.insert(checkpoints, {[1] = root.CFrame, [2] = part})
			part.Parent = Workspace
		end
	end
end

function checkpointf:teleport()
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

function characterAdded() character = player.Character end

function inputBegan(input, gameProcessed) if gameProcessed then return end
	if input.KeyCode == config.set then checkpointf:set() end
	if input.KeyCode == config.unset then checkpointf:unset() end
	if input.KeyCode == config.teleport then checkpointf:teleport() end
end

function mouseEnter()
	
end

UserInputService.InputBegan:Connect(inputBegan)
player.CharacterAdded:Connect(characterAdded)

if syn then
	_hook()
end

checkpointf:gui()
