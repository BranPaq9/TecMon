extends Node
## Provides type matchup multipliers.
## Returns 1.0 for any pair not explicitly listed (neutral).

var _chart: Dictionary = {}  ## { [atk_type][def_type] = float }

func _ready() -> void:
	_build_chart()

func get_multiplier(atk: Enums.TecmonType, def: Enums.TecmonType) -> float:
	if atk in _chart and def in _chart[atk]:
		return _chart[atk][def]
	return 1.0

func _build_chart() -> void:
	## Shorthand aliases for the enum values.
	var T := Enums.TecmonType

	## Format: _set(attacking_type, defending_type, multiplier)
	## Only non-1.0 matchups need to be listed.

	## Fire
	_set_mult(T.FIRE,     T.GRASS,  2.0)
	_set_mult(T.FIRE,     T.ICE,    2.0)
	_set_mult(T.FIRE,     T.STEEL,  2.0)
	_set_mult(T.FIRE,     T.WATER,  0.5)
	_set_mult(T.FIRE,     T.ROCK,   0.5)
	_set_mult(T.FIRE,     T.FIRE,   0.5)
	_set_mult(T.FIRE,     T.DRAGON, 0.5)

	## Water
	_set_mult(T.WATER,    T.FIRE,   2.0)
	_set_mult(T.WATER,    T.ROCK,   2.0)
	_set_mult(T.WATER,    T.GROUND, 2.0)
	_set_mult(T.WATER,    T.WATER,  0.5)
	_set_mult(T.WATER,    T.GRASS,  0.5)
	_set_mult(T.WATER,    T.DRAGON, 0.5)

	## Grass
	_set_mult(T.GRASS,    T.WATER,  2.0)
	_set_mult(T.GRASS,    T.ROCK,   2.0)
	_set_mult(T.GRASS,    T.GROUND, 2.0)
	_set_mult(T.GRASS,    T.FIRE,   0.5)
	_set_mult(T.GRASS,    T.GRASS,  0.5)
	_set_mult(T.GRASS,    T.POISON, 0.5)
	_set_mult(T.GRASS,    T.FLYING, 0.5)
	_set_mult(T.GRASS,    T.BUG,    0.5)
	_set_mult(T.GRASS,    T.STEEL,  0.5)
	_set_mult(T.GRASS,    T.DRAGON, 0.5)

	## Electric
	_set_mult(T.ELECTRIC, T.WATER,  2.0)
	_set_mult(T.ELECTRIC, T.FLYING, 2.0)
	_set_mult(T.ELECTRIC, T.GRASS,  0.5)
	_set_mult(T.ELECTRIC, T.ELECTRIC, 0.5)
	_set_mult(T.ELECTRIC, T.DRAGON, 0.5)
	_set_mult(T.ELECTRIC, T.GROUND, 0.0)  ## Immune

	## Ground
	_set_mult(T.GROUND,   T.FIRE,   2.0)
	_set_mult(T.GROUND,   T.ELECTRIC, 2.0)
	_set_mult(T.GROUND,   T.POISON, 2.0)
	_set_mult(T.GROUND,   T.ROCK,   2.0)
	_set_mult(T.GROUND,   T.STEEL,  2.0)
	_set_mult(T.GROUND,   T.GRASS,  0.5)
	_set_mult(T.GROUND,   T.BUG,    0.5)
	_set_mult(T.GROUND,   T.FLYING, 0.0)  ## Immune

	## Normal
	_set_mult(T.NORMAL,   T.ROCK,   0.5)
	_set_mult(T.NORMAL,   T.STEEL,  0.5)
	_set_mult(T.NORMAL,   T.GHOST,  0.0)  ## Immune

	## Ghost
	_set_mult(T.GHOST,    T.NORMAL, 0.0)  ## Immune
	_set_mult(T.GHOST,    T.PSYCHIC, 2.0)
	_set_mult(T.GHOST,    T.GHOST,  2.0)
	_set_mult(T.GHOST,    T.DARK,   0.5)

	## Add remaining types (Fighting, Poison, Flying, Psychic, Bug, Rock,
	## Dragon, Dark, Steel, Ice, Fairy) following the same pattern.
func _set_mult(atk: Enums.TecmonType, def: Enums.TecmonType, mult: float) -> void:
	if atk not in _chart:
		_chart[atk] = {}
	_chart[atk][def] = mult
