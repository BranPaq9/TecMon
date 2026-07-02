extends CanvasLayer

const RESOLUTIONS := [
	Vector2i(320, 160),
	Vector2i(320*2, 160*2),
	Vector2i(320*3, 160*3),
	Vector2i(320*4, 160*4),
	Vector2i(320*5, 160*5),
	Vector2i(320*6, 160*6)
]

enum ScreenMode {
	WINDOWED,
	BORDERLESS,
	FULLSCREEN
}

@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider

var parent_scene : int
var current_res : Vector2i = RESOLUTIONS[0]


func _ready() -> void:
	hide()
	master_slider.value = get_bus_volume("Master")
	music_slider.value = get_bus_volume("Music")
	sfx_slider.value = get_bus_volume("SFX")
	
	
func set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	value = max(value, 0.0001)
	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func get_bus_volume(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return 1.0

	return clamp(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)

func _on_back_button_pressed() -> void:
	hide()
	if parent_scene == 1:
		SceneManager.game_manager.get_child(4).show()
	else:
		get_tree().paused = false

func _on_visibility_changed() -> void:
	if visible and get_tree().paused:
		parent_scene = 1
	elif visible:
		get_tree().paused = true
		parent_scene = 2


func _on_resolution_dropdown_item_selected(index: int) -> void:
	DisplayServer.window_set_size(RESOLUTIONS[index])
	current_res = RESOLUTIONS[index]
	


func _on_screen_mode_dropdown_item_selected(index: int) -> void:
	match index:
		ScreenMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(current_res)

		ScreenMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(current_res)

		ScreenMode.FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_shaders_toggle_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_vsync_toggle_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED
	)


func _on_master_vol_slider_value_changed(value: float) -> void:
	set_bus_volume("Master", value)


func _on_music_vol_slider_value_changed(value: float) -> void:
	set_bus_volume("Music", value)


func _on_sfx_vol_slider_value_changed(value: float) -> void:
	set_bus_volume("SFX", value)


func _on_vo_toggle_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
