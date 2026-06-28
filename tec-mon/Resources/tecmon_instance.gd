extends Resource
class_name TecmonInstance

## The actual tecmon. Owns all its states: level, HP, moves, ailment, XP
## Always references the TecmonData for specific facts
## Never pass TecmonData directly to battle, use TecmonInstance instead

signal levelled_up(new_level: int)
signal fainted

@export_category("Identity")
@export var data: TecmonData       ## blueprint
@export var nickname: String = ""  ## Player given name
@export var is_shiny: bool = false

@export_category("Progression")
@export var level: int = 1
@export var experience: float = 0.0

## Up to 4 moves. Each is a MoveInstance
@export_category("Moves")
@export var moves: Array[MoveInstance] = []

# Live stats
## Computed from level + base stats. Call compute_stats() whenever level changes.
## Do not serialize these — they are always re-derived.
var max_hp: float = 0.0
var current_hp: float = 0.0
var attack: float = 0.0
var defense: float = 0.0
var special_attack: float = 0.0
var special_defense: float = 0.0
var speed: float = 0.0

# Status
var ailment: Enums.TecmonAilment = Enums.TecmonAilment.NONE
var ailment_counter: int = 0  ## Generic counter for how many more turns its effected


## Create a fully initialised instance from a TecmonData
static func create(species: TecmonData, at_level: int, shiny: bool = false) -> TecmonInstance:
	var inst := TecmonInstance.new()
	inst.data = species
	inst.level = at_level
	inst.is_shiny = shiny
	inst.compute_stats()
	inst.current_hp = inst.max_hp

	# Build a starting moveset: up to the last 4 moves learnable at this level.
	var available: Array[MoveResource] = species.moves_available_at(at_level)
	var start_index: int = max(0, available.size() - 4)
	for move in available.slice(start_index):
		inst.moves.append(MoveInstance.new(move))

	return inst

## Recalculates all stats from level and base data. Call after every level-up.
func compute_stats() -> void:
	if data == null:
		push_error("Data is null")
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

#Display
func display_name() -> String:
	if nickname != "":
		return nickname
	elif data:
		return (data.tecmon_name)
	else:
		return "???"

func get_front_sprite() -> Texture2D:
	if is_shiny and data.front_shiny_sprite:
		return data.front_shiny_sprite
	if data:
		return data.front_sprite
	else:
		return null

func get_back_sprite() -> Texture2D:
	if is_shiny and data.back_shiny_sprite:
		return data.back_shiny_sprite
	if data:
		return data.back_sprite
	else:
		return null

#HP helpers
func is_fainted() -> bool:
	return current_hp <= 0.0

func hp_percent() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp

func heal(amount: float) -> void:
	current_hp = min(max_hp, current_hp + amount)

func take_damage(amount: float) -> void:
	current_hp = max(0.0, current_hp - amount)
	if is_fainted():
		fainted.emit()

#Experience & levelling

## Award XP and level up if the threshold is crossed. Returns true if levelled.
func award_experience(amount: float) -> bool:
	experience += amount
	var levelled := false
	while level < 100 and experience >= _xp_for_next_level():
		experience -= _xp_for_next_level()
		level += 1
		compute_stats()
		current_hp = min(current_hp + (max_hp - current_hp), max_hp)  ## Partial HP restore on level-up.
		levelled_up.emit(level)
		levelled = true
	return levelled

func _xp_for_next_level() -> float:
	## Medium-fast group: level^3
	if data:
		return pow(level, 3)
	else: 
		return 1000.0

#Ailment helpers
func has_ailment() -> bool:
	return ailment != Enums.TecmonAilment.NONE

func apply_ailment(new_ailment: Enums.TecmonAilment) -> bool:
	## Returns false if the ailment could not be applied (already has one).
	if has_ailment():
		return false
	ailment = new_ailment
	ailment_counter = 0
	return true

func clear_ailment() -> void:
	ailment = Enums.TecmonAilment.NONE
	ailment_counter = 0

#Move management
func can_use_any_move() -> bool:
	for m in moves:
		if m.has_pp():
			return true
	return false

## Replace a move slot (index 0-3). Pass -1 to append if there's room.
func learn_move(new_move: MoveResource, slot: int = -1) -> bool:
	if slot == -1:
		if moves.size() < 4:
			moves.append(MoveInstance.new(new_move))
			return true
		return false  ## Party is full; caller should prompt the player to choose a slot.
	if slot < 0 or slot >= moves.size():
		return false
	moves[slot] = MoveInstance.new(new_move)
	return true
