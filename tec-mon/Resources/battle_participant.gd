extends RefCounted
class_name BattleParticipant

var instance: TecmonInstance
var is_player_side: bool = false

var stat_stages: Dictionary = {
	Enums.TecmonStat.ATTACK: 0,
	Enums.TecmonStat.DEFENSE: 0,
	Enums.TecmonStat.SPECIAL_ATTACK: 0,
	Enums.TecmonStat.SPECIAL_DEFENSE: 0,
	Enums.TecmonStat.SPEED: 0,
	Enums.TecmonStat.ACCURACY: 0,
	Enums.TecmonStat.EVASION: 0,
}

var is_protected: bool = false
var trapped: bool = false

static func create(inst: TecmonInstance, player_side: bool) -> BattleParticipant:
	var p := BattleParticipant.new()
	p.instance = inst
	p.is_player_side = player_side
	return p

func effective_stat(stat: Enums.TecmonStat) -> float:
	var base: float
	match stat:
		Enums.TecmonStat.ATTACK: base = instance.attack
		Enums.TecmonStat.DEFENSE: base = instance.defense
		Enums.TecmonStat.SPECIAL_ATTACK: base = instance.special_attack
		Enums.TecmonStat.SPECIAL_DEFENSE: base = instance.special_defense
		Enums.TecmonStat.SPEED: base = instance.speed
		_: base = 1.0
	return base * _stage_multiplier(stat)

func _stage_multiplier(stat: Enums.TecmonStat) -> float:
	var stage: int = stat_stages.get(stat, 0)
	if stat in [Enums.TecmonStat.ACCURACY, Enums.TecmonStat.EVASION]:
		return (3.0 + stage) / 3.0 if stage >= 0 else 3.0 / (3.0 - stage)
	else:
		return (2.0 + stage) / 2.0 if stage >= 0 else 2.0 / (2.0 - stage)

func modify_stage(stat: Enums.TecmonStat, delta: int) -> int:
	var current: int = stat_stages.get(stat, 0)
	var new_stage: int = clamp(current + delta, -6, 6)
	stat_stages[stat] = new_stage
	return new_stage - current

func reset_stages() -> void:
	for stat in stat_stages:
		stat_stages[stat] = 0

func is_fainted() -> bool: return instance.is_fainted()
func display_name() -> String: return instance.display_name()
func hp_percent() -> float: return instance.hp_percent()
func current_hp() -> int: return roundi(instance.current_hp)
func max_hp() -> int: return roundi(instance.max_hp)

func take_damage(amount: float) -> void:
	instance.take_damage(amount)

## Runs all end-of-turn ailment ticks. Returns an Array of [ailment_type, damage]
## pairs so BattleSystem can generate the right messages.
func tick_ailments() -> Array:
	var events: Array = []
	var to_clear: Array[Enums.TecmonAilment] = []

	for a: ActiveAilment in instance.ailments:
		match a.type:
			Enums.TecmonAilment.BURN:
				var dmg := instance.max_hp / 16.0
				instance.take_damage(dmg)
				events.append([a.type, dmg])

			Enums.TecmonAilment.POISON:
				var dmg := instance.max_hp / 8.0
				instance.take_damage(dmg)
				events.append([a.type, dmg])

			Enums.TecmonAilment.TOXIC:
				a.toxic_counter += 1
				var dmg := instance.max_hp * (a.toxic_counter / 16.0)
				instance.take_damage(dmg)
				events.append([a.type, dmg])

			Enums.TecmonAilment.SLEEP:
				a.turns_remaining -= 1
				events.append([a.type, 0.0])
				if a.turns_remaining <= 0:
					to_clear.append(a.type)

			Enums.TecmonAilment.FREEZE:
				## 20% chance to thaw each turn.
				if randf() < 0.2:
					to_clear.append(a.type)
					events.append([Enums.TecmonAilment.FREEZE, -1.0])  ## -1 signals thaw.
				else:
					events.append([a.type, 0.0])

			Enums.TecmonAilment.CONFUSION:
				a.turns_remaining -= 1
				if a.turns_remaining <= 0:
					to_clear.append(a.type)
					events.append([Enums.TecmonAilment.CONFUSION, -1.0])  ## -1 signals snapped out.
				## Confusion self-hit is handled at move resolution, not here.

	for t in to_clear:
		instance.clear_ailment(t)

	return events

## Called at the start of the user's move. Returns whether the move is blocked.
func pre_move_ailment_check() -> Enums.TecmonAilment:
	if instance.has_ailment(Enums.TecmonAilment.SLEEP):
		return Enums.TecmonAilment.SLEEP
	if instance.has_ailment(Enums.TecmonAilment.FREEZE):
		return Enums.TecmonAilment.FREEZE
	if instance.has_ailment(Enums.TecmonAilment.PARALYSIS):
		if randf() < 0.25:
			return Enums.TecmonAilment.PARALYSIS
	if instance.has_ailment(Enums.TecmonAilment.CONFUSION):
		var conf := instance.get_ailment(Enums.TecmonAilment.CONFUSION)
		if conf and randf() < 0.333:
			return Enums.TecmonAilment.CONFUSION
	return Enums.TecmonAilment.NONE

func reset_battle_state() -> void:
	reset_stages()
	is_protected = false
	trapped = false
	instance.clear_ailment(Enums.TecmonAilment.CONFUSION)
