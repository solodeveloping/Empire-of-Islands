extends Component
class_name C_HasWaterEndurance

@export
var time: float = 0

@export
var starting_time: float = 0

func _init(
	starting_time_: float = 0,
) -> void:
	starting_time = starting_time_
	time = starting_time_
