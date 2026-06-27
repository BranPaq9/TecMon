extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

#checks for the player entering and exiting the area and plays the according animation aswell as a particle effect
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		calculate_encounter_chance()
	animated_sprite_2d.play("Down")
	gpu_particles_2d.restart()
	
func _on_body_exited(body: Node2D) -> void:
	animated_sprite_2d.play("Up")

func calculate_encounter_chance():
	EncounterManager.try_encounter("grass")
