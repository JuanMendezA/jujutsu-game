-- Definición de animaciones.
--
-- Por defecto son procedurales: se mueven las articulaciones (Motor6D) por código,
-- así funcionan sin subir nada a Roblox. Si más adelante creas animaciones en Studio
-- (por ejemplo con Moon Animator) y las publicas, pon su ID en AnimationIds y se
-- usará la animación real en lugar de la procedural.
--
-- Cada animación es una lista de keyframes. Cada keyframe gira articulaciones
-- (en grados, X/Y/Z en el espacio del torso) durante "Time" segundos. Al final se
-- vuelve a la pose normal en "Recover" segundos, salvo que Hold = true (se mantiene
-- hasta que llegue AnimStop, como el bloqueo).
--
-- Ejes útiles: X positivo levanta brazos/piernas hacia delante; Y positivo gira
-- a la izquierda; Z positivo abre hacia la derecha.

local Animations = {}

Animations.AnimationIds = {
	-- M1_1 = "rbxassetid://123456",
}

type Pose = { [string]: { number } }
type Keyframe = { Time: number, Pose: Pose }
export type Animation = { Keyframes: { Keyframe }, Recover: number, Hold: boolean? }

Animations.List = {
	-- Combo M1
	M1_1 = { -- jab derecho
		Keyframes = {
			{ Time = 0.06, Pose = { Torso = { 0, -20, 0 }, RightShoulder = { 20, 0, 0 } } },
			{ Time = 0.08, Pose = { Torso = { 0, 25, 0 }, RightShoulder = { 90, 0, -10 }, RightElbow = { 0, 0, 0 } } },
		},
		Recover = 0.18,
	},
	M1_2 = { -- jab izquierdo
		Keyframes = {
			{ Time = 0.06, Pose = { Torso = { 0, 20, 0 }, LeftShoulder = { 20, 0, 0 } } },
			{ Time = 0.08, Pose = { Torso = { 0, -25, 0 }, LeftShoulder = { 90, 0, 10 } } },
		},
		Recover = 0.18,
	},
	M1_3 = { -- gancho derecho
		Keyframes = {
			{ Time = 0.08, Pose = { Torso = { 0, -35, 0 }, RightShoulder = { 40, 0, 60 }, RightElbow = { 60, 0, 0 } } },
			{ Time = 0.1, Pose = { Torso = { 0, 40, 0 }, RightShoulder = { 90, 50, -40 }, RightElbow = { 40, 0, 0 } } },
		},
		Recover = 0.2,
	},
	M1_4 = { -- patada final
		Keyframes = {
			{ Time = 0.1, Pose = { Torso = { -10, 0, 0 }, RightHip = { 50, 0, 0 }, RightKnee = { -80, 0, 0 } } },
			{ Time = 0.1, Pose = { Torso = { 15, 0, 0 }, RightHip = { 95, 0, 0 }, RightKnee = { 0, 0, 0 }, LeftShoulder = { 30, 0, 40 }, RightShoulder = { 30, 0, -40 } } },
		},
		Recover = 0.3,
	},
	BlackFlash = { -- golpe con todo el cuerpo
		Keyframes = {
			{ Time = 0.08, Pose = { Torso = { 10, -45, 0 }, RightShoulder = { 30, 0, 40 }, RightElbow = { 90, 0, 0 } } },
			{ Time = 0.08, Pose = { Torso = { -20, 50, 0 }, RightShoulder = { 100, 0, -10 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { -30, 0, 0 } } },
			{ Time = 0.15, Pose = { Torso = { -20, 50, 0 }, RightShoulder = { 100, 0, -10 }, LeftShoulder = { -30, 0, 0 } } },
		},
		Recover = 0.3,
	},

	-- Defensa y movimiento
	Block = {
		Keyframes = {
			{ Time = 0.1, Pose = { Torso = { -10, 0, 0 }, Neck = { -10, 0, 0 }, RightShoulder = { 100, 0, -45 }, LeftShoulder = { 100, 0, 45 }, RightElbow = { 70, 0, 0 }, LeftElbow = { 70, 0, 0 } } },
		},
		Recover = 0.15,
		Hold = true,
	},
	Dodge = {
		Keyframes = {
			{ Time = 0.08, Pose = { Torso = { -35, 0, 0 }, RightShoulder = { -50, 0, 0 }, LeftShoulder = { -50, 0, 0 }, RightHip = { 30, 0, 0 }, LeftHip = { -30, 0, 0 } } },
			{ Time = 0.2, Pose = { Torso = { -35, 0, 0 }, RightShoulder = { -50, 0, 0 }, LeftShoulder = { -50, 0, 0 }, RightHip = { 30, 0, 0 }, LeftHip = { -30, 0, 0 } } },
		},
		Recover = 0.2,
	},
	HitReact = {
		Keyframes = {
			{ Time = 0.05, Pose = { Torso = { 20, 0, 0 }, Neck = { 25, 0, 0 }, RightShoulder = { 30, 0, 30 }, LeftShoulder = { 30, 0, -30 } } },
		},
		Recover = 0.25,
	},

	-- Técnicas
	Cast_Ray = { -- Sangre Perforante: manos juntas apuntando
		Keyframes = {
			{ Time = 0.15, Pose = { Torso = { 0, 0, 0 }, RightShoulder = { 70, 0, -30 }, LeftShoulder = { 70, 0, 30 }, RightElbow = { 90, 0, 0 }, LeftElbow = { 90, 0, 0 } } },
			{ Time = 0.08, Pose = { Torso = { -10, 0, 0 }, RightShoulder = { 90, 0, -15 }, LeftShoulder = { 90, 0, 15 } } },
			{ Time = 0.2, Pose = { Torso = { -10, 0, 0 }, RightShoulder = { 90, 0, -15 }, LeftShoulder = { 90, 0, 15 } } },
		},
		Recover = 0.25,
	},
	Cast_Blast = { -- Supernova / Rojo: carga a un lado y empuja hacia delante
		Keyframes = {
			{ Time = 0.18, Pose = { Torso = { 0, -40, 0 }, RightShoulder = { 30, 0, 50 }, RightElbow = { 100, 0, 0 }, LeftShoulder = { 60, 0, 0 } } },
			{ Time = 0.08, Pose = { Torso = { -15, 30, 0 }, RightShoulder = { 95, 0, -10 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { -20, 0, 0 } } },
			{ Time = 0.2, Pose = { Torso = { -15, 30, 0 }, RightShoulder = { 95, 0, -10 }, LeftShoulder = { -20, 0, 0 } } },
		},
		Recover = 0.3,
	},
	Cast_Pull = { -- Azul: levanta la mano y la baja apuntando
		Keyframes = {
			{ Time = 0.15, Pose = { Torso = { 10, 0, 0 }, RightShoulder = { 160, 0, -10 }, Neck = { -15, 0, 0 } } },
			{ Time = 0.1, Pose = { Torso = { -10, 0, 0 }, RightShoulder = { 85, 0, -10 }, RightElbow = { 10, 0, 0 } } },
			{ Time = 0.25, Pose = { Torso = { -10, 0, 0 }, RightShoulder = { 85, 0, -10 } } },
		},
		Recover = 0.25,
	},

	-- Maldiciones
	CurseAttack = { -- golpe con los dos brazos desde arriba
		Keyframes = {
			{ Time = 0.25, Pose = { Torso = { 15, 0, 0 }, RightShoulder = { 170, 0, 0 }, LeftShoulder = { 170, 0, 0 } } },
			{ Time = 0.1, Pose = { Torso = { -25, 0, 0 }, RightShoulder = { 60, 0, 0 }, LeftShoulder = { 60, 0, 0 } } },
		},
		Recover = 0.3,
	},
}

-- Movimiento de técnica -> animación
Animations.ForMoveKind = {
	Ray = "Cast_Ray",
	Blast = "Cast_Blast",
	Pull = "Cast_Pull",
}

return Animations
