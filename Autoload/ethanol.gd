extends Node

var level: float = 0.0
const MAX_ETHANOL: float = 100.0

func add(amount: float) -> void:
	level = clamp(level + amount, 0.0, MAX_ETHANOL)
		
func get_clarity() -> float:
	return level / MAX_ETHANOL
