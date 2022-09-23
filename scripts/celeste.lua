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
local lastJump:number = os.clock()

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
	
	if input.KeyCode == Enum.KeyCode.Space then
		if humanoid:GetState() == Enum.HumanoidStateType.Climbing or humanoid:GetState() == Enum.HumanoidStateType.Running then return end
		
		local params:OverlapParams = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = character:GetChildren()
		
		local ray:RaycastResult = game:GetService("Workspace"):Raycast(root.Position, root.CFrame.LookVector * 2, params)
		
		if ray then
			local instance:Instance = ray.Instance
			local normal:Vector3 = ray.Normal
			
			local pivotTo:CFrame = CFrame.lookAt(root.Position, root.Position - normal)
			character:PivotTo(pivotTo)
			
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then					
					part.AssemblyLinearVelocity = Vector3.new(normal.X, normal.Y + 1, normal.Z).Unit * 50
				end
			end
			
			lastJump = os.clock()
		end
	end
	
	if input.KeyCode == Enum.KeyCode.Z then
		isClimbing = not isClimbing
	end
end))

table.insert(connections, RunService.RenderStepped:Connect(function(d)
	lastDelay = d
	local state:Enum.HumanoidStateType = humanoid:GetState()
	
	if state == Enum.HumanoidStateType.Running then
		canDash = true
	end
	
	if isClimbing then
		if os.clock() - lastJump < 0.1 then return end
		
		local params:OverlapParams = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = character:GetChildren()
		
		local ray:RaycastResult = game:GetService("Workspace"):Raycast(root.Position - Vector3.new(0, 1, 0), (root.CFrame * CFrame.new(0, -1, 0)).LookVector * 2, params)
		
		if ray then
			local instance:Instance = ray.Instance
			local normal:Vector3 = ray.Normal
			local distance:number = ray.Distance
			
			local size:Vector3 = instance.Size
			local cframe:CFrame = instance.CFrame
			
			local pivotTo:CFrame = CFrame.lookAt(root.Position, root.Position - (normal))
			
			pivotTo *= CFrame.new(0, 0, - (distance - (humanoid.RigType == Enum.HumanoidRigType.R6 and 0.6 or 1.1)))
			character:PivotTo(pivotTo)
			
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.new(part.AssemblyLinearVelocity.X, (UserInputService:IsKeyDown(Enum.KeyCode.W) and humanoid.WalkSpeed) or (UserInputService:IsKeyDown(Enum.KeyCode.S) and -humanoid.WalkSpeed), part.AssemblyLinearVelocity.Z)
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
