-- Valores de balance del prototipo. El servidor es la única fuente de verdad;
-- el cliente solo los lee para mostrar la interfaz.

local Config = {}

Config.MaxHealth = 100
Config.MaxEnergy = 100
Config.EnergyRegenPerSecond = 6

Config.M1 = {
	Damage = 5,
	FinisherDamage = 10, -- último golpe del combo
	ComboLength = 4,
	ComboResetTime = 1.2,
	Cooldown = 0.35,
	Range = 6,
}

-- Black Flash: si el siguiente M1 llega justo cuando termina el cooldown
-- (dentro de esta ventana), el golpe se multiplica.
Config.BlackFlash = {
	Window = 0.12,
	Multiplier = 2.5,
	EnergyReward = 25,
}

Config.Block = {
	DamageReduction = 0.8,
}

Config.Dodge = {
	Cooldown = 2,
	InvulnerableTime = 0.3,
	Speed = 70,
}

Config.Leveling = {
	MaxLevel = 100,
	XpForLevel = function(level: number): number
		return 100 * level
	end,
	XpPerCurse = 40,
}

-- Técnicas innatas. Cada movimiento usa un "Kind" que el servidor sabe ejecutar:
--   Ray   = disparo en línea recta, daña al primer objetivo
--   Pull  = atrae a todos hacia un punto y los daña
--   Blast = explosión que empuja lejos y daña
Config.Techniques = {
	Blood = {
		DisplayName = "Manipulación de Sangre",
		Rarity = "Común",
		Weight = 80,
		Moves = {
			Z = { Name = "Sangre Perforante", Kind = "Ray", Damage = 18, Range = 60, EnergyCost = 20, Cooldown = 4 },
			X = { Name = "Supernova", Kind = "Blast", Damage = 14, Radius = 10, Force = 50, EnergyCost = 25, Cooldown = 7 },
		},
	},
	Limitless = {
		DisplayName = "Infinito",
		Rarity = "Legendaria",
		Weight = 20,
		Moves = {
			Z = { Name = "Azul", Kind = "Pull", Damage = 12, Radius = 14, Range = 50, EnergyCost = 25, Cooldown = 6 },
			X = { Name = "Rojo", Kind = "Blast", Damage = 22, Radius = 12, Force = 110, EnergyCost = 40, Cooldown = 10 },
		},
	},
}

Config.MaxAimDistance = 120

Config.Curse = {
	Count = 5,
	Health = 60,
	Damage = 8,
	AttackRange = 5,
	AttackCooldown = 1.5,
	AggroRange = 45,
	WalkSpeed = 12,
	RespawnTime = 10,
}

return Config
