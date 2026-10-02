-- Crea (en el servidor) o espera (en el cliente) los RemoteEvents del juego.
--   Action: cliente -> servidor, "quiero hacer X"
--   Effect: servidor -> clientes, efectos visuales y avisos

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"
local NAMES = { "Action", "Effect" }

local folder: Folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

return {
	Action = folder:WaitForChild("Action") :: RemoteEvent,
	Effect = folder:WaitForChild("Effect") :: RemoteEvent,
}
