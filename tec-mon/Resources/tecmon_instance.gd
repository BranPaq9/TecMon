extends Resource
class_name TecmonInstance

signal levelled_up(new_level: int)
signal fainted

@export_category("Identity")
@export var data: TecmonData
@export var nickname: String = ""
@export var is_shiny: bool = false

@export_category("Progression")
@export var level: int = 1
@export var experience: float = 0.0

@export_category("Moves")
@export var moves: Array[MoveInstance] = []

var max_hp: float = 0.0
var current_hp: float = 0.0
var attack: float = 0.0
var defense: float = 0.0
var special_attack: float = 0.0
var special_defense: float = 0.0
var speed: float = 0.0

## All currently active ailments. Multiple can coexist (e.g. burn + confusion).
## Use the helpers below — don't read this directly outside TecmonInstance.
var ailments: Array[ActiveAilment] = []

static func create(species: TecmonData, at_level: int, shiny: bool = false) -> TecmonInstance:
	var inst := TecmonInstance.new()
	inst.data = species
	inst.level = at_level
	inst.is_shiny = shiny
	inst.compute_stats()
	inst.current_hp = inst.max_hp
	var available: Array[MoveResource] = species.moves_available_at(at_level)
	var start_index: int = max(0, available.size() - 4)
	for move in available.slice(start_index):
		inst.moves.append(MoveInstance.new(move))
	return inst

func compute_stats() -> void:
	if data == null:
		push_error("TecmonInstance: data is null")
		return
	max_hp = _hp_formula(data.base_hp)
	attack = _stat_formula(data.base_attack)
	defense = _stat_formula(data.base_defense)
	special_attack = _stat_formula(data.base_special_attack)
	special_defense = _stat_formula(data.base_special_defense)
	speed = _stat_formula(data.base_speed)

func _hp_formula(base: float) -> float:
	return floorf((2.0 * base * level) / 100.0) + level + 10.0

func _stat_formula(base: float) -> float:
	return floorf((2.0 * base * level) / 100.0) + 5.0

func display_name() -> String:
	if nickname != "": return nickname
	if data: return data.tecmon_name
	return "???"

func get_front_sprite() -> Texture2D:
	if is_shiny and data.front_shiny_sprite: return data.front_shiny_sprite
	if data: return data.front_sprite
	return null

func get_back_sprite() -> Texture2D:
	if is_shiny and data.back_shiny_sprite: return data.back_shiny_sprite
	if data: return data.back_sprite
	return null

func is_fainted() -> bool:
	return current_hp <= 0.0

func hp_percent() -> float:
	if max_hp <= 0.0: return 0.0
	return current_hp / max_hp

func heal(amount: float) -> void:
	current_hp = min(max_hp, current_hp + amount)

func take_damage(amount: float) -> void:
	current_hp = max(0.0, current_hp - amount)
	if is_fainted():
		fainted.emit()

func award_experience(amount: float) -> bool:
	experience += amount
	var levelled := false
	while level < 100 and experience >= _xp_for_next_level():
		experience -= _xp_for_next_level()
		level += 1
		compute_stats()
		current_hp = min(current_hp + (max_hp - current_hp), max_hp)
		levelled_up.emit(level)
		levelled = true
	return levelled

func _xp_for_next_level() -> float:
	return pow(level, 3) if data else 1000.0

func has_ailment(type: Enums.TecmonAilment) -> bool:
	return get_ailment(type) != null

func get_ailment(type: Enums.TecmonAilment) -> ActiveAilment:
	for a in ailments:
		if a.type == type:
			return a
	return null

## Returns false if this ailment type is already present.
func apply_ailment(type: Enums.TecmonAilment, turns: int) -> bool:
	if has_ailment(type):
		return false
	ailments.append(ActiveAilment.create(type, turns))
	return true

func clear_ailment(type: Enums.TecmonAilment) -> void:
	ailments = ailments.filter(func(a): return a.type != type)

func clear_all_ailments() -> void:
	ailments.clear()

func can_use_any_move() -> bool:
	for m in moves:
		if m.has_pp(): return true
	return false

func learn_move(new_move: MoveResource, slot: int = -1) -> bool:
	if slot == -1:
		if moves.size() < 4:
			moves.append(MoveInstance.new(new_move))
			return true
		return false
	if slot < 0 or slot >= moves.size():
		return false
	moves[slot] = MoveInstance.new(new_move)
	return true
