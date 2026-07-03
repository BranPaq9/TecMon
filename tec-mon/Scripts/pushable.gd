extends CharacterBody2D
class_name PushableBlock

const TILE_SIZE: float = 16.0
var is_being_pushed: bool = false
var target_position: Vector2

func try_push(direction: Vector2, tile_collision_layers: Array[int]) -> bool:
	if is_being_pushed:
		return false
	var desired: Vector2 = global_position + (direction * TILE_SIZE)
	if _is_occupied(desired, tile_collision_layers):
		return false
	target_position = desired
	is_being_pushed = true
	return true

func _physics_process(delta: float) -> void:
	if not is_being_pushed:
		return
	var dir_to_target := target_position - global_position
	var move_speed := 64.0
	var dist := move_speed * delta
	if dir_to_target.length() <= dist:
		global_position = target_position
		is_being_pushed = false
	else:
		velocity = dir_to_target.normalized() * move_speed
		move_and_slide()

func _is_occupied(pos: Vector2, layers: Array[int]) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos + Vector2(8.0, 8.0)
	var mask := 0
	for n in layers:
		mask |= (1 << (n - 1))
	query.collision_mask = mask
	query.collide_with_bodies = true
	var results := space_state.intersect_point(query)
	return not results.is_empty()
	
	
