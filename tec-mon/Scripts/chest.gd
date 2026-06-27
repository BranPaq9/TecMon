extends StaticBody2D

func interact() -> void:
	MessageBus.send(["You Have Opened a Common Chest", "You Have found a potion of healing"], 20)
	AudioManager.play_sfx(preload("res://Assets/Sounds/SFX/open_chest.wav"))
