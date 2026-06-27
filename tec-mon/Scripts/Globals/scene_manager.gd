extends CanvasLayer

signal level_changed(level_data: LevelData) ##Signal for when the current level is changed 

var current_level: LevelData = null
var _is_changing: bool = false
var color_rect: ColorRect
var game_manager: Node
var current_level_container: Node2D


func _ready() -> void:
	# Creates a black box that fill the screen for the transitions
	# Makes it ignore mouse inputs
	layer = 100
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.color = Color.BLACK
	color_rect.modulate.a = 0.0
	add_child(color_rect)
	# go_to(Global.main_menu.level_name)
	
func is_changing() -> bool:
	return _is_changing

func go_to(level_name: String) -> void:
	if _is_changing:
		return
	
	var level_data := LevelRegistry.get_level(level_name)
	if level_data == null:
		push_error("Level not found: " + level_name)
		return
	
	_is_changing = true
	await _transition_out()
	
	if current_level_container.get_child_count() > 0:
		current_level_container.get_child(0).queue_free()
	
	current_level = level_data
	var level_path: String = current_level.scene_path
	var level_scene: PackedScene = load(level_path)
	var level_node: Level = level_scene.instantiate()
	current_level_container.add_child(level_node)
	
	await get_tree().process_frame  # wait for scene to load
	
	level_changed.emit(level_data)
	
	await _transition_in()
	_is_changing = false

#tweens the opacity of the black box
func _transition_out() -> void:
	color_rect.visible = true
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.5)
	await tween.finished

func _transition_in() -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	await tween.finished
	color_rect.visible = false
