extends Node

var _levels: Dictionary = {}
var dir_path: String = "res://Levels/"

func _ready() -> void:
	_register_all()

func _register_all() -> void: #Gets all the level reosurces in a specific dir
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.get_extension() == "tres":
			var res: LevelData = load(dir_path + file)
			if res is LevelData:
				_levels[res.level_name] = res
		file = dir.get_next()
	
func get_level(level_name: String) -> LevelData:
	return _levels.get(level_name, null)

func get_all() -> Dictionary:
	return _levels
