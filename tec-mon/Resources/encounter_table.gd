extends Resource
class_name EncounterTable

@export var encounters: Array[Tecmon] = []

func roll() -> Tecmon:
	if encounters.is_empty():
		return null
	
	var total_weight := 0
	for e in encounters: #gets the total weight for all the tecmon in the table
		total_weight += e.weight
	
	var roll := randi() % total_weight
	var cumulative := 0
	
	for e in encounters: #rolls to see what tecmon will be chosen
		cumulative += e.weight
		if roll < cumulative:
			var shiny_roll : float = randf()
			if shiny_roll < Global.shiny_odds: #checks to see if the tecmon will be shiny
				e.is_shiny = true
			return e

	return encounters.back()
