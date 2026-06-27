extends CanvasLayer

var enemy_tecmon: Tecmon
var player_tecmon: Tecmon

@onready var enemy_tecmon_sprite: TextureRect = $Control/EnemyTecmon
@onready var player_tecmon_sprite: TextureRect = $Control/PlayerTecmon

func _ready() -> void:
	EncounterManager.encounter_started.connect(_on_encounter_started) #Connects the encounter signal to function
	hide()
	
func _on_encounter_started(tecmon: Tecmon) -> void:
	MessageBus.send(["You encountered a " + tecmon.tecmon_name]) # Sends message to the message box with the tecmon name
	await MessageBus.message_box_closed #waits for the Message box to send a closed signal to run the rest of the code
	Global.set_movement_blocked(true)
	enemy_tecmon = tecmon #Sets the enemy tecmon
	
	if enemy_tecmon:
		print("Is Shiny = " + str(enemy_tecmon.is_shiny))
		if enemy_tecmon.is_shiny:
			enemy_tecmon_sprite.texture = enemy_tecmon.front_shiny_sprite
		else:
			enemy_tecmon_sprite.texture = enemy_tecmon.front_sprite
	
	await SceneManager._transition_out()
	show()
	SceneManager._transition_in()
	
func _on_fight_pressed() -> void:
	pass # Replace with function body.

func _on_items_pressed() -> void:
	pass # Replace with function body.

func _on_tecmons_pressed() -> void:
	pass # Replace with function body.

func _on_escape_pressed() -> void:
	await SceneManager._transition_out()
	hide()
	await SceneManager._transition_in()
	Global.set_movement_blocked(false)
