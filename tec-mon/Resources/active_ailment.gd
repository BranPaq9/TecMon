extends Resource
class_name ActiveAilment

## A single ailment currently affecting a TecmonInstance.

var type: Enums.TecmonAilment = Enums.TecmonAilment.NONE
var turns_remaining: int = -1  ## -1 = indefinite (burn, poison, paralysis, freeze)
var toxic_counter: int = 0 ## Escalates each turn for TOXIC only

static func create(ailment_type: Enums.TecmonAilment, ailment_turns: int) -> ActiveAilment:
	var a := ActiveAilment.new()
	a.type = ailment_type
	match ailment_type:
		Enums.TecmonAilment.SLEEP:
			a.turns_remaining = randi_range(1, 3)
		Enums.TecmonAilment.CONFUSION:
			a.turns_remaining = randi_range(2, 5)
		_:
			a.turns_remaining = ailment_turns
	return a
