extends Node
## Owns the active battle's state machine and drives turn resolution.
## BattleStage listens to signals from this node.

signal battle_started
signal battle_ended(outcome: BattleOutcome)
signal turn_started
signal turn_ended
signal move_executed(user: BattleParticipant, target: BattleParticipant, move: MoveInstance, result: MoveResult)
signal stat_changed(participant: BattleParticipant, stat: Enums.TecmonStat, delta: int)
signal ailment_applied(participant: BattleParticipant, ailment: Enums.TecmonAilment)
signal participant_fainted(participant: BattleParticipant)
signal message_queued(text: String)  ## UI listens to this to feed MessageBus.

enum BattleOutcome { PLAYER_WIN, PLAYER_FLED, PLAYER_LOST }

enum TurnPhase { IDLE, AWAITING_INPUT, RESOLVING, ENDED }

# Active battle stat
var player_participant: BattleParticipant   ## The active player-side tecmon.
var enemy_participant: BattleParticipant    ## The active enemy tecmon.
var player_party: Array[TecmonInstance] = []
var phase: TurnPhase = TurnPhase.IDLE

# Queued actions for the current turn (set by UI before execute_turn is called).
var _queued_player_move: MoveInstance = null
var _player_is_fleeing: bool = false

#Starting a battle
func start_battle(enemy_instance: TecmonInstance, party: Array[TecmonInstance]) -> void:
	player_party = party
	player_participant = BattleParticipant.create(party[0], true)
	enemy_participant  = BattleParticipant.create(enemy_instance, false)
	phase = TurnPhase.AWAITING_INPUT
	battle_started.emit()

# Player action input (called by BattleStage UI)

func queue_move(move: MoveInstance) -> void:
	if phase != TurnPhase.AWAITING_INPUT:
		return
	_queued_player_move = move
	_player_is_fleeing = false
	execute_turn()

func queue_flee() -> void:
	if phase != TurnPhase.AWAITING_INPUT:
		return
	_player_is_fleeing = true
	execute_turn()

# Turn resolution

func execute_turn() -> void:
	if phase != TurnPhase.AWAITING_INPUT:
		return
	phase = TurnPhase.RESOLVING
	turn_started.emit()

	## Flee attempt.
	if _player_is_fleeing:
		if _can_flee():
			_end_battle(BattleOutcome.PLAYER_FLED)
			return
		else:
			message_queued.emit("You couldn't escape!")

	## Enemy picks a move (simple random AI for now).
	var enemy_move: MoveInstance = _pick_enemy_move()

	## Determine turn order by speed.
	var player_goes_first: bool = (
		player_participant.effective_stat(Enums.TecmonStat.SPEED) >=
		enemy_participant.effective_stat(Enums.TecmonStat.SPEED)
	)

	if player_goes_first:
		_resolve_move(player_participant, enemy_participant, _queued_player_move)
		if not enemy_participant.is_fainted():
			_resolve_move(enemy_participant, player_participant, enemy_move)
	else:
		_resolve_move(enemy_participant, player_participant, enemy_move)
		if not player_participant.is_fainted():
			_resolve_move(player_participant, enemy_participant, _queued_player_move)

	## End-of-turn ailment ticks.
	if not player_participant.is_fainted():
		_apply_ailment_tick(player_participant)
	if not enemy_participant.is_fainted():
		_apply_ailment_tick(enemy_participant)

	## Check for faint outcomes.
	if enemy_participant.is_fainted():
		message_queued.emit(enemy_participant.display_name() + " fainted!")
		participant_fainted.emit(enemy_participant)
		_end_battle(BattleOutcome.PLAYER_WIN)
		return

	if player_participant.is_fainted():
		message_queued.emit(player_participant.display_name() + " fainted!")
		participant_fainted.emit(player_participant)
		## TODO: check for remaining party members; for now just end the battle.
		_end_battle(BattleOutcome.PLAYER_LOST)
		return

	_queued_player_move = null
	_player_is_fleeing = false
	phase = TurnPhase.AWAITING_INPUT
	turn_ended.emit()

# Move resolution

func _resolve_move(user: BattleParticipant, target: BattleParticipant, move_inst: MoveInstance) -> void:
	if move_inst == null or not move_inst.has_pp():
		message_queued.emit(user.display_name() + " has no moves left!")
		return

	## Confusion self-hit check.
	if user.confusion_tick():
		message_queued.emit(user.display_name() + " is confused and hurt itself!")
		var self_dmg: float = _calc_confusion_damage(user)
		user.take_damage(self_dmg)
		return

	## Accuracy check.
	if not _accuracy_roll(user, target, move_inst.move):
		message_queued.emit(user.display_name() + "'s " + move_inst.move.move_name + " missed!")
		move_inst.use()
		return

	move_inst.use()
	message_queued.emit(user.display_name() + " used " + move_inst.move.move_name + "!")

	var result := MoveResult.new()

	match move_inst.move.move_category:
		MoveResource.MoveCategory.PHYSICAL, MoveResource.MoveCategory.SPECIAL:
			result = _calc_damage(user, target, move_inst.move)
			target.take_damage(result.damage)
			if result.is_critical:
				message_queued.emit("A critical hit!")
			if result.effectiveness != 1.0:
				if result.effectiveness > 1.0:
					message_queued.emit("It's super effective!")
				else:
					message_queued.emit("It's not very effective...")
		MoveResource.MoveCategory.STATUS:
			_apply_status_effect(user, target, move_inst.move)

	move_executed.emit(user, target, move_inst, result)

