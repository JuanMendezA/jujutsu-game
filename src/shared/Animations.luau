-- Definición de animaciones.
--
-- Por defecto son procedurales: se mueven las articulaciones por código, así funcionan
-- sin subir nada a Roblox. Si más adelante creas animaciones en Studio (por ejemplo con
-- Moon Animator) y las publicas, pon su ID en AnimationIds y se usará la animación real.
--
-- Cada animación es una lista de keyframes con tres fases típicas:
--   1. Carga (anticipación): el cuerpo se echa hacia atrás para coger fuerza.
--   2. Impacto: muy rápido (Ease = "Quint") con todo el cuerpo hacia delante.
--   3. Asentado: el cuerpo cede un poco tras el impacto en lugar de quedarse rígido.
-- La función strike() arma esas tres fases a partir de la pose de carga y la de impacto.
-- Campos de cada keyframe:
--   Time  = segundos que tarda en llegar a la pose
--   Ease  = estilo de suavizado (Enum.EasingStyle), por defecto "Quad"
--   Dir   = dirección del suavizado (Enum.EasingDirection), por defecto "Out"
--   Pose  = giros por articulación en grados {X, Y, Z}, en los ejes del torso
-- Al final se vuelve a la pose normal en "Recover" segundos, salvo Hold = true.
--
-- Guía de ejes:
--   Brazos/piernas: X+ hacia delante, X- hacia atrás. Brazo derecho Z+ se abre hacia
--   fuera, Z- cruza el cuerpo (al revés en el izquierdo).
--   Codos/rodillas: codo X+ dobla el antebrazo, rodilla X- dobla la pierna.
--   Root (todo el cuerpo) y Torso: X- inclina hacia delante, X+ hacia atrás,
--   Y+ gira a la izquierda, Y- a la derecha, Z inclina de lado.
--   Neck: X- baja la barbilla, X+ mira arriba.

local Animations = {}

Animations.AnimationIds = {
	-- M1_1 = "rbxassetid://123456",
}

type Pose = { [string]: { number } }
type Keyframe = { Time: number, Pose: Pose, Ease: string?, Dir: string? }
export type Animation = { Keyframes: { Keyframe }, Recover: number, Hold: boolean? }

-- Pose de guardia con los puños arriba, reutilizada en las cargas.
local GUARD_ARMS = {
	RightShoulder = { 70, 0, -25 },
	RightElbow = { 110, 0, 0 },
	LeftShoulder = { 70, 0, 25 },
	LeftElbow = { 110, 0, 0 },
}

local function merge(...: Pose): Pose
	local result = {}
	for _, pose in { ... } do
		for joint, angles in pose do
			result[joint] = angles
		end
	end
	return result
end

-- Escala todos los giros de una pose (1 = igual, 0 = pose normal).
local function scale(pose: Pose, k: number): Pose
	local result = {}
	for joint, a in pose do
		result[joint] = { a[1] * k, a[2] * k, a[3] * k }
	end
	return result
end

-- Carga suave -> impacto rápido -> asentado. Los tiempos son {carga, impacto, asentado}.
local function strike(windup: Pose, impact: Pose, times: { number }): { Keyframe }
	return {
		{ Time = times[1], Ease = "Sine", Dir = "InOut", Pose = windup },
		{ Time = times[2], Ease = "Quint", Dir = "Out", Pose = impact },
		{ Time = times[3], Ease = "Sine", Dir = "Out", Pose = scale(impact, 0.85) },
	}
end

local RIGHT_STRAIGHT_IMPACT = {
	Root = { -10, 0, 0 },
	Torso = { -5, 50, 0 },
	Neck = { 0, -35, 0 },
	RightShoulder = { 95, 0, -12 },
	RightElbow = { 0, 0, 0 },
	LeftShoulder = { 55, 0, 30 },
	LeftElbow = { 120, 0, 0 },
	LeftHip = { 40, 0, 0 },
	LeftKnee = { -25, 0, 0 },
	RightHip = { -30, 0, 0 },
	RightKnee = { -20, 0, 0 },
}

