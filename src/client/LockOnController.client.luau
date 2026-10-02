-- Lock on: Alt fija la cámara y el personaje en el enemigo más cercano a la mira.
-- Alt otra vez lo suelta. Mientras está fijado, las técnicas apuntan al objetivo.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LockOn = require(script.Parent.LockOn)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local MAX_DISTANCE = 80
local BREAK_DISTANCE = 110
local CAMERA_BACK = 12
local CAMERA_UP = 4
local CAMERA_SIDE = 2.5

local highlight: Highlight? = nil
local diedConnection: RBXScriptConnection? = nil

local function myParts(): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return humanoid, root
end

local function candidates(): { Model }
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and other.Character then
			table.insert(list, other.Character)
		end
	end
	local curses = workspace:FindFirstChild("Curses")
	if curses then
		for _, model in curses:GetChildren() do
			if model:IsA("Model") then
				table.insert(list, model)
			end
		end
	end
	return list
end

local function isValid(model: Model?): boolean
	if not (model and model.Parent) then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0 and model:FindFirstChild("HumanoidRootPart") ~= nil
end

-- Elige el objetivo más centrado en pantalla, penalizando un poco la distancia.
local function findTarget(root: BasePart): Model?
	local best, bestScore = nil, math.huge
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
	for _, model in candidates() do
		if isValid(model) then
			local targetRoot = model.HumanoidRootPart :: BasePart
			local distance = (targetRoot.Position - root.Position).Magnitude
			local screen, onScreen = camera:WorldToViewportPoint(targetRoot.Position)
			if distance <= MAX_DISTANCE and onScreen then
				local score = (Vector2.new(screen.X, screen.Y) - center).Magnitude + distance * 3
				if score < bestScore then
					best, bestScore = model, score
				end
			end
		end
	end
	return best
end

local function unlock()
	LockOn.Target = nil
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
	if diedConnection then
		diedConnection:Disconnect()
		diedConnection = nil
	end
	local humanoid = myParts()
	if humanoid then
		humanoid.AutoRotate = true
	end
	camera.CameraType = Enum.CameraType.Custom
end

local function lock(target: Model)
	LockOn.Target = target
	highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(230, 30, 40)
	highlight.Parent = target
	diedConnection = (target:FindFirstChildOfClass("Humanoid") :: Humanoid).Died:Connect(unlock)

	local humanoid = myParts()
	if humanoid then
		humanoid.AutoRotate = false
	end
	camera.CameraType = Enum.CameraType.Scriptable
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		if LockOn.Target then
			unlock()
		else
			local _, root = myParts()
			local target = root and findTarget(root)
			if target then
				lock(target)
			end
		end
	end
end)

player.CharacterAdded:Connect(function()
	if LockOn.Target then
		unlock()
	end
end)

RunService:BindToRenderStep("LockOn", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local target = LockOn.Target
	if not target then
		return
	end
	local humanoid, root = myParts()
	if not (humanoid and root and humanoid.Health > 0 and isValid(target)) then
		unlock()
		return
	end
	local targetPosition = (target.HumanoidRootPart :: BasePart).Position
	local offset = targetPosition - root.Position
	if offset.Magnitude > BREAK_DISTANCE then
		unlock()
		return
	end

	-- El personaje mira al objetivo (solo en horizontal).
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude > 0.5 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
	end

	-- Cámara por encima del hombro, mirando al objetivo.
	local direction = if flat.Magnitude > 0.5 then flat.Unit else root.CFrame.LookVector
	local right = direction:Cross(Vector3.yAxis)
	local desired = root.Position - direction * CAMERA_BACK + Vector3.yAxis * CAMERA_UP + right * CAMERA_SIDE
	local goal = CFrame.lookAt(desired, targetPosition)
	camera.CFrame = camera.CFrame:Lerp(goal, math.clamp(dt * 12, 0, 1))
end)
