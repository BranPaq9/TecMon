extends Resource
class_name MoveResource

enum MoveCategory { PHYSICAL, SPECIAL, STATUS }

@export_category("Basic Info")
@export var move_name: String = ""
@export var move_type: Enums.TecmonType
@export var move_category: MoveCategory = MoveCategory.PHYSICAL
@export_multiline var description: String = ""

@export_category("Battle Stats")
@export var base_power: int = 0      ## 0 for STATUS moves.
@export var accuracy: int = 100      ## 0 = always hits (Swift, etc.)
@export var max_pp: int = 10
@export var priority: int = 0        ## Higher goes first regardless of speed. Quick Attack = +1.

@export_category("Effects")
@export var ailment: Enums.TecmonAilment = Enums.TecmonAilment.NONE
@export_range(0, 100) var ailment_chance: int = 0  ## % chance to apply ailment on hit. 100 = guaranteed.
@export var ailment_turns: int = 0
@export var stat_changes: Array[StatChange] = []  ## Empty for most moves.

@export_category("Sprites")
@export var sprite_sheet: Texture2D
@export var h_frames: int
@export var v_frames: int
