extends StaticBody2D
class_name NPC


@export var party_data: Array[TecmonData]
@export_multiline() var dialog: Array[String] = []
var party_instance : Array[TecmonInstance]

func _ready() -> void:
	while not party_data.is_empty():
		party_instance.append(TecmonInstance.create(party_data[0], 4, party_data[0].tecmon_name))
		party_data.pop_front()

func interact() -> void:
	MessageBus.send(["Hello!", "Let's BATTLE!"], 20)
	await MessageBus.message_box_closed
	await SceneManager._transition_out()
	var p_party: Array[TecmonInstance] = Global.player.tecmon_party
	BattleSystem.start_battle(party_instance, p_party)
	# AudioManager.play_sfx("")
