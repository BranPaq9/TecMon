extends CanvasLayer

## Listens for encounters, shows the battle UI, and bridges player input to BattleSystem.
## Owns no battle logic — all resolution happens in BattleSystem.

@onready var enemy_sprite:  TextureRect = $Control/EnemyTecmon
@onready var player_sprite: TextureRect = $Control/PlayerTecmon

@onready var enemy_name_label: Label = %EnemyName
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var player_name_label: Label = %PlayerName
@onready var player_hp_bar: ProgressBar = %PlayerHPBar

@onready var move_container: VBoxContainer = %MoveContainer
@onready var move_one: Button = %MoveOne
@onready var move_two: Button = %MoveTwo
@onready var move_three: Button = %MoveThree
@onready var move_four: Button = %MoveFour

func _ready() -> void:
	EncounterManager.encounter_started.connect(_on_encounter_started)
	BattleSystem.battle_ended.connect(_on_battle_ended)
	BattleSystem.turn_ended.connect(_refresh_ui)
	BattleSystem.message_queued.connect(_on_message_queued)
	BattleSystem.move_executed.connect(_on_move_executed)
	move_container.hide()
	move_one.pressed.connect(_on_move_button_pressed.bind(move_one))
	move_two.pressed.connect(_on_move_button_pressed.bind(move_two))
	move_three.pressed.connect(_on_move_button_pressed.bind(move_three))
	move_four.pressed.connect(_on_move_button_pressed.bind(move_four))
	hide()

func _on_encounter_started(enemy_instance: TecmonInstance) -> void:
	MessageBus.send(["You encountered a " + enemy_instance.display_name() + "!"])
	await MessageBus.message_box_closed
	Global.set_movement_blocked(true)
	await SceneManager._transition_out()
	show()
	SceneManager._transition_in()

	## Hand off to BattleSystem with the enemy and the player's party.
	## TODO: pass the real player party here once the player party is tracked.
	var placeholder_party: Array[TecmonInstance] = [TecmonInstance.create(get_tree().get_first_node_in_group("Player").starter_tecmon, 4, false)]
	BattleSystem.start_battle(enemy_instance, placeholder_party)

	_refresh_ui()

func _refresh_ui() -> void:
	var enemy  := BattleSystem.enemy_participant
	var player := BattleSystem.player_participant
	MessageBus.send(["What will " + player.instance.display_name() + " do?"])
	if enemy:
		enemy_sprite.texture = enemy.instance.get_front_sprite()
		enemy_name_label.text = enemy.display_name() + " Lv." + str(enemy.instance.level)
		enemy_hp_bar.value = enemy.hp_percent() * 100.0

	if player:
		player_sprite.texture = player.instance.get_back_sprite()
		player_name_label.text = player.display_name() + " Lv." + str(player.instance.level)
		player_hp_bar.value = player.hp_percent() * 100.0
		
func _on_message_queued(text: String) -> void:
	MessageBus.send([text])
	## If you want to await each message before the next turn step, connect to
	## MessageBus.message_box_closed inside BattleSystem instead of here.

func _on_move_executed(_user: BattleParticipant, _target: BattleParticipant,
		_move: MoveInstance, result: MoveResult) -> void:
	## TODO: trigger animations, screen shake, HP drain tweens.
	move_container.hide()
	_refresh_ui()

func _on_move_button_pressed(button: Button):
	var player : BattleParticipant = BattleSystem.player_participant
	var tecmon_instance: TecmonInstance = player.instance
	var move: MoveInstance
	match button:
		move_one:
			move = tecmon_instance.moves.get(0)
		move_two:
			move = tecmon_instance.moves.get(1)
		move_three:
			move = tecmon_instance.moves.get(2)
		move_four:
			move = tecmon_instance.moves.get(3)
	
	BattleSystem.queue_move(move)
	
func _on_fight_pressed() -> void:
	move_container.show()
	var tecmon_instance: TecmonInstance = BattleSystem.player_participant.instance
	if move_container.visible == true:
		for index in tecmon_instance.moves.size():
			var move_instance: MoveInstance = tecmon_instance.moves.get(index)
			var move_resource: MoveResource = move_instance.move
			var move_text: String = (move_resource.move_name + " " + str(move_instance.current_pp) + "/" + str(move_resource.max_pp))
			match index:
				0:
					move_one.text = move_text
					move_one.show()
				1:
					move_two.text = move_text
					move_two.show()
				2:
					move_three.text = move_text
					move_three.show()
				3:
					move_four.text = move_text
					move_four.show()

func _on_items_pressed() -> void:
	## TODO: Open inventory.
	pass

func _on_tecmons_pressed() -> void:
	## TODO: Open party screen for switching.
	pass

func _on_escape_pressed() -> void:
	BattleSystem.queue_flee()

func _on_battle_ended(outcome: BattleSystem.BattleOutcome) -> void:
	await MessageBus.message_box_closed
	await SceneManager._transition_out()
	hide()
	await SceneManager._transition_in()
	Global.set_movement_blocked(false)
