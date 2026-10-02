-- Definición de animaciones.
--
-- Por defecto son procedurales: se mueven las articulaciones por código, así funcionan
-- sin subir nada a Roblox. Si más adelante creas animaciones en Studio (por ejemplo con
-- Moon Animator) y las publicas, pon su ID en AnimationIds y se usará la animación real.
--
-- Cada animación es una lista de keyframes con tres fases típicas:
--   1. Carga (anticipación): el cuerpo se echa hacia atrás para coger fuerza.
--   2. Impacto: muy rápido (Ease = "Exponential") con todo el cuerpo hacia delante.
--   3. Congelado: se mantiene la pose un instante para que el golpe "pese".
-- Campos de cada keyframe:
--   Time  = segundos que tarda en llegar a la pose
--   Ease  = estilo de suavizado (Enum.EasingStyle), por defecto "Quad"
--   Lunge = impulso hacia delante (studs/s) al empezar ese keyframe; solo se aplica al
--           personaje propio
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
type Keyframe = { Time: number, Pose: Pose, Ease: string?, Lunge: number? }
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

local RIGHT_STRAIGHT_IMPACT = {
	Root = { -18, 0, 0 },
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
	Root = { -18, 0, 0 },
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
	Root = { 0, 80, 30 },
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
	Root = { -28, 0, 0 },
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
	Root = { -20, 0, 0 },
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
	Root = { -25, 0, 0 },
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
		Keyframes = {
			{ Time = 0.08, Ease = "Sine", Pose = merge(GUARD_ARMS, {
				Root = { 8, 0, 0 },
				Torso = { 0, -45, 0 },
				Neck = { 0, 30, 0 },
				RightShoulder = { 30, 0, 35 },
				RightElbow = { 120, 0, 0 },
				RightHip = { -10, 0, 0 },
			}) },
			{ Time = 0.05, Ease = "Exponential", Lunge = 22, Pose = RIGHT_STRAIGHT_IMPACT },
			{ Time = 0.08, Pose = RIGHT_STRAIGHT_IMPACT },
		},
		Recover = 0.18,
	},
	M1_2 = {
		Keyframes = {
			{ Time = 0.08, Ease = "Sine", Pose = merge(GUARD_ARMS, {
				Root = { 8, 0, 0 },
				Torso = { 0, 45, 0 },
				Neck = { 0, -30, 0 },
				LeftShoulder = { 30, 0, -35 },
				LeftElbow = { 120, 0, 0 },
				LeftHip = { -10, 0, 0 },
			}) },
			{ Time = 0.05, Ease = "Exponential", Lunge = 22, Pose = LEFT_STRAIGHT_IMPACT },
			{ Time = 0.08, Pose = LEFT_STRAIGHT_IMPACT },
		},
		Recover = 0.18,
	},
	M1_3 = {
		Keyframes = {
			{ Time = 0.1, Ease = "Sine", Pose = merge(GUARD_ARMS, {
				Root = { -15, 0, 0 },
				Torso = { 0, -30, 0 },
				RightShoulder = { -35, 0, 15 },
				RightElbow = { 100, 0, 0 },
				RightHip = { 40, 0, 0 },
				RightKnee = { -60, 0, 0 },
				LeftHip = { 40, 0, 0 },
				LeftKnee = { -60, 0, 0 },
			}) },
			{ Time = 0.06, Ease = "Exponential", Lunge = 18, Pose = UPPERCUT_IMPACT },
			{ Time = 0.1, Pose = UPPERCUT_IMPACT },
		},
		Recover = 0.22,
	},
	M1_4 = {
		Keyframes = {
			{ Time = 0.12, Ease = "Sine", Pose = merge(GUARD_ARMS, {
				Root = { 10, -50, -10 },
				Torso = { 0, -25, 0 },
				Neck = { 0, 50, 0 },
				RightHip = { -35, 0, 15 },
				RightKnee = { -70, 0, 0 },
				LeftKnee = { -25, 0, 0 },
			}) },
			{ Time = 0.07, Ease = "Exponential", Lunge = 28, Pose = ROUNDHOUSE_IMPACT },
			{ Time = 0.14, Pose = ROUNDHOUSE_IMPACT },
		},
		Recover = 0.3,
	},
	BlackFlash = {
		Keyframes = {
			{ Time = 0.12, Ease = "Sine", Pose = {
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
			} },
			{ Time = 0.05, Ease = "Exponential", Lunge = 40, Pose = BLACK_FLASH_IMPACT },
			{ Time = 0.25, Pose = BLACK_FLASH_IMPACT },
		},
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
			{ Time = 0.06, Ease = "Exponential", Pose = {
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
			{ Time = 0.04, Ease = "Exponential", Pose = {
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
		Keyframes = {
			{ Time = 0.2, Ease = "Sine", Pose = {
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
			} },
			{ Time = 0.05, Ease = "Exponential", Lunge = 15, Pose = RAY_IMPACT },
			{ Time = 0.3, Pose = RAY_IMPACT },
		},
		Recover = 0.3,
	},
	Cast_Blast = { -- Supernova / Rojo
		Keyframes = {
			{ Time = 0.28, Ease = "Sine", Pose = {
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
			} },
			{ Time = 0.06, Ease = "Exponential", Lunge = 25, Pose = BLAST_IMPACT },
			{ Time = 0.3, Pose = BLAST_IMPACT },
		},
		Recover = 0.35,
	},
	Cast_Pull = { -- Azul
		Keyframes = {
			{ Time = 0.25, Ease = "Sine", Pose = {
				Root = { 15, 0, 0 },
				Torso = { 5, -15, 0 },
				Neck = { 30, 10, 0 },
				RightShoulder = { 178, 0, -5 },
				RightElbow = { 10, 0, 0 },
				LeftShoulder = { 30, 0, 40 },
				LeftElbow = { 70, 0, 0 },
			} },
			{ Time = 0.06, Ease = "Exponential", Pose = PULL_IMPACT },
			{ Time = 0.35, Pose = PULL_IMPACT },
		},
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
			{ Time = 0.07, Ease = "Exponential", Pose = {
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
