-- Interfaz: vida, energía maldita, nivel/XP, técnica y cooldowns de Z y X.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function bar(name: string, color: Color3, y: number): Frame
	local back = Instance.new("Frame")
	back.Name = name
	back.AnchorPoint = Vector2.new(0, 1)
	back.Position = UDim2.new(0, 20, 1, y)
	back.Size = UDim2.fromOffset(260, 18)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	back.BorderSizePixel = 0
	back.Parent = gui
	Instance.new("UICorner", back).CornerRadius = UDim.new(0, 4)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
	return back
end

local function label(text: string, position: UDim2, size: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = position
	l.AnchorPoint = Vector2.new(0, 1)
	l.Size = UDim2.fromOffset(400, size + 4)
	l.Font = Enum.Font.GothamBold
	l.TextSize = size
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.5
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = gui
	return l
end

local healthBar = bar("Health", Color3.fromRGB(200, 50, 60), -50)
local energyBar = bar("Energy", Color3.fromRGB(70, 110, 255), -26)
local levelLabel = label("", UDim2.new(0, 20, 1, -74), 16)
local techniqueLabel = label("", UDim2.new(0, 20, 1, -96), 18)
local cooldownLabel = label("", UDim2.new(0, 300, 1, -26), 16)

local function moveText(key: string, techniqueId: string?): string
	local technique = techniqueId and Config.Techniques[techniqueId]
	local move = technique and technique.Moves[key]
	if not move then
		return ""
	end
	local readyAt = player:GetAttribute("Cooldown_" .. key) or 0
	local remaining = readyAt - workspace:GetServerTimeNow()
	local status = if remaining > 0 then string.format("%.1fs", remaining) else "listo"
	return string.format("[%s] %s (%s)", key, move.Name, status)
end

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		healthBar.Fill.Size = UDim2.fromScale(math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 1)
	end
	local energy = player:GetAttribute("Energy") or 0
	energyBar.Fill.Size = UDim2.fromScale(energy / Config.MaxEnergy, 1)

	levelLabel.Text = string.format(
		"Nivel %d  ·  XP %d / %d",
		player:GetAttribute("Level") or 1,
		player:GetAttribute("Xp") or 0,
		player:GetAttribute("XpNeeded") or 100
	)

	local techniqueId = player:GetAttribute("Technique")
	local technique = techniqueId and Config.Techniques[techniqueId]
	techniqueLabel.Text = if technique
		then string.format("%s (%s)", technique.DisplayName, technique.Rarity)
		else "Cargando técnica..."
	cooldownLabel.Text = moveText("Z", techniqueId) .. "     " .. moveText("X", techniqueId)
end)
