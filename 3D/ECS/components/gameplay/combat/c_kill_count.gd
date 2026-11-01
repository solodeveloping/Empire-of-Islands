extends Component
class_name C_KillCount

@export
var ships: int = 0

@export
var units: int = 0

@export
var animals: int = 0

func _init(
	ships_: int = 0,
	units_: int = 0,
	animals_: int = 0,
) -> void:
	ships = ships_
	units = units_
	animals = animals_
