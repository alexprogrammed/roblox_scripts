-- Celeste movement mechanics but in Roblox, requested by a friend.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player:Player? = Players.LocalPlayer
local character:Model = player.Character or player.CharacterAdded:Wait()

local humanoid:Humanoid = character:WaitForChild("Humanoid", math.huge)
local root:BasePart = character:WaitForChild("HumanoidRootPart", math.huge)

local camera:Camera = Workspace.CurrentCamera

local canDash:boolean = true
local isClimbing:boolean = false

local connections:{RBXScriptConnection} = {}

local lastDelay:number = 0

table.insert(connections, UserInputService.InputBegan:Connect(function(input:InputObject, gameProcessed:boolean)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.X then
		if canDash then
			canDash = false
			local lookVector = camera.CFrame.LookVector
			local fps = 1 / lastDelay
			for i = 1, fps / 5 do
				task.delay(lastDelay * i, function()
					for _, part in pairs(character:GetChildren()) do
						if part:IsA("BasePart") then					
							part.AssemblyLinearVelocity = lookVector * 75
						end
					end
				end)
			end
		end
	end
	if input.KeyCode == Enum.KeyCode.Z then
		isClimbing = true
	end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input:InputObject, gameProcessed:boolean)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Z then
		isClimbing = false
	end
end))

table.insert(connections, RunService.RenderStepped:Connect(function(d)
	lastDelay = d
	local state = humanoid:GetState()
	
	if state == Enum.HumanoidStateType.Running then
		canDash = true
	end
	
	if isClimbing then
		local ray = game:GetService("Workspace"):Raycast(root.Position - Vector3.new(0, 1, 0), (root.CFrame * CFrame.new(0, -1, 0)).LookVector * 2)
		if ray then
			local vel = 0
			
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then
				vel = humanoid.WalkSpeed
			elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then
				vel = -humanoid.WalkSpeed
			end
			
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then					
					part.AssemblyLinearVelocity = Vector3.new(part.AssemblyLinearVelocity.X, vel, part.AssemblyLinearVelocity.Z)
				end
			end
		else
			isClimbing = false
		end
	end
end))

humanoid.Died:Connect(function()
	for _, connection:RBXScriptConnection in pairs(connections) do
		connection:Disconnect()
	end
end)
