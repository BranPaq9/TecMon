extends StaticBody2D

@export var party_data: Array[TecmonData]
var party_instance : Array[TecmonInstance]

func _ready() -> void:
	while not party_data.is_empty():
		party_instance.append(TecmonInstance.create(party_data[0], 4))
		party_data.pop_front()

func interact() -> void:
	MessageBus.send(["Hello!", "Let's BATTLE!"], 20)
	await MessageBus.message_box_closed
	await SceneManager._transition_out()
	var p_party: Array[TecmonInstance] = [
		TecmonInstance.create(
			get_tree().get_first_node_in_group("Player").starter_tecmon, 4, false
		)
	]
	p_party.get(0).nickname = "Saint"
	BattleSystem.start_battle(party_instance, p_party)
	# AudioManager.play_sfx("")
