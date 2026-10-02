-- Combate del lado del servidor: M1, bloqueo, esquiva, Black Flash, energía maldita
-- y técnicas innatas. El cliente solo pide acciones; aquí se valida todo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Animations = require(ReplicatedStorage.Shared.Animations)
local PlayerData = require(script.Parent.PlayerData)

type State = {
	LastM1: number,
	Combo: number,
	Blocking: boolean,
	InvulnerableUntil: number,
	DodgeReadyAt: number,
	MoveReadyAt: { [string]: number },
}

local Combat = {}

local function playAnim(character: Instance?, name: string)
	if character then
		Remotes.Effect:FireAllClients("Anim", { Character = character, Name = name })
	end
end

local function stopAnim(character: Instance?, name: string)
	if character then
		Remotes.Effect:FireAllClients("AnimStop", { Character = character, Name = name })
	end
end

Combat.PlayAnim = playAnim

local states: { [Player]: State } = {}

local function newState(): State
	return {
		LastM1 = 0,
		Combo = 0,
		Blocking = false,
		InvulnerableUntil = 0,
		DodgeReadyAt = 0,
		MoveReadyAt = {},
	}
end

local function getAliveRoot(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (humanoid and root) or humanoid.Health <= 0 then
		return nil, nil, nil
	end
	return character, humanoid, root
end

local function humanoidFromPart(part: BasePart): Humanoid?
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

-- Devuelve los humanoides vivos dentro de una esfera, sin repetir y sin el atacante.
local function humanoidsInRadius(center: Vector3, radius: number, exclude: Model): { Humanoid }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { exclude }

	local found: { [Humanoid]: boolean } = {}
	local list = {}
	for _, part in workspace:GetPartBoundsInRadius(center, radius, params) do
		local humanoid = humanoidFromPart(part)
		if humanoid and humanoid.Health > 0 and not found[humanoid] then
			found[humanoid] = true
			table.insert(list, humanoid)
		end
	end
	return list
end

local function energy(player: Player): number
	return player:GetAttribute("Energy") or 0
end

local function setEnergy(player: Player, value: number)
	player:SetAttribute("Energy", math.clamp(value, 0, Config.MaxEnergy))
end

-- Aplica daño respetando bloqueo e invulnerabilidad del objetivo si es un jugador.
function Combat.DealDamage(attacker: Player?, target: Humanoid, amount: number)
	local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
	local blocking = false
	if targetPlayer then
		local state = states[targetPlayer]
		if state then
			if os.clock() < state.InvulnerableUntil then
				return
			end
			if state.Blocking then
				blocking = true
				amount *= 1 - Config.Block.DamageReduction
			end
		end
	end
	if attacker then
		target:SetAttribute("LastAttacker", attacker.UserId)
	end
	target:TakeDamage(amount)
	if not blocking and target.Health > 0 then
		playAnim(target.Parent, "HitReact")
	end
end

local function push(target: Humanoid, velocity: Vector3)
	local root = target.Parent and target.Parent:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.AssemblyLinearVelocity = velocity
	end
end

local function onM1(player: Player, state: State)
	local character, humanoid, root = getAliveRoot(player)
	if not (character and humanoid and root) or state.Blocking then
		return
	end

	local now = os.clock()
	local sinceLast = now - state.LastM1
	if sinceLast < Config.M1.Cooldown then
		return
	end

	local isBlackFlash = state.Combo > 0 and sinceLast <= Config.M1.Cooldown + Config.BlackFlash.Window
	if sinceLast > Config.M1.ComboResetTime or state.Combo >= Config.M1.ComboLength then
		state.Combo = 0
	end
	state.Combo += 1
	state.LastM1 = now

	local isFinisher = state.Combo == Config.M1.ComboLength
	local damage = if isFinisher then Config.M1.FinisherDamage else Config.M1.Damage

	local center = root.Position + root.CFrame.LookVector * (Config.M1.Range / 2)
	local targets = humanoidsInRadius(center, Config.M1.Range / 2, character)
	if isBlackFlash and #targets > 0 then
		playAnim(character, "BlackFlash")
	else
		playAnim(character, "M1_" .. state.Combo)
	end
	if #targets == 0 then
		return
	end

	if isBlackFlash then
		damage *= Config.BlackFlash.Multiplier
		setEnergy(player, energy(player) + Config.BlackFlash.EnergyReward)
		Remotes.Effect:FireAllClients("BlackFlash", { Position = center, UserId = player.UserId })
	else
		Remotes.Effect:FireAllClients("Hit", { Position = center })
	end

	for _, target in targets do
		Combat.DealDamage(player, target, damage)
		if isFinisher then
			push(target, root.CFrame.LookVector * 40 + Vector3.new(0, 15, 0))
		end
	end
end

local function onDodge(player: Player, state: State)
	local _, _, root = getAliveRoot(player)
	local now = os.clock()
	if not root or now < state.DodgeReadyAt then
		return
	end
	state.DodgeReadyAt = now + Config.Dodge.Cooldown
	state.InvulnerableUntil = now + Config.Dodge.InvulnerableTime
	playAnim(root.Parent, "Dodge")
end

local MoveKinds = {}

function MoveKinds.Ray(player: Player, character: Model, root: BasePart, aim: Vector3, move)
	local direction = (aim - root.Position).Unit * move.Range
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(root.Position, direction, params)
	local hitPosition = if result then result.Position else root.Position + direction
	Remotes.Effect:FireAllClients("Beam", { From = root.Position, To = hitPosition, Move = move.Name })

	if result then
		local target = humanoidFromPart(result.Instance)
		if target and target.Health > 0 then
			Combat.DealDamage(player, target, move.Damage)
		end
	end
end

function MoveKinds.Pull(player: Player, character: Model, root: BasePart, aim: Vector3, move)
	local offset = aim - root.Position
	if offset.Magnitude > move.Range then
		offset = offset.Unit * move.Range
	end
	local center = root.Position + offset
	Remotes.Effect:FireAllClients("Sphere", { Position = center, Radius = move.Radius, Color = Color3.fromRGB(60, 120, 255) })

	for _, target in humanoidsInRadius(center, move.Radius, character) do
		local targetRoot = target.Parent:FindFirstChild("HumanoidRootPart") :: BasePart?
		if targetRoot then
			push(target, (center - targetRoot.Position) * 4)
		end
		Combat.DealDamage(player, target, move.Damage)
	end
end

function MoveKinds.Blast(player: Player, character: Model, root: BasePart, aim: Vector3, move)
	local flat = Vector3.new(aim.X - root.Position.X, 0, aim.Z - root.Position.Z)
	local direction = if flat.Magnitude > 0.1 then flat.Unit else root.CFrame.LookVector
	local center = root.Position + direction * (move.Radius * 0.8)
	Remotes.Effect:FireAllClients("Sphere", { Position = center, Radius = move.Radius, Color = Color3.fromRGB(230, 40, 40) })

	for _, target in humanoidsInRadius(center, move.Radius, character) do
		local targetRoot = target.Parent:FindFirstChild("HumanoidRootPart") :: BasePart?
		if targetRoot then
			local away = targetRoot.Position - root.Position
			away = if away.Magnitude > 0.1 then away.Unit else direction
			push(target, away * move.Force + Vector3.new(0, move.Force * 0.3, 0))
		end
		Combat.DealDamage(player, target, move.Damage)
	end
end

local function onTechnique(player: Player, state: State, key: unknown, aim: unknown)
	if (key ~= "Z" and key ~= "X") or typeof(aim) ~= "Vector3" then
		return
	end
	local aimPosition = aim :: Vector3
	if aimPosition ~= aimPosition or aimPosition.Magnitude > 1e6 then -- NaN o valores absurdos
		return
	end

	local character, _, root = getAliveRoot(player)
	local data = PlayerData.Get(player)
	if not (character and root and data and data.Technique) or state.Blocking then
		return
	end
	if (aimPosition - root.Position).Magnitude > Config.MaxAimDistance then
		return
	end

	local move = Config.Techniques[data.Technique].Moves[key :: string]
	local now = os.clock()
	if not move or now < (state.MoveReadyAt[key :: string] or 0) or energy(player) < move.EnergyCost then
		return
	end

	state.MoveReadyAt[key :: string] = now + move.Cooldown
	setEnergy(player, energy(player) - move.EnergyCost)
	player:SetAttribute("Cooldown_" .. (key :: string), workspace:GetServerTimeNow() + move.Cooldown)
	playAnim(character, Animations.ForMoveKind[move.Kind])
	MoveKinds[move.Kind](player, character, root, aimPosition, move)
end

local function onCharacter(player: Player, character: Model)
	states[player] = newState()
	setEnergy(player, Config.MaxEnergy)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.MaxHealth = Config.MaxHealth
	humanoid.Health = Config.MaxHealth
end

function Combat.Start()
	Remotes.Action.OnServerEvent:Connect(function(player, action: unknown, a: unknown, b: unknown)
		local state = states[player]
		if not state then
			return
		end
		if action == "M1" then
			onM1(player, state)
		elseif action == "Block" then
			local blocking = a == true
			if blocking ~= state.Blocking then
				state.Blocking = blocking
				player:SetAttribute("Blocking", blocking)
				if blocking then
					playAnim(player.Character, "Block")
				else
					stopAnim(player.Character, "Block")
				end
			end
		elseif action == "Dodge" then
			onDodge(player, state)
		elseif action == "Technique" then
			onTechnique(player, state, a, b)
		end
	end)

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			onCharacter(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	RunService.Heartbeat:Connect(function(dt)
		for player in states do
			setEnergy(player, energy(player) + Config.EnergyRegenPerSecond * dt)
		end
	end)
end

return Combat
