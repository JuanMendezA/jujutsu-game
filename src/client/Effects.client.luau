-- Efectos visuales que manda el servidor (golpes, Black Flash, técnicas).
-- Son solo decoración: no afectan al daño.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = workspace
	return p
end

local function burst(position: Vector3, color: Color3, size: number, duration: number)
	local p = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.5, Color = color, Position = position })
	TweenService:Create(p, TweenInfo.new(duration), { Size = Vector3.one * size, Transparency = 1 }):Play()
	Debris:AddItem(p, duration)
end

local function blackFlashText(userId: number)
	if userId ~= player.UserId then
		return
	end
	local gui = player.PlayerGui:FindFirstChild("Hud")
	if not gui then
		return
	end
	local text = Instance.new("TextLabel")
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.35)
	text.Size = UDim2.fromOffset(500, 80)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBlack
	text.TextSize = 56
	text.Text = "BLACK FLASH"
	text.TextColor3 = Color3.fromRGB(230, 30, 40)
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.TextStrokeTransparency = 0
	text.Parent = gui
	TweenService:Create(text, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(text, 1)
end

Remotes.Effect.OnClientEvent:Connect(function(kind: string, data)
	if kind == "Hit" then
		burst(data.Position, Color3.new(1, 1, 1), 3, 0.15)
	elseif kind == "BlackFlash" then
		burst(data.Position, Color3.new(0, 0, 0), 9, 0.35)
		burst(data.Position, Color3.fromRGB(230, 30, 40), 6, 0.25)
		blackFlashText(data.UserId)
	elseif kind == "Beam" then
		local length = (data.To - data.From).Magnitude
		local beam = part({
			Size = Vector3.new(0.6, 0.6, length),
			CFrame = CFrame.lookAt(data.From, data.To) * CFrame.new(0, 0, -length / 2),
			Color = Color3.fromRGB(180, 0, 20),
		})
		TweenService:Create(beam, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		Debris:AddItem(beam, 0.3)
		burst(data.To, Color3.fromRGB(180, 0, 20), 4, 0.2)
	elseif kind == "Sphere" then
		burst(data.Position, data.Color, data.Radius * 2, 0.5)
	end
end)