local LEFT_STRAIGHT_IMPACT = {
	Root = { -10, 0, 0 },
	Torso = { -5, -50, 0 },
	Neck = { 0, 35, 0 },
	LeftShoulder = { 95, 0, 12 },
	LeftElbow = { 0, 0, 0 },
	RightShoulder = { 55, 0, -30 },
	RightElbow = { 120, 0, 0 },
	RightHip = { 40, 0, 0 },
	RightKnee = { -25, 0, 0 },
	LeftHip = { -30, 0, 0 },
	LeftKnee = { -20, 0, 0 },
}

local UPPERCUT_IMPACT = {
	Root = { 12, 0, 0 },
	Torso = { 8, 35, 0 },
	Neck = { 20, -20, 0 },
	RightShoulder = { 170, 0, -15 },
	RightElbow = { 25, 0, 0 },
	LeftShoulder = { 20, 0, 40 },
	LeftElbow = { 60, 0, 0 },
	RightHip = { -10, 0, 0 },
	LeftHip = { 15, 0, 0 },
}

local ROUNDHOUSE_IMPACT = {
	Root = { 0, 45, 15 },
	Torso = { 0, 20, 0 },
	Neck = { 0, -40, 0 },
	RightHip = { 20, 45, 95 },
	RightKnee = { 0, 0, 0 },
	LeftHip = { 0, 0, 10 },
	LeftKnee = { -15, 0, 0 },
	RightShoulder = { 20, 0, 80 },
	LeftShoulder = { 30, 0, -70 },
	LeftElbow = { 40, 0, 0 },
}

local BLACK_FLASH_IMPACT = {
	Root = { -16, 0, 0 },
	Torso = { -8, 65, 0 },
	Neck = { -10, -45, 0 },
	RightShoulder = { 100, 0, -5 },
	RightElbow = { 0, 0, 0 },
	LeftShoulder = { -45, 0, -25 },
	LeftElbow = { 30, 0, 0 },
	LeftHip = { 60, 0, 0 },
	LeftKnee = { -50, 0, 0 },
	RightHip = { -45, 0, 0 },
	RightKnee = { -10, 0, 0 },
}

local RAY_IMPACT = {
	Root = { -12, 0, 0 },
	Neck = { -5, 0, 0 },
	RightShoulder = { 95, 0, -8 },
	RightElbow = { 0, 0, 0 },
	LeftShoulder = { 95, 0, 8 },
	LeftElbow = { 0, 0, 0 },
	LeftHip = { 40, 0, 0 },
	LeftKnee = { -35, 0, 0 },
	RightHip = { -30, 0, 0 },
}

local BLAST_IMPACT = {
	Root = { -14, 0, 0 },
	Torso = { -5, 55, 0 },
	Neck = { 0, -40, 0 },
	RightShoulder = { 100, 0, -5 },
	RightElbow = { 0, 0, 0 },
	LeftShoulder = { -40, 0, -35 },
	LeftElbow = { 20, 0, 0 },
	LeftHip = { 55, 0, 0 },
	LeftKnee = { -45, 0, 0 },
	RightHip = { -40, 0, 0 },
}

local PULL_IMPACT = {
	Root = { -15, 0, 0 },
	Torso = { 0, 20, 0 },
	Neck = { -5, -15, 0 },
	RightShoulder = { 85, 0, -10 },
	RightElbow = { 0, 0, 0 },
	LeftShoulder = { 20, 0, 35 },
	LeftElbow = { 40, 0, 0 },
	LeftHip = { 30, 0, 0 },
	LeftKnee = { -25, 0, 0 },
}

