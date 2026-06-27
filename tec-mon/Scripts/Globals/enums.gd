extends Node

enum TecmonType #all the types for the tecmons
{
	NONE,
	NORMAL,
	FIRE,
	WATER,
	GRASS,
	ELECTRIC,
	ICE,
	FIGHTING,
	POISON,
	GROUND,
	FLYING,
	PSYCHIC,
	BUG,
	ROCK,
	GHOST,
	DRAGON,
	DARK,
	STEEL,
	FAIRY
}

enum TecmonAilment #Status effects that can effect a tecmon
{
	NONE,
	BURN,
	FREEZE,
	PARALYSIS,
	POISON,
	TOXIC,
	SLEEP,
	CONFUSION,
	TRAP,
	LEECH_SEED,
	DISABLE,
	UNKNOWN
}

enum TecmonStat #the different stats for each tecmon
{
	NONE,
	HP,
	ATTACK,
	DEFENSE,
	SPECIAL_ATTACK,
	SPECIAL_DEFENSE,
	SPEED,
	ACCURACY,
	EVASION
}
