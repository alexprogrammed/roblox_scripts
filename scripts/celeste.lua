-- Celeste movement mechanics but in Roblox, requested by a friend.

if not config then
	config = {dash = Enum.KeyCode.X, climb = Enum.KeyCode.Z}
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local gravity = Workspace.Gravity

local humanoid = character:WaitForChild("Humanoid", math.huge)
local root = character:WaitForChild("HumanoidRootPart", math.huge)

local camera = Workspace.CurrentCamera

local canDash = true
local isClimbing = false

local connections = {}

local lastRenderSteppedDelay = 0
local lastJump = os.clock()

if humanoid.Health <= 0 then return end

function randomString()
	local str = ""
	for i = 1, 100 do str = str .. string.char(math.random(1,127)) end
	return str
end

function dash()
	if canDash then
		isClimbing = false
		canDash = false

		local lookVector = camera.CFrame.LookVector
		local fps = 1 / lastRenderSteppedDelay

		local threads = {}
		function createEffect()
			local model = Instance.new("Model")
			model.Name = randomString()
			model.Parent = Workspace

			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then
					local clone = Instance.new("Part")
					clone.Name = randomString() 
					clone.Color = Color3.new(1, 1, 1)
					clone.CFrame = part.CFrame
					clone.Material = Enum.Material.Neon
					clone.Size = part.Size
					clone.Anchored = true
					clone.CanCollide = false
					clone.CanQuery = false
					clone.CanTouch = false
					clone.Transparency = 0.8
					clone.Parent = model

					game:GetService("TweenService"):Create(clone, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0), {Transparency = 1}):Play()
				end
			end

			task.delay(1, function()
				if model then
					model:Destroy()
				end
			end)
		end

		local stateChangedConnection = humanoid.StateChanged:Connect(function(new, old)
			if new == Enum.HumanoidStateType.Landed then
				lookVector = Vector3.new(lookVector.X, 0, lookVector.Z)
			end

			if new == Enum.HumanoidStateType.Jumping then
				for _, thread in pairs(threads) do
					coroutine.close(thread)
				end

				task.delay(lastRenderSteppedDelay, function()
					for _, part in pairs(character:GetChildren()) do
						if part:IsA("BasePart") then
							part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						end
					end

					for i = 1, fps / 4 do
						task.delay(lastRenderSteppedDelay * i, function()
							for _, part in pairs(character:GetChildren()) do
								if part:IsA("BasePart") then
									part.AssemblyLinearVelocity = Vector3.new(lookVector.X, 0.2, lookVector.Z).Unit * 100
								end
							end

							if i % 2 == 0 then
								createEffect()
							end
						end)
					end

				end)
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

				if i % 2 == 0 then
					createEffect()
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

function climb()
	isClimbing = not isClimbing
end

function jump()
	if humanoid:GetState() == Enum.HumanoidStateType.Climbing or humanoid:GetState() == Enum.HumanoidStateType.Running then return end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = character:GetChildren()

	local ray = game:GetService("Workspace"):Raycast(root.Position, root.CFrame.LookVector * 2, params)
	local ray2 = game:GetService("Workspace"):Raycast(root.Position, root.CFrame.LookVector * -2, params)

	if ray or ray2 then
		task.spawn(function()
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxasset://sounds/action_jump.mp3"
			game:GetService("ContentProvider"):PreloadAsync({sound}, function()
				game:GetService("SoundService"):PlayLocalSound(sound)
			end)
		end)

		isClimbing = false

		local currentRay = ray or ray2

		local instance = currentRay.Instance
		local normal = currentRay.Normal

		local pivotTo = CFrame.lookAt(root.Position, root.Position - Vector3.new((currentRay == ray and -normal.X) or (currentRay == ray2 and normal.X), 0, (currentRay == ray and -normal.Z) or (currentRay == ray2 and normal.Z)))
		character:PivotTo(pivotTo)

		for _, part in pairs(character:GetChildren()) do
			if part:IsA("BasePart") then					
				part.AssemblyLinearVelocity = Vector3.new(normal.X, 1, normal.Z).Unit * 60
			end
		end

		lastJump = os.clock()
	end
end

function step(d)
	lastRenderSteppedDelay = d
	local state = humanoid:GetState()

	if state == Enum.HumanoidStateType.Running then
		if not isClimbing then
			canDash = true
		end
	end

	if isClimbing then
		Workspace.Gravity = 0

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = character:GetChildren()

		local ray = game:GetService("Workspace"):Raycast(root.Position - Vector3.new(0, 1, 0), (root.CFrame * CFrame.new(0, -1, 0)).LookVector * 2, params)

		if ray then
			if os.clock() - lastJump < 0.1 then
				return
			end

			local instance = ray.Instance
			local normal = ray.Normal
			local distance = ray.Distance

			local size = instance.Size
			local cframe = instance.CFrame

			if instance then
				if instance:IsA("BasePart") then
					if instance.Material == Enum.Material.Ice then
						isClimbing = false
						return
					end
				end
			end

			local updatedNormal = Vector3.new(normal.X, 0, normal.Z)

			local pivotTo = CFrame.lookAt(root.Position, root.Position - updatedNormal)

			pivotTo *= CFrame.new(0, 0, - (distance - 0.8))
			character:PivotTo(pivotTo)

			local cross = pivotTo.RightVector.Unit

			local velocity = Vector3.new(0, (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1) or (UserInputService:IsKeyDown(Enum.KeyCode.S) and -1) or 0, 0)

			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				velocity += cross
			elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
				velocity -= cross
			end

			local unit = velocity ~= Vector3.new(0, 0, 0) and velocity.Unit or Vector3.new(0, 0, 0)

			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = unit * humanoid.WalkSpeed
				end
			end
		else
			isClimbing = false
		end
	else
		Workspace.Gravity = gravity
	end
end

function handleAction(actionName, inputState, _inputObject)
	if inputState == Enum.UserInputState.Begin then
		if actionName == "CELESTE_DASH" then
			dash()
		elseif actionName == "CELESTE_CLIMB" then
			climb()
		end	
	end
end

table.insert(connections, UserInputService.JumpRequest:Connect(jump))
table.insert(connections, RunService.RenderStepped:Connect(step))

ContextActionService:BindAction("CELESTE_DASH", handleAction, false, config.dash or Enum.KeyCode.X)
ContextActionService:BindAction("CELESTE_CLIMB", handleAction, false, config.climb or Enum.KeyCode.Z)

humanoid.Died:Once(function()
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	
	ContextActionService:UnbindAction("CELESTE_DASH")
	ContextActionService:UnbindAction("CELESTE_CLIMB")
	
	Workspace.Gravity = gravity
end)
