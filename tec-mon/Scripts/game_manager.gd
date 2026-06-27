extends Node

@onready var battle_stage: CanvasLayer = $BattleStage
@onready var current_level: Node2D = $CurrentLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	SceneManager.game_manager = self #registers itself with the scenemanager
	SceneManager.current_level_container = current_level
