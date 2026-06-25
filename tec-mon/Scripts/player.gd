extends CharacterBody2D

@export var walk_speed : float = 64.0
@export var animation_tree: AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
const TILE_SIZE : float = 16

var is_moving : bool = false
var target_position : Vector2
var move_direction : Vector2 = Vector2.ZERO
var last_direction : Vector2 = Vector2.DOWN

func _ready():
	target_position = global_position.snapped(Vector2.ONE * TILE_SIZE)
	global_position = target_position
	
func _physics_process(delta: float) -> void:
	
	if is_moving:
		move_to_target(delta)
	else:
		read_input()
	update_animation()
		
func read_input() -> void:
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	
	if input_direction.x != 0:
		input_direction.y = 0
		
	if input_direction != Vector2.ZERO:
		move_direction = input_direction.normalized()
		last_direction = move_direction
		target_position = global_position + move_direction * TILE_SIZE
		is_moving = true
		
func move_to_target(delta : float) -> void:
	var direction_to_target := target_position - global_position
	var distance_this_frame := walk_speed * delta
	
	if direction_to_target.length() <= distance_this_frame:
		global_position = target_position
		velocity = Vector2.ZERO
		is_moving = false
	else:
		velocity = direction_to_target.normalized() * walk_speed
		move_and_slide()
		
func update_animation() -> void:
	animation_tree.set("parameters/Idle/blend_position", last_direction)
	animation_tree.set("parameters/Walking/blend_position", last_direction)
	
	if is_moving:
		if state_machine.get_current_node() != "Walking":
			state_machine.travel("Walking")
	else:
		if state_machine.get_current_node() != "Idle":
			state_machine.travel("Idle")
		
	
	
		
