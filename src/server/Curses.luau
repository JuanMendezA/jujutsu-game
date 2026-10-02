-- Maldiciones enemigas básicas: persiguen al jugador más cercano, golpean
-- cuerpo a cuerpo, dan XP a quien las mata y reaparecen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Combat = require(script.Parent.Combat)
local PlayerData = require(script.Parent.PlayerData)

local Curses = {}

local container: Folder

local function spawnPoints(): { Vector3 }
	-- Si en el mapa hay una carpeta "CurseSpawns" con partes, se usan como puntos de aparición.
	local folder = workspace:FindFirstChild("CurseSpawns")
	local points = {}
	if folder then
		for _, part in folder:GetChildren() do
			if part:IsA("BasePart") then
				table.insert(points, part.Position + Vector3.new(0, 4, 0))
			end
		end
	end
	if #points == 0 then
		for i = 1, Config.Curse.Count do
			local angle = (i / Config.Curse.Count) * math.pi * 2
			table.insert(points, Vector3.new(math.cos(angle) * 40, 5, math.sin(angle) * 40))
		end
	end
	return points
end

local function buildCurse(): Model
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = Color3.fromRGB(70, 20, 90)
	description.TorsoColor = Color3.fromRGB(40, 10, 50)
	description.LeftArmColor = Color3.fromRGB(70, 20, 90)
	description.RightArmColor = Color3.fromRGB(70, 20, 90)
	description.LeftLegColor = Color3.fromRGB(40, 10, 50)
	description.RightLegColor = Color3.fromRGB(40, 10, 50)

	local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	model.Name = "Maldición"
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.MaxHealth = Config.Curse.Health
	humanoid.Health = Config.Curse.Health
	humanoid.WalkSpeed = Config.Curse.WalkSpeed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	return model
end

local function nearestPlayerRoot(position: Vector3): BasePart?
	local best, bestDistance = nil, Config.Curse.AggroRange
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and root and humanoid.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then
				best, bestDistance = root, distance
			end
		end
	end
	return best
end

local function run(spawnPosition: Vector3)
	local model = buildCurse()
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	model:PivotTo(CFrame.new(spawnPosition))
	model.Parent = container
	root:SetNetworkOwner(nil)

	local lastAttack = 0
	local alive = true

	humanoid.Died:Connect(function()
		alive = false
		local killerId = humanoid:GetAttribute("LastAttacker")
		local killer = killerId and Players:GetPlayerByUserId(killerId)
		if killer then
			PlayerData.AddXp(killer, Config.Leveling.XpPerCurse)
		end
		task.delay(3, function()
			model:Destroy()
		end)
		task.delay(Config.Curse.RespawnTime, run, spawnPosition)
	end)

	task.spawn(function()
		while alive and model.Parent do
			local target = nearestPlayerRoot(root.Position)
			if target then
				local distance = (target.Position - root.Position).Magnitude
				if distance <= Config.Curse.AttackRange then
					humanoid:MoveTo(root.Position)
					local now = os.clock()
					if now - lastAttack >= Config.Curse.AttackCooldown then
						lastAttack = now
						local targetHumanoid = target.Parent:FindFirstChildOfClass("Humanoid")
						if targetHumanoid then
							Combat.PlayAnim(model, "CurseAttack")
							Combat.DealDamage(nil, targetHumanoid, Config.Curse.Damage)
						end
					end
				else
					humanoid:MoveTo(target.Position)
				end
			else
				humanoid:MoveTo(spawnPosition)
			end
			task.wait(0.25)
		end
	end)
end

function Curses.Start()
	container = Instance.new("Folder")
	container.Name = "Curses"
	container.Parent = workspace

	for _, position in spawnPoints() do
		task.spawn(run, position)
	end
end

return Curses
