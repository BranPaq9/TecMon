extends StaticBody2D
class_name Heart

@export var infinite : bool

@export var heart_sprite : Sprite2D
@export var heart_used_sprite : Sprite2D

var interacted: bool = false

func interact(player: Player):
	if interacted:
		return
	heal_player(player)
	AudioManager.play_sfx("heal")
	if not infinite:
		interacted = true
		
func heal_player(player):
	MessageBus.send(["Your party has been healed!"])
	for tecmon in player.tecmon_party:
		tecmon.current_hp = tecmon.max_hp
	if not infinite:
		heart_sprite.hide()
		heart_used_sprite.show()
		interacted = true
	
