-- Lane indices are centered on zero: -2, -1, 0, 1, 2.
local Config = {}
Config.Track = {LaneCount = 5, LaneWidth = 6, ChunkLength = 100}
Config.Crouch = {HeightReduction = 0.9, FastFallSpeed = 65, JumpBuffer = 0.2}
Config.Speed = {Base = 26, PerCoin = 0.2, Max = 42, Acceleration = 6}
Config.SpeedRoutes = {
	Enabled = true, FirstChunk = 3, EveryChunks = 6, Bonus = 10, Duration = 3, Acceleration = 24,
	MinSteps = 2, MaxSteps = 4, MinSpacing = 76, MaxSpacing = 92, MaxBonus = 22, MaxDuration = 7,
}
Config.Drafting = {Enabled = true, MinDistance = 4, MaxDistance = 28, LateralRange = 2.5, ChargeTime = 1.4, Bonus = 6, Duration = 2, Cooldown = 3}
Config.PowerUps = {
	Enabled = true, FirstChunk = 2, EveryChunks = 2, PickupRadius = 2.7, RespawnTime = 8,
	Catalog = {
		{Id = "Boomerang", Name = "Bumeran"},
		{Id = "Lightning", Name = "Rayo"},
		{Id = "MouseTrap", Name = "Trampa"},
		{Id = "Sneakers", Name = "Zapatillas"},
		{Id = "Egg", Name = "Huevo"},
	},
}
Config.CoinRespawnTime = 6
Config.Abilities = {
	SneakersDuration = 4, SneakersMaxSpeed = 80, SneakersAcceleration = 28, SneakersBraking = 40, StunDuration = 1,
	LightningLoss = 0.3, BoomerangLoss = 0.15, HitProtection = 1.5,
	SlowDuration = 2.5, SlowMultiplier = 0.6, BaitCoins = 3,
	EggDuration = 1.5, EggSpeed = 110, EggLifetime = 2,
	TrapLifetime = 12, MaxObjects = 32,
}
Config.MotionEffects = {
	Enabled = true,
	Intensity = 1, -- Set to 0 for a steady camera; values are capped at 1.
	BaseFOV = 75, SpeedFOV = 10,
	MaxRollDegrees = 2.5,
	LandingDip = 0.3, CrashShake = 0.22,
	JumpLift = 0.18, LaneSway = 0.35,
}
Config.Obstacles = {
	Enabled = true,
	Seed = 473,
	FirstChunk = 1,
	RowEveryChunks = 1,
	SpawnChance = 0.99,
	PositionJitter = 20,
	ExtraTruckChance = 0.65,
	TruckSignChance = 0.9,
	WideSignChance = 0.5,
	SignJumpChance = 0.55,
	SignJumpOffset = 20,
	RampBarrierChance = 0.85,
	MaxTruckWidth = 3,
	TruckHeight = 16,
	TruckLength = 28,
	RampLength = 28,
	BarrierHeight = 2.2,
	SignBottom = 3,
	SignTop = 6.5,
}
Config.Crash = {
	BacktrackDistance = 55, PauseDuration = 0.5, ProtectionDuration = 1.25,
	RecoilHeight = 1.6, RecoilTiltDegrees = 12,
	BlinkInterval = 0.1, BlinkTransparency = 0.75,
}
Config.Trains = {
	Enabled = true, Speed = 38, Length = 52, Height = 11,
	SpawnDistance = 260, MinSpawnDistance = 220, MaxSpawnDistance = 340,
	MinInterval = 7, MaxInterval = 12,
	MaxActive = 3, DespawnDistance = 100,
}
-- A lane change starts at 0.2 s and reaches 0.6 s after 80 pickups.
Config.LaneChange = {BaseDuration = 0.2, SecondsPerCoin = 0.005, MaxDuration = 0.6}
Config.DefaultMode = "Classic"
Config.Developers = {
	UserIds = {}, -- Add published-game developer UserIds here; the user-owned experience creator also has access.
	AllowStudio = true, -- Studio test sessions only; this does not grant access in a published server.
}
Config.Matches = {
	Intermission = 10,
	DefaultMode = "Race",
	Modes = {
		Race = {DisplayName = "Carrera", Duration = 180, Distance = 3600, CoinMode = "Classic"},
		Elimination = {DisplayName = "Corre que te atrapan", Duration = 300, Distance = 1000000, CoinMode = "Classic", CaptureInterval = 20},
	},
}
Config.CoinModes = {
	Classic = {
		Enabled = true,
		Seed = 8127,
		SpawnChance = 0.85,
		LinesPerChunk = 2,
		CoinsPerLine = 6,
		MinCoinsPerLine = 3,
		Spacing = 6,
		Value = 1,
		Height = 3,
		PickupRadius = 2.5,
		AllowedLanes = {-2, -1, 0, 1, 2},
	},
	CoinRush = {
		Speed = {Base = 26, PerCoin = 0.2, Max = 48, Acceleration = 6},
		Enabled = true,
		Seed = 9271,
		SpawnChance = 1,
		LinesPerChunk = 5,
		CoinsPerLine = 10,
		MinCoinsPerLine = 6,
		Spacing = 8,
		Value = 2,
		Height = 3,
		PickupRadius = 2.5,
		AllowedLanes = {-2, -1, 0, 1, 2},
	},
	NoCoins = {
		Enabled = false,
		Speed = {Base = 26, PerCoin = 0, Max = 26},
		LaneChange = {BaseDuration = 0.2, SecondsPerCoin = 0, MaxDuration = 0.2},
	},
}
return Config
