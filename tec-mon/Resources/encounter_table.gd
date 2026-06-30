extends Resource
class_name EncounterTable

## A weighted list of TecmonData entries for a given zone.
## roll() generates a fully initialised TecmonInstance, including level and shiny check.

@export var entries: Array[EncounterEntry] = []

## Returns a new TecmonInstance, or null if the table is empty.
func _roll() -> TecmonInstance:
	if entries.is_empty():
		return null

	var total_weight: int = 0
	for entry in entries:
		total_weight += entry.data.weight

	var roll: int = randi() % total_weight
	var cumulative: int = 0

	for entry in entries:
		cumulative += entry.data.weight
		if roll < cumulative:
			print(entry.data.tecmon_name)
			return _spawn(entry)
	
	return null  ## Should never reach here.

func _spawn(entry: EncounterEntry) -> TecmonInstance:
	var spawned_level: int = randi_range(entry.data.min_level, entry.data.max_level)
	var is_shiny: bool = randf() < Global.shiny_odds
	return TecmonInstance.create(entry.data, spawned_level, entry.data.tecmon_name, is_shiny)
