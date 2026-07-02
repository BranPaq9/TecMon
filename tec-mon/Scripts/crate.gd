extends CharacterBody2D

@export var push_force = 132

func _ready() -> void:
	pass

#check if player is in the Area2D
func _player_detected(body):
	#print("Detected")
	if body.name == "Player":
		if Input.is_action_pressed("down"):
			velocity.y += push_force
		if Input.is_action_pressed("up"):
			velocity.y -= push_force
		if Input.is_action_pressed("left"):
			velocity.x -= push_force
		if Input.is_action_pressed("right"):
			velocity.x+= push_force
	move_and_slide()

func _physics_process(delta: float) -> void:
	pass
