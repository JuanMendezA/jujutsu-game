-- Controles: clic = M1, F (mantener) = bloquear, Q = esquivar, Z / X = técnicas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local lastDodge = 0

local function dash()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (humanoid and root) then
		return
	end
	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = root.CFrame.LookVector
	end
	root.AssemblyLinearVelocity = direction.Unit * Config.Dodge.Speed + Vector3.new(0, 5, 0)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Remotes.Action:FireServer("M1")
	elseif input.KeyCode == Enum.KeyCode.F then
		Remotes.Action:FireServer("Block", true)
	elseif input.KeyCode == Enum.KeyCode.Q then
		local now = os.clock()
		if now - lastDodge >= Config.Dodge.Cooldown then
			lastDodge = now
			dash()
			Remotes.Action:FireServer("Dodge")
		end
	elseif input.KeyCode == Enum.KeyCode.Z then
		Remotes.Action:FireServer("Technique", "Z", mouse.Hit.Position)
	elseif input.KeyCode == Enum.KeyCode.X then
		Remotes.Action:FireServer("Technique", "X", mouse.Hit.Position)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then
		Remotes.Action:FireServer("Block", false)
	end
end)
