-- Reproduce las animaciones de Shared/Animations sobre cualquier personaje (R15 o R6).
-- Corre en cada cliente: el servidor avisa "este personaje hace X" y cada cliente lo anima.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Animations = require(ReplicatedStorage.Shared.Animations)

-- Nombre de cada articulación según el tipo de cuerpo.
local JOINT_NAMES = {
	Torso = { "Waist", "RootJoint" },
	Neck = { "Neck" },
	RightShoulder = { "RightShoulder", "Right Shoulder" },
	LeftShoulder = { "LeftShoulder", "Left Shoulder" },
	RightElbow = { "RightElbow" },
	LeftElbow = { "LeftElbow" },
	RightHip = { "RightHip", "Right Hip" },
	LeftHip = { "LeftHip", "Left Hip" },
	RightKnee = { "RightKnee" },
	LeftKnee = { "LeftKnee" },
}

type Rig = {
	Joints: { [string]: Motor6D },
	Rest: { [Motor6D]: CFrame },
	Token: number,
	Current: string?,
	Tracks: { [string]: AnimationTrack },
}

local AnimationPlayer = {}

local rigs: { [Model]: Rig } = setmetatable({}, { __mode = "k" }) :: any

local function getRig(character: Model): Rig
	local rig = rigs[character]
	if rig then
		return rig
	end
	rig = { Joints = {}, Rest = {}, Token = 0, Current = nil, Tracks = {} }
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") then
			for role, names in JOINT_NAMES do
				if not rig.Joints[role] and table.find(names, descendant.Name) then
					rig.Joints[role] = descendant
					rig.Rest[descendant] = descendant.C0
				end
			end
		end
	end
	rigs[character] = rig
	return rig
end

local function posed(rest: CFrame, angles: { number }?): CFrame
	if not angles then
		return rest
	end
	local rotation = CFrame.Angles(math.rad(angles[1]), math.rad(angles[2]), math.rad(angles[3]))
	-- Gira alrededor de la articulación usando los ejes del torso (igual en R15 y R6).
	return CFrame.new(rest.Position) * rotation * rest.Rotation
end

local function tweenPose(rig: Rig, pose: { [string]: { number } }?, time: number)
	local info = TweenInfo.new(math.max(time, 0.01), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for role, joint in rig.Joints do
		if joint.Parent then
			TweenService:Create(joint, info, { C0 = posed(rig.Rest[joint], pose and pose[role]) }):Play()
		end
	end
end

local function playTrack(character: Model, rig: Rig, name: string, id: string, hold: boolean?): boolean
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return false
	end
	local track = rig.Tracks[name]
	if not track then
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		track = animator:LoadAnimation(animation)
		track.Looped = hold == true
		rig.Tracks[name] = track
	end
	track:Play(0.05)
	return true
end

function AnimationPlayer.Play(character: Model, name: string)
	local animation = Animations.List[name]
	if not (character and character.Parent and animation) then
		return
	end
	local rig = getRig(character)
	rig.Token += 1
	rig.Current = name
	local token = rig.Token

	local id = Animations.AnimationIds[name]
	if id and id ~= "" and playTrack(character, rig, name, id, animation.Hold) then
		return
	end

	task.spawn(function()
		for _, keyframe in animation.Keyframes do
			if rig.Token ~= token then
				return
			end
			tweenPose(rig, keyframe.Pose, keyframe.Time)
			task.wait(keyframe.Time)
		end
		if rig.Token == token and not animation.Hold then
			tweenPose(rig, nil, animation.Recover)
			rig.Current = nil
		end
	end)
end

function AnimationPlayer.Stop(character: Model, name: string)
	local rig = character and rigs[character]
	if not rig then
		return
	end
	local track = rig.Tracks[name]
	if track then
		track:Stop(0.1)
	end
	if rig.Current == name then
		rig.Token += 1
		rig.Current = nil
		local animation = Animations.List[name]
		tweenPose(rig, nil, animation and animation.Recover or 0.15)
	end
end

return AnimationPlayer