Animations.List = {
	-- Combo M1: directo derecho, directo izquierdo, gancho ascendente y patada giratoria.
	M1_1 = {
		Keyframes = strike(merge(GUARD_ARMS, {
				Root = { 8, 0, 0 },
				Torso = { 0, -45, 0 },
				Neck = { 0, 30, 0 },
				RightShoulder = { 30, 0, 35 },
				RightElbow = { 120, 0, 0 },
				RightHip = { -10, 0, 0 },
			}), RIGHT_STRAIGHT_IMPACT, { 0.08, 0.05, 0.08 }),
		Recover = 0.18,
	},
	M1_2 = {
		Keyframes = strike(merge(GUARD_ARMS, {
				Root = { 8, 0, 0 },
				Torso = { 0, 45, 0 },
				Neck = { 0, -30, 0 },
				LeftShoulder = { 30, 0, -35 },
				LeftElbow = { 120, 0, 0 },
				LeftHip = { -10, 0, 0 },
			}), LEFT_STRAIGHT_IMPACT, { 0.08, 0.05, 0.08 }),
		Recover = 0.18,
	},
	M1_3 = {
		Keyframes = strike(merge(GUARD_ARMS, {
				Root = { -15, 0, 0 },
				Torso = { 0, -30, 0 },
				RightShoulder = { -35, 0, 15 },
				RightElbow = { 100, 0, 0 },
				RightHip = { 40, 0, 0 },
				RightKnee = { -60, 0, 0 },
				LeftHip = { 40, 0, 0 },
				LeftKnee = { -60, 0, 0 },
			}), UPPERCUT_IMPACT, { 0.1, 0.06, 0.1 }),
		Recover = 0.22,
	},
	M1_4 = {
		Keyframes = strike(merge(GUARD_ARMS, {
				Root = { 6, -30, -6 },
				Torso = { 0, -25, 0 },
				Neck = { 0, 50, 0 },
				RightHip = { -35, 0, 15 },
				RightKnee = { -70, 0, 0 },
				LeftKnee = { -25, 0, 0 },
			}), ROUNDHOUSE_IMPACT, { 0.12, 0.07, 0.14 }),
		Recover = 0.3,
	},
	BlackFlash = {
		Keyframes = strike({
				Root = { -12, 0, 0 },
				Torso = { 5, -75, 0 },
				Neck = { 0, 55, 0 },
				RightShoulder = { 20, 0, 65 },
				RightElbow = { 130, 0, 0 },
				LeftShoulder = { 95, 0, -35 },
				LeftElbow = { 50, 0, 0 },
				RightHip = { 45, 0, 0 },
				RightKnee = { -60, 0, 0 },
				LeftHip = { 30, 0, 0 },
				LeftKnee = { -50, 0, 0 },
			}, BLACK_FLASH_IMPACT, { 0.12, 0.05, 0.25 }),
		Recover = 0.35,
	},

	-- Defensa y movimiento
	Block = {
		Keyframes = {
			{ Time = 0.08, Ease = "Back", Pose = {
				Root = { -12, 0, 0 },
				Neck = { -20, 0, 0 },
				RightShoulder = { 115, 0, -55 },
				RightElbow = { 85, 0, 0 },
				LeftShoulder = { 115, 0, 55 },
				LeftElbow = { 85, 0, 0 },
				RightHip = { 25, 0, 0 },
				RightKnee = { -40, 0, 0 },
				LeftHip = { 25, 0, 0 },
				LeftKnee = { -40, 0, 0 },
			} },
		},
		Recover = 0.15,
		Hold = true,
	},
	Dodge = {
		Keyframes = {
			{ Time = 0.06, Ease = "Quint", Pose = {
				Root = { -45, 0, 0 },
				Neck = { 30, 0, 0 },
				RightShoulder = { -70, 0, 30 },
				LeftShoulder = { -70, 0, -30 },
				RightElbow = { 20, 0, 0 },
				LeftElbow = { 20, 0, 0 },
				RightHip = { 50, 0, 0 },
				RightKnee = { -70, 0, 0 },
				LeftHip = { -40, 0, 0 },
			} },
			{ Time = 0.22, Pose = {
				Root = { -40, 0, 0 },
				Neck = { 25, 0, 0 },
				RightShoulder = { -65, 0, 30 },
				LeftShoulder = { -65, 0, -30 },
				RightHip = { 45, 0, 0 },
				RightKnee = { -65, 0, 0 },
				LeftHip = { -35, 0, 0 },
			} },
		},
		Recover = 0.2,
	},
	HitReact = {
		Keyframes = {
			{ Time = 0.04, Ease = "Quint", Pose = {
				Root = { 28, 0, 0 },
				Torso = { 10, 15, 0 },
				Neck = { 40, 0, 0 },
				RightShoulder = { 60, 0, 60 },
				LeftShoulder = { 60, 0, -60 },
				RightElbow = { 50, 0, 0 },
				LeftElbow = { 50, 0, 0 },
				RightHip = { 20, 0, 0 },
				RightKnee = { -30, 0, 0 },
			} },
			{ Time = 0.12, Pose = {
				Root = { 22, 0, 0 },
				Torso = { 8, 12, 0 },
				Neck = { 30, 0, 0 },
				RightShoulder = { 50, 0, 55 },
				LeftShoulder = { 50, 0, -55 },
				RightElbow = { 45, 0, 0 },
				LeftElbow = { 45, 0, 0 },
			} },
		},
		Recover = 0.3,
	},

	-- Técnicas: carga larga y suelta explosiva.
	Cast_Ray = { -- Sangre Perforante
		Keyframes = strike({
				Root = { 12, 0, 0 },
				Neck = { -15, 0, 0 },
				RightShoulder = { 55, 0, -45 },
				RightElbow = { 125, 0, 0 },
				LeftShoulder = { 55, 0, 45 },
				LeftElbow = { 125, 0, 0 },
				RightHip = { 20, 0, 0 },
				RightKnee = { -35, 0, 0 },
				LeftHip = { 20, 0, 0 },
				LeftKnee = { -35, 0, 0 },
			}, RAY_IMPACT, { 0.2, 0.05, 0.3 }),
		Recover = 0.3,
	},
	Cast_Blast = { -- Supernova / Rojo
		Keyframes = strike({
				Root = { 10, 0, 0 },
				Torso = { 5, -80, 0 },
				Neck = { 0, 60, 0 },
				RightShoulder = { 15, 0, 75 },
				RightElbow = { 130, 0, 0 },
				LeftShoulder = { 90, 0, -35 },
				LeftElbow = { 25, 0, 0 },
				RightHip = { 35, 0, 0 },
				RightKnee = { -55, 0, 0 },
				LeftHip = { 25, 0, 0 },
				LeftKnee = { -40, 0, 0 },
			}, BLAST_IMPACT, { 0.28, 0.06, 0.3 }),
		Recover = 0.35,
	},
	Cast_Pull = { -- Azul
		Keyframes = strike({
				Root = { 15, 0, 0 },
				Torso = { 5, -15, 0 },
				Neck = { 30, 10, 0 },
				RightShoulder = { 178, 0, -5 },
				RightElbow = { 10, 0, 0 },
				LeftShoulder = { 30, 0, 40 },
				LeftElbow = { 70, 0, 0 },
			}, PULL_IMPACT, { 0.25, 0.06, 0.35 }),
		Recover = 0.3,
	},

	-- Maldiciones: golpe a dos manos desde muy arriba.
	CurseAttack = {
		Keyframes = {
			{ Time = 0.3, Ease = "Sine", Pose = {
				Root = { 22, 0, 0 },
				Neck = { 25, 0, 0 },
				RightShoulder = { 178, 0, 10 },
				LeftShoulder = { 178, 0, -10 },
				RightElbow = { 40, 0, 0 },
				LeftElbow = { 40, 0, 0 },
			} },
			{ Time = 0.07, Ease = "Quint", Pose = {
				Root = { -40, 0, 0 },
				Neck = { -15, 0, 0 },
				RightShoulder = { 45, 0, -10 },
				LeftShoulder = { 45, 0, 10 },
				RightElbow = { 0, 0, 0 },
				LeftElbow = { 0, 0, 0 },
				RightHip = { 40, 0, 0 },
				RightKnee = { -60, 0, 0 },
				LeftHip = { 40, 0, 0 },
				LeftKnee = { -60, 0, 0 },
			} },
			{ Time = 0.15, Pose = {
				Root = { -38, 0, 0 },
				RightShoulder = { 45, 0, -10 },
				LeftShoulder = { 45, 0, 10 },
				RightHip = { 40, 0, 0 },
				RightKnee = { -60, 0, 0 },
				LeftHip = { 40, 0, 0 },
				LeftKnee = { -60, 0, 0 },
			} },
		},
		Recover = 0.35,
	},
}

-- Movimiento de técnica -> animación
Animations.ForMoveKind = {
	Ray = "Cast_Ray",
	Blast = "Cast_Blast",
	Pull = "Cast_Pull",
}

return Animations