# Damage formula

func _calc_damage(user: BattleParticipant, target: BattleParticipant, move: MoveResource) -> MoveResult:
	var result := MoveResult.new()

	## Pick the right attack/defense pair.
	var atk: float
	var def: float
	if move.move_category == MoveResource.MoveCategory.PHYSICAL:
		atk = user.effective_stat(Enums.TecmonStat.ATTACK)
		def = target.effective_stat(Enums.TecmonStat.DEFENSE)
		## Burn halves physical attack.
		if user.instance.ailment == Enums.TecmonAilment.BURN:
			atk *= 0.5
	else:
		atk = user.effective_stat(Enums.TecmonStat.SPECIAL_ATTACK)
		def = target.effective_stat(Enums.TecmonStat.SPECIAL_DEFENSE)

	## Critical hit (6.25% base chance).
	result.is_critical = randf() < 0.0625
	var crit_mod: float = 1.5 if result.is_critical else 1.0

	## Type effectiveness.
	result.effectiveness = _calc_effectiveness(move.move_type, target.instance.data)

	## Core formula (simplified Gen-V style).
	var level_factor: float = (2.0 * user.instance.level / 5.0) + 2.0
	var raw: float = (level_factor * move.base_power * (atk / def)) / 50.0 + 2.0
	var randomness: float = randf_range(0.85, 1.0)
	result.damage = raw * crit_mod * result.effectiveness * randomness

	return result

func _calc_effectiveness(move_type: Enums.TecmonType, target_data: TecmonData) -> float:
	## Look up both of the defender's types.
	var mult: float = 1.0
	mult *= TypeChart.get_multiplier(move_type, target_data.type_one)
	if target_data.type_two != Enums.TecmonType.NONE:
		mult *= TypeChart.get_multiplier(move_type, target_data.type_two)
	return mult

func _calc_confusion_damage(user: BattleParticipant) -> float:
	## Fixed-power 40, physical, targets self, ignores stages.
	var atk: float  = user.instance.attack
	var def: float  = user.instance.defense
	var level_factor: float = (2.0 * user.instance.level / 5.0) + 2.0
	return (level_factor * 40.0 * (atk / def)) / 50.0 + 2.0

# Accuracy

func _accuracy_roll(user: BattleParticipant, target: BattleParticipant, move: MoveResource) -> bool:
	if move.accuracy <= 0:
		return true  ## Always-hit moves (Swift, etc.)
	var acc: float  = move.accuracy / 100.0
	acc *= user.effective_stat(Enums.TecmonStat.ACCURACY)
	acc /= target.effective_stat(Enums.TecmonStat.EVASION)
	return randf() < acc

# Status effects

func _apply_status_effect(user: BattleParticipant, target: BattleParticipant, move: MoveResource) -> void:
	## Moves declare their effects as arrays of MoveEffect resources.
	## This stub just handles ailment application for now.
	if move.ailment == Enums.TecmonAilment.NONE:
		return
	var applied := target.instance.apply_ailment(move.ailment)
	if applied:
		ailment_applied.emit(target, move.ailment)
		message_queued.emit(target.display_name() + " was " + _ailment_name(move.ailment) + "!")
	else:
		message_queued.emit("It didn't affect " + target.display_name() + "!")

func _apply_ailment_tick(participant: BattleParticipant) -> void:
	var dmg := participant.apply_ailment_tick()
	if dmg > 0.0:
		match participant.instance.ailment:
			Enums.TecmonAilment.BURN:
				message_queued.emit(participant.display_name() + " is hurt by its burn!")
			Enums.TecmonAilment.POISON, Enums.TecmonAilment.TOXIC:
				message_queued.emit(participant.display_name() + " is hurt by poison!")

func _ailment_name(ailment: Enums.TecmonAilment) -> String:
	match ailment:
		Enums.TecmonAilment.BURN: return "burned"
		Enums.TecmonAilment.FREEZE: return "frozen"
		Enums.TecmonAilment.PARALYSIS: return "paralysed"
		Enums.TecmonAilment.POISON: return "poisoned"
		Enums.TecmonAilment.TOXIC: return "badly poisoned"
		Enums.TecmonAilment.SLEEP: return "put to sleep"
		Enums.TecmonAilment.CONFUSION: return "confused"
		_: return "afflicted"

# Flee

func _can_flee() -> bool:
	## Classic flee formula: high player speed relative to enemy = high chance.
	var p_spd := player_participant.effective_stat(Enums.TecmonStat.SPEED)
	var e_spd := enemy_participant.effective_stat(Enums.TecmonStat.SPEED)
	if p_spd >= e_spd:
		return true
	var chance: float = (p_spd * 128.0 / e_spd) / 255.0
	return randf() < chance

# Enemy AI (placeholder

func _pick_enemy_move() -> MoveInstance:
	## Simple random selection among moves with PP remaining.
	var available: Array[MoveInstance] = []
	for m in enemy_participant.instance.moves:
		if m.has_pp():
			available.append(m)
	if available.is_empty():
		return null
	return available[randi() % available.size()]

# Ending the battle

func _end_battle(outcome: BattleOutcome) -> void:
	phase = TurnPhase.ENDED

	## Reset volatile battle state on both sides.
	if player_participant:
		player_participant.reset_battle_state()
	if enemy_participant:
		enemy_participant.reset_battle_state()
	
	await MessageBus.message_box_closed
	battle_ended.emit(outcome)
