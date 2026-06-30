extends StaticBody2D
class_name Chest

func interact():
	MessageBus.send(["You opened a chest"])
	AudioManager.play_sfx("open_chest")
