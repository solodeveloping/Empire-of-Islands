extends Component
class_name C_ShipPopulation

@export
var current: int = 0

@export
var maximum: int = 0

func _init(current_: int = 0, maximum_: int = 0) -> void:
	current = current_
	maximum = maximum_
