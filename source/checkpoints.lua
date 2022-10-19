-- Obby checkpoint system, requested by a friend.

if not config then config = {keybinds = {set = Enum.KeyCode.E, unset = Enum.KeyCode.Q, teleport = Enum.KeyCode.R, lastStable = Enum.KeyCode.F}, saveCameraAngle = true} end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local root = character.PrimaryPart
local humanoid = character:WaitForChild("Humanoid")

function randomString()
	local str = ""
	for i = 1, 100 do str = str .. string.char(math.random(1,127)) end
	return str
end

local checkpointd = {}
local checkpointf = {}

function checkpointf:gui()
	local gui, detector, text, frame = Instance.new("ScreenGui"), Instance.new("Frame"), Instance.new("TextLabel"), Instance.new("Frame")
	gui.DisplayOrder, gui.Name, gui.IgnoreGuiInset = 2147483647, randomString(), true
	detector.BackgroundTransparency, detector.Position, detector.Size, detector.Name, detector.Parent = 1, UDim2.new(0, 0, 0.9, 0), UDim2.new(1, 0, 0.1, 0), randomString(), gui
	frame.Size, frame.Position, frame.Name, frame.BackgroundTransparency, frame.Parent = UDim2.new(0.2, 0, 0, 64), UDim2.new(0.05, 0, 1, 0), randomString(), 1, gui
	text.Size, text.Position, text.Name, text.BackgroundTransparency, text.Text, text.TextScaled, text.Font, text.TextColor3, text.TextStrokeTransparency, text.TextStrokeColor3, text.RichText, text.TextXAlignment, text.Parent = UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 0, 0.5, 0), randomString(), 1, "", true, Enum.Font.Arcade, Color3.new(1, 1, 1), 0, Color3.new(0, 0, 0), true, Enum.TextXAlignment.Left, frame
	
	local connections = {}
	local messages = {config.keybinds.set.Name..": set", config.keybinds.unset.Name..": unset", config.keybinds.teleport.Name..": teleport"}
	
	local function _anim(start:UDim2, finish:UDim2)
		for _, connection in pairs(connections) do
			connection:Disconnect()
		end

		local lerpStartA = os.clock()
		local connectionA, connectionB
		
		connectionA = RunService.RenderStepped:Connect(function()
			if os.clock() - lerpStartA > 0.5 then
				connectionA:Disconnect()
				frame.Position = finish
			else
				frame.Position = start:Lerp(finish, (os.clock() - lerpStartA) * 2)
			end
		end)
		table.insert(connections, connectionA)
	end
	
	detector.MouseEnter:Connect(function()
		_anim(UDim2.new(0, 4, 1, 0), UDim2.new(0, 4, 1, -32))
	end)
	
	detector.MouseLeave:Connect(function()
		_anim(UDim2.new(0, 4, 1, -32), UDim2.new(0, 4, 1, 0))
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
				task.wait(0.1)
				
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
	end
	
	local success, errorMessage = pcall(function()
		gui.Parent = game:GetService("CoreGui")
	end)
	
	if not success then
		if player:FindFirstChildOfClass("PlayerGui") then
			gui.Parent = player:FindFirstChildOfClass("PlayerGui")
		end
	end
end

function checkpointf:unset()
	if #checkpointd > 0 then
		local checkpoint = checkpointd[#checkpointd]
		
		if checkpoint[2] then
			checkpoint[2]:Destroy()
		end
		
		table.remove(checkpointd, #checkpointd)
	end
end

function checkpointf:set()
	if character and root then
        local part = Instance.new("Part")
        part.CFrame, part.Size, part.Color, part.Material, part.Transparency, part.CanCollide, part.Anchored, part.Name = root.CFrame, root.Size, Color3.new(1, 0, 0), Enum.Material.Neon, 0.5, false, true, randomString()
        table.insert(checkpointd, {[1] = root.CFrame, [2] = part, [3] = camera.CFrame, [4] = humanoid:GetState()})
        part.Parent = Workspace
	end
end

function checkpointf:teleport()
	if #checkpointd > 0 then
		if character and root then
            character:PivotTo(checkpointd[#checkpointd][1])
            humanoid:ChangeState(checkpointd[#checkpointd][4])
            if config.saveCameraAngle then
                camera.CFrame = checkpointd[#checkpointd][3]
            end
        end
	end
end

function characterAdded()
    character = player.Character
    humanoid = character:WaitForChild("Humanoid")
    root = character.PrimaryPart
end

function inputBegan(input, gameProcessed) if gameProcessed then return end
	if input.KeyCode == config.keybinds.set then checkpointf:set() end
	if input.KeyCode == config.keybinds.unset then checkpointf:unset() end
	if input.KeyCode == config.keybinds.teleport then checkpointf:teleport() end
end

UserInputService.InputBegan:Connect(inputBegan)
player.CharacterAdded:Connect(characterAdded)

checkpointf:gui()
