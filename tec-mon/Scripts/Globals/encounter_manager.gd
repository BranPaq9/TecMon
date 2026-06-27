extends Node

signal encounter_started(encounter: Tecmon) ## Signal for when an encounter with a tecmon begins

func try_encounter(zone: String = "grass") -> void:
	print("tried rolling")
	var level := SceneManager.current_level #checks for the current level

	if level == null or not level.has_encounters:
		print("no level")
		return
	
	if randf() > level.encounter_rate: #rolls for the chance to get an encounter
		return
	
	var table: EncounterTable = _get_table(level, zone) # gets the encounter table based on the level and terrain
	if table == null:
		return
	
	var encounter := table.roll()
	if encounter:
		encounter_started.emit(encounter)
	
func _get_table(level: LevelData, zone: String) -> EncounterTable:
	match zone:
		"grass": return level.grass_encounters
		"water": return level.water_encounters
		"cave":  return level.cave_encounters
	return null
