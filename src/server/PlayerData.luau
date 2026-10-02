-- Carga y guarda el progreso (nivel, XP y técnica) con DataStore.
-- Los valores se exponen como atributos del jugador para que la interfaz los lea.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local STORE_NAME = "PlayerData_v1"
local RETRIES = 3

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStore no disponible (¿API Services desactivado en Studio?):", result)
	end
end

type Data = { Level: number, Xp: number, Technique: string? }

local PlayerData = {}

local loaded: { [Player]: Data } = {}
-- Solo guardamos si la carga salió bien, para no sobrescribir datos reales con valores por defecto.
local canSave: { [Player]: boolean } = {}

local function keyFor(player: Player): string
	return "u_" .. player.UserId
end

local function withRetries<T>(fn: () -> T): (boolean, T | string)
	local ok, result
	for attempt = 1, RETRIES do
		ok, result = pcall(fn)
		if ok then
			return true, result
		end
		task.wait(attempt)
	end
	return false, result
end

local function rollTechnique(): string
	local total = 0
	for _, technique in Config.Techniques do
		total += technique.Weight
	end
	local roll = math.random() * total
	for id, technique in Config.Techniques do
		roll -= technique.Weight
		if roll <= 0 then
			return id
		end
	end
	return "Blood"
end

local function publish(player: Player, data: Data)
	player:SetAttribute("Level", data.Level)
	player:SetAttribute("Xp", data.Xp)
	player:SetAttribute("XpNeeded", Config.Leveling.XpForLevel(data.Level))
	player:SetAttribute("Technique", data.Technique)
end

function PlayerData.Load(player: Player)
	local data: Data = { Level = 1, Xp = 0, Technique = nil }
	local ok = true

	if store then
		local success, result = withRetries(function()
			return (store :: DataStore):GetAsync(keyFor(player))
		end)
		if success then
			if type(result) == "table" then
				data.Level = tonumber(result.Level) or 1
				data.Xp = tonumber(result.Xp) or 0
				if type(result.Technique) == "string" and Config.Techniques[result.Technique] then
					data.Technique = result.Technique
				end
			end
		else
			ok = false
			warn("[PlayerData] No se pudo cargar a", player.Name, result)
		end
	else
		ok = false
	end

	if not data.Technique then
		data.Technique = rollTechnique()
	end

	if not player.Parent then
		return
	end
	loaded[player] = data
	canSave[player] = ok
	publish(player, data)
end

function PlayerData.Save(player: Player)
	local data = loaded[player]
	if not (data and store and canSave[player]) then
		return
	end
	local success, err = withRetries(function()
		return (store :: DataStore):SetAsync(keyFor(player), {
			Level = data.Level,
			Xp = data.Xp,
			Technique = data.Technique,
		}, { player.UserId })
	end)
	if not success then
		warn("[PlayerData] No se pudo guardar a", player.Name, err)
	end
end

function PlayerData.Get(player: Player): Data?
	return loaded[player]
end

function PlayerData.AddXp(player: Player, amount: number)
	local data = loaded[player]
	if not data then
		return
	end
	data.Xp += amount
	while data.Level < Config.Leveling.MaxLevel and data.Xp >= Config.Leveling.XpForLevel(data.Level) do
		data.Xp -= Config.Leveling.XpForLevel(data.Level)
		data.Level += 1
	end
	publish(player, data)
end

function PlayerData.Start()
	Players.PlayerAdded:Connect(PlayerData.Load)
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerData.Load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		PlayerData.Save(player)
		loaded[player] = nil
		canSave[player] = nil
	end)

	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				PlayerData.Save(player)
				pending -= 1
			end)
		end
		while pending > 0 do
			task.wait()
		end
	end)
end

return PlayerData
