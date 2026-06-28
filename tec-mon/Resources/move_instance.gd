extends Resource
class_name MoveInstance

## A live copy of a Move owned by a TecmonInstance.
## Tracks remaining usages independently per creature.

@export var move: MoveResource ## The move definition
var current_pp: int ## Remaining uses this battle / session.

func _init(m: MoveResource = null) -> void:
	if m == null:
		return
	move = m
	current_pp = m.max_pp

## Returns true if this move can still be used.
func has_pp() -> bool:
	return current_pp > 0

## Spend one PP. Call before executing the move.
func use() -> void:
	current_pp = max(0, current_pp - 1)

## Restore all PP
func restore(amount: int = -1) -> void:
	if amount < 0:
		current_pp = move.max_pp
	else:
		current_pp = min(move.max_pp, current_pp + amount)
