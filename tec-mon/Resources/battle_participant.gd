extends RefCounted
class_name BattleParticipant

## Wraps a TecmonInstance for the duration of a battle.
## Holds volatile battle state that resets when the battle ends:
## stat stages, effective stats (after stages), confusion turns, etc.
## The underlying TecmonInstance is the source of truth for HP and ailments.

# ── References ────────────────────────────────────────────────────────────────
var instance: TecmonInstance
var is_player_side: bool = false

# ── Stat stages ───────────────────────────────────────────────────────────────
## Each stage is clamped to [-6, +6]. Reset when the tecmon is swapped out or
## the battle ends.
var stat_stages: Dictionary = {
	Enums.TecmonStat.ATTACK:          0,
	Enums.TecmonStat.DEFENSE:         0,
	Enums.TecmonStat.SPECIAL_ATTACK:  0,
	Enums.TecmonStat.SPECIAL_DEFENSE: 0,
	Enums.TecmonStat.SPEED:           0,
	Enums.TecmonStat.ACCURACY:        0,
	Enums.TecmonStat.EVASION:         0,
}

## Volatile battle flags
var confusion_turns: int = 0
var is_confused: bool = false
var is_protected: bool = false  ## Protect / Detect (lasts one turn)
var trapped: bool = false

# ── Factory ───────────────────────────────────────────────────────────────────

static func create(inst: TecmonInstance, player_side: bool) -> BattleParticipant:
	var p := BattleParticipant.new()
	p.instance = inst
	p.is_player_side = player_side
	return p

# ── Effective stats ───────────────────────────────────────────────────────────

## Returns a stat value with stage multipliers applied.
## Use this instead of reading instance stats directly during battle.
func effective_stat(stat: Enums.TecmonStat) -> float:
	var base: float
	match stat:
		Enums.TecmonStat.ATTACK:          base = instance.attack
		Enums.TecmonStat.DEFENSE:         base = instance.defense
		Enums.TecmonStat.SPECIAL_ATTACK:  base = instance.special_attack
		Enums.TecmonStat.SPECIAL_DEFENSE: base = instance.special_defense
		Enums.TecmonStat.SPEED:           base = instance.speed
		_:                                base = 1.0
	return base * _stage_multiplier(stat)

func _stage_multiplier(stat: Enums.TecmonStat) -> float:
	var stage: int = stat_stages.get(stat, 0)
	## Standard multiplier table: stages -6..+6 map to 2/8 .. 8/2.
	if stat in [Enums.TecmonStat.ACCURACY, Enums.TecmonStat.EVASION]:
		## Accuracy/evasion use a different table: 3/(3-stage) vs (3+stage)/3
		if stage >= 0:
			return (3.0 + stage) / 3.0
		else:
			return 3.0 / (3.0 - stage)
	else:
		if stage >= 0:
			return (2.0 + stage) / 2.0
		else:
			return 2.0 / (2.0 - stage)

# ── Stat stage changes ────────────────────────────────────────────────────────

## Apply a stage change. Returns the actual change applied (clamped).
## Positive delta = buff, negative = debuff.
func modify_stage(stat: Enums.TecmonStat, delta: int) -> int:
	var current: int = stat_stages.get(stat, 0)
	var new_stage: int = clamp(current + delta, -6, 6)
	stat_stages[stat] = new_stage
	return new_stage - current  ## Actual change (0 if already at limit).

func reset_stages() -> void:
	for stat in stat_stages:
		stat_stages[stat] = 0

# ── Convenience pass-throughs ─────────────────────────────────────────────────

func is_fainted() -> bool:
	return instance.is_fainted()

func display_name() -> String:
	return instance.display_name()

func hp_percent() -> float:
	return instance.hp_percent()

# ── Damage application ────────────────────────────────────────────────────────

## Apply pre-calculated damage to the underlying instance.
func take_damage(amount: float) -> void:
	instance.take_damage(amount)

## Apply an end-of-turn ailment tick. Returns the damage dealt (if any).
func apply_ailment_tick() -> float:
	var dmg: float = 0.0
	match instance.ailment:
		Enums.TecmonAilment.BURN:
			dmg = instance.max_hp / 16.0
			instance.take_damage(dmg)
		Enums.TecmonAilment.POISON:
			dmg = instance.max_hp / 8.0
			instance.take_damage(dmg)
		Enums.TecmonAilment.TOXIC:
			instance.ailment_counter += 1
			dmg = instance.max_hp * (instance.ailment_counter / 16.0)
			instance.take_damage(dmg)
		Enums.TecmonAilment.SLEEP:
			instance.ailment_counter -= 1
			if instance.ailment_counter <= 0:
				instance.clear_ailment()
	return dmg

# ── Confusion ─────────────────────────────────────────────────────────────────

func apply_confusion(turns: int = 3) -> void:
	is_confused = true
	confusion_turns = turns

## Called at the start of each turn. Returns true if the tecmon hurts itself.
func confusion_tick() -> bool:
	if not is_confused:
		return false
	confusion_turns -= 1
	if confusion_turns <= 0:
		is_confused = false
		return false
	## 1/3 chance to hurt itself.
	return randf() < 0.333

## Resets all volatile battle state. Call when a participant is swapped out.
func reset_battle_state() -> void:
	reset_stages()
	is_confused = false
	confusion_turns = 0
	is_protected = false
	trapped = false
