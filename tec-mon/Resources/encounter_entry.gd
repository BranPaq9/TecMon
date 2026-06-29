extends Resource
class_name EncounterEntry

## Level range here overrides the species-level defaults when set.

@export var data: TecmonData
## Leave these at 0 to fall back to the defaults
@export var level_min_override: int = 0
@export var level_max_override: int = 0
