-- Efectos visuales que manda el servidor (golpes, Black Flash, técnicas) y las
-- animaciones. Son solo decoración: no afectan al daño.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local AnimationPlayer = require(script.Parent.AnimationPlayer)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SHAKE_RANGE = 35
local BASE_FOV = 70

local RED = Color3.fromRGB(230, 30, 40)
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

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
	TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * size,
		Transparency = 1,
	}):Play()
	Debris:AddItem(p, duration)
end

-- Onda expansiva: un anillo plano perpendicular a la dirección del golpe.
local function shockwave(position: Vector3, direction: Vector3?, color: Color3, size: number, duration: number)
	local axis = if direction and direction.Magnitude > 0.1 then direction.Unit else Vector3.yAxis
	-- El cilindro de Roblox tiene su eje en X; lo alineamos con la dirección del golpe.
	local cframe = CFrame.lookAt(position, position + axis) * CFrame.Angles(0, math.rad(90), 0)
	local ring = part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.15, 1, 1),
		CFrame = cframe,
		Color = color,
		Transparency = 0.1,
	})
	TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.05, size, size),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, duration)
end

-- Chispas que salen disparadas hacia delante desde el punto de impacto.
local function sparks(position: Vector3, direction: Vector3?, color: Color3, count: number, length: number)
	local forward = if direction and direction.Magnitude > 0.1 then direction.Unit else Vector3.zAxis
	for _ = 1, count do
		local spread = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 1.6
		local dir = (forward + spread).Unit
		local distance = length * (0.6 + math.random() * 0.6)
		local spark = part({
			Size = Vector3.new(0.12, 0.12, 1.2),
			CFrame = CFrame.lookAt(position, position + dir),
			Color = color,
		})
		TweenService:Create(spark, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(position + dir * distance, position + dir * (distance + 1)),
			Size = Vector3.new(0.04, 0.04, 0.3),
			Transparency = 1,
		}):Play()
		Debris:AddItem(spark, 0.2)
	end
end

-- Rayos negros y rojos alrededor del Black Flash.
local function lightning(position: Vector3, count: number, radius: number)
	for i = 1, count do
		local color = if i % 2 == 0 then RED else BLACK
		local start = position
		for _ = 1, 4 do
			local nextPoint = start + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * radius
			local length = (nextPoint - start).Magnitude
			local bolt = part({
				Size = Vector3.new(0.25, 0.25, length),
				CFrame = CFrame.lookAt(start, nextPoint) * CFrame.new(0, 0, -length / 2),
				Color = color,
			})
			TweenService:Create(bolt, TweenInfo.new(0.3), { Transparency = 1 }):Play()
			Debris:AddItem(bolt, 0.3)
			start = nextPoint
		end
	end
end

-- Sacudida de cámara: se aplica después de la cámara normal y del lock on.
local shakeIntensity = 0
local shakeDecay = 0

local function shake(position: Vector3, intensity: number, duration: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local distance = (root.Position - position).Magnitude
	if distance > SHAKE_RANGE then
		return
	end
	local scaled = intensity * (1 - distance / SHAKE_RANGE * 0.6)
	if scaled > shakeIntensity then
		shakeIntensity = scaled
		shakeDecay = scaled / duration
	end
end

RunService:BindToRenderStep("ImpactShake", Enum.RenderPriority.Camera.Value + 2, function(dt)
	if shakeIntensity <= 0 then
		return
	end
	local i = shakeIntensity
	local offset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * i * 0.6
	local tilt = CFrame.Angles(0, 0, math.rad((math.random() - 0.5) * i * 4))
	camera.CFrame = camera.CFrame * CFrame.new(offset) * tilt
	shakeIntensity = math.max(0, shakeIntensity - shakeDecay * dt)
end)

local function fovPunch(amount: number)
	camera.FieldOfView = BASE_FOV + amount
	TweenService:Create(camera, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = BASE_FOV,
	}):Play()
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
	text.TextSize = 72
	text.Text = "BLACK FLASH"
	text.TextColor3 = RED
	text.TextStrokeColor3 = BLACK
	text.TextStrokeTransparency = 0
	text.Rotation = -4
	text.Parent = gui
	TweenService:Create(text, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextSize = 56 }):Play()
	TweenService:Create(text, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(text, 1)

	-- Destello de pantalla
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = BLACK
	flash.BackgroundTransparency = 0.3
	flash.ZIndex = 0
	flash.Parent = gui
	TweenService:Create(flash, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	Debris:AddItem(flash, 0.25)
end

Remotes.Effect.OnClientEvent:Connect(function(kind: string, data)
	if kind == "Anim" then
		AnimationPlayer.Play(data.Character, data.Name)
	elseif kind == "AnimStop" then
		AnimationPlayer.Stop(data.Character, data.Name)
	elseif kind == "Hit" then
		local big = data.Finisher == true
		burst(data.Position, WHITE, if big then 6 else 3.5, 0.15)
		shockwave(data.Position, data.Direction, WHITE, if big then 14 else 8, 0.25)
		sparks(data.Position, data.Direction, Color3.fromRGB(255, 230, 180), if big then 10 else 6, if big then 8 else 5)
		shake(data.Position, if big then 0.9 else 0.4, if big then 0.25 else 0.15)
		if big then
			fovPunch(6)
		end
	elseif kind == "BlackFlash" then
		burst(data.Position, BLACK, 14, 0.4)
		burst(data.Position, RED, 9, 0.3)
		shockwave(data.Position, data.Direction, RED, 24, 0.4)
		shockwave(data.Position, data.Direction, BLACK, 16, 0.3)
		sparks(data.Position, data.Direction, RED, 16, 12)
		lightning(data.Position, 6, 5)
		shake(data.Position, 1.8, 0.4)
		fovPunch(12)
		blackFlashText(data.UserId)
	elseif kind == "Beam" then
		local length = (data.To - data.From).Magnitude
		local beam = part({
			Size = Vector3.new(0.8, 0.8, length),
			CFrame = CFrame.lookAt(data.From, data.To) * CFrame.new(0, 0, -length / 2),
			Color = Color3.fromRGB(180, 0, 20),
		})
		TweenService:Create(beam, TweenInfo.new(0.35), { Transparency = 1, Size = Vector3.new(0.1, 0.1, length) }):Play()
		Debris:AddItem(beam, 0.35)
		burst(data.To, Color3.fromRGB(180, 0, 20), 5, 0.25)
		shockwave(data.To, data.To - data.From, Color3.fromRGB(180, 0, 20), 8, 0.3)
		shake(data.From, 0.5, 0.2)
	elseif kind == "Sphere" then
		burst(data.Position, data.Color, data.Radius * 2, 0.5)
		shockwave(data.Position, Vector3.yAxis, data.Color, data.Radius * 3, 0.5)
		shake(data.Position, 1.2, 0.35)
		fovPunch(8)
	end
end)
