-- Celeste movement mechanics but in Roblox, requested by a friend.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid", math.huge)
local root = character:WaitForChild("HumanoidRootPart", math.huge)

local camera = Workspace.CurrentCamera

local canDash = true
local isClimbing = false

local connections = {}

local lastRenderSteppedDelay = 0
local lastJump = os.clock()

if humanoid.Health <= 0 then return end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.X then
		if canDash then
			canDash = false
			local lookVector = camera.CFrame.LookVector
			local fps = 1 / lastRenderSteppedDelay
			
			local threads = {}
			
			local stateChangedConnection = humanoid.StateChanged:Connect(function(new, old)
				if new == Enum.HumanoidStateType.Landed then
					lookVector = Vector3.new(lookVector.X, 0, lookVector.Z)
				end
				
				if new == Enum.HumanoidStateType.Jumping then
					for _, thread in pairs(threads) do
						coroutine.close(thread)
					end
					
					for i = 1, fps / 4 do
						task.delay(lastRenderSteppedDelay * i, function()
							for _, part in pairs(character:GetChildren()) do
								if part:IsA("BasePart") then
									part.AssemblyLinearVelocity = Vector3.new(lookVector.X, 0.5, lookVector.Z).Unit * 75
								end
							end
						end)
					end
				end
			end)
			
			task.delay((lastRenderSteppedDelay * (fps / 6)), function()
				stateChangedConnection:Disconnect()
			end)
			
			for i = 1, fps / 4 do
				local thread = coroutine.create(function()
					for _, part in pairs(character:GetChildren()) do
						if part:IsA("BasePart") then
							part.AssemblyLinearVelocity = lookVector.Unit * 75
						end
					end
				end)
				
				table.insert(threads, thread)
				
				task.delay(lastRenderSteppedDelay * i, function()
					if coroutine.status(thread) == "dead" then return end
					coroutine.resume(thread)
				end)
			end
		end
	end
	
	if input.KeyCode == Enum.KeyCode.Space then
		if humanoid:GetState() == Enum.HumanoidStateType.Climbing or humanoid:GetState() == Enum.HumanoidStateType.Running then return end
		
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = character:GetChildren()
		
		local ray = game:GetService("Workspace"):Raycast(root.Position, root.CFrame.LookVector * 2, params)
		local ray2 = game:GetService("Workspace"):Raycast(root.Position, root.CFrame.LookVector * -2, params)
		
		if ray or ray2 then
			
			local currentRay = ray or ray2
			
			local instance = currentRay.Instance
			local normal = currentRay.Normal
			
			local pivotTo = CFrame.lookAt(root.Position, root.Position - Vector3.new((currentRay == ray and normal.X) or (currentRay == ray2 and -normal.X), 0, (currentRay == ray and normal.Z) or (currentRay == ray2 and -normal.Z)))
			character:PivotTo(pivotTo)
			
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then					
					part.AssemblyLinearVelocity = Vector3.new(normal.X, 1, normal.Z).Unit * 60
				end
			end
			
			lastJump = os.clock()
		end
	end
	
	if input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.Q then
		isClimbing = not isClimbing
	end
end))

table.insert(connections, RunService.RenderStepped:Connect(function(d)
	lastRenderSteppedDelay = d
	local state = humanoid:GetState()
	
	if state == Enum.HumanoidStateType.Running then
		canDash = true
	end
	
	if isClimbing then
		if os.clock() - lastJump < 0.1 then return end
		
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = character:GetChildren()
		
		local ray = game:GetService("Workspace"):Raycast(root.Position - Vector3.new(0, 1, 0), (root.CFrame * CFrame.new(0, -1, 0)).LookVector * 2, params)
		
		if ray then
			local instance = ray.Instance
			local normal = ray.Normal
			local distance = ray.Distance
			
			local size = instance.Size
			local cframe = instance.CFrame
			
			local updatedNormal = Vector3.new(normal.X, 0, normal.Z)
			
			local pivotTo = CFrame.lookAt(root.Position, root.Position - updatedNormal)
			
			pivotTo *= CFrame.new(0, 0, - (distance - (humanoid.RigType == Enum.HumanoidRigType.R6 and 0.6 or 1.1)))
			character:PivotTo(pivotTo) 
			
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.new((UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D)) and root.AssemblyLinearVelocity.X or 0, (UserInputService:IsKeyDown(Enum.KeyCode.W) and humanoid.WalkSpeed) or (UserInputService:IsKeyDown(Enum.KeyCode.S) and -humanoid.WalkSpeed), (UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D)) and root.AssemblyLinearVelocity.Z or 0)
				end
			end
		else
			isClimbing = false
		end
	end
end))

humanoid.Died:Once(function()
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
end)
