-- Reproduce las animaciones de Shared/Animations sobre cualquier personaje (R15 o R6).
-- Corre en cada cliente: el servidor avisa "este personaje hace X" y cada cliente lo anima.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Animations = require(ReplicatedStorage.Shared.Animations)

-- Nombre de cada articulación según el tipo de cuerpo.
local JOINT_NAMES = {
	Root = { "Root" }, -- solo R15; en R6 el cuerpo entero se mueve con Torso (RootJoint)
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

-- Lo que se mueve de cada articulación. Con Motor6D es su C0; con el sistema nuevo de
-- Roblox (Avatar Joint Upgrade, AnimationConstraint) es el CFrame de su Attachment0.
type Joint = { Target: Instance, Property: string }

type Rig = {
	Joints: { [string]: Joint },
	Rest: { [Instance]: CFrame },
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
		local joint: Joint? = nil
		if descendant:IsA("Motor6D") then
			joint = { Target = descendant, Property = "C0" }
		elseif descendant:IsA("AnimationConstraint") and descendant.Attachment0 then
			joint = { Target = descendant.Attachment0, Property = "CFrame" }
		end
		if joint then
			for role, names in JOINT_NAMES do
				if not rig.Joints[role] and table.find(names, descendant.Name) then
					rig.Joints[role] = joint
					rig.Rest[joint.Target] = (joint.Target :: any)[joint.Property]
				end
			end
		end
	end
	if next(rig.Joints) == nil then
		warn("[AnimationPlayer] No se encontraron articulaciones en", character:GetFullName())
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

local function tweenPose(rig: Rig, pose: { [string]: { number } }?, time: number, ease: string?, dir: string?)
	local style = (ease and (Enum.EasingStyle :: any)[ease]) or Enum.EasingStyle.Quad
	local direction = (dir and (Enum.EasingDirection :: any)[dir]) or Enum.EasingDirection.Out
	local info = TweenInfo.new(math.max(time, 0.01), style, direction)
	for role, joint in rig.Joints do
		if joint.Target.Parent then
			local goal = { [joint.Property] = posed(rig.Rest[joint.Target], pose and pose[role]) }
			TweenService:Create(joint.Target, info, goal):Play()
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
			tweenPose(rig, keyframe.Pose, keyframe.Time, keyframe.Ease, keyframe.Dir)
			task.wait(keyframe.Time)
		end
		if rig.Token == token and not animation.Hold then
			tweenPose(rig, nil, animation.Recover, "Cubic", "InOut")
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
