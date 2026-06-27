extends Resource
class_name Tecmon

@export_category("Basic Info")
@export var tecmon_name: String = ""
@export var id: int = 1
@export_multiline() var description: String
@export var type_one: Enums.TecmonType = Enums.TecmonType.NONE
@export var type_two: Enums.TecmonType = Enums.TecmonType.NONE

@export var evolution_level: int = 30
@export var evolution: Tecmon
@export var moves: Array[Move] = []
@export var is_shiny: bool = false

@export_category("Sprites")
@export var front_sprite: Texture2D #64x64
@export var front_shiny_sprite: Texture2D
@export var back_sprite: Texture2D
@export var shiny_back_sprite: Texture2D
@export var mini_sprite: Texture2D #32x32

@export_category("Spawn Info")
@export var min_level: int = 2
@export var max_level: int = 5
@export var weight: int = 10  # higher = more common
@export var starting_moves: Array[Move] = []

@export_category("Stats")
@export var base_experience: float = 65
@export var base_attack: float = 75
@export var base_health: float = 75
@export var base_defense: float = 75
@export var base_speed: float = 75
@export_range(1, 2, 0.05) var growth_rate: float = 1.2
