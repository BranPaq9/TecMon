extends Node2D
class_name Level

@export var level_data: LevelData

func _ready() -> void:
	if level_data == null:
		return

	if level_data.bgm != null:
		AudioManager.play_music(level_data.bgm, -12)
		
