extends Component
class_name C_ComputeDeAggro

@export
var original_position: Vector3 = Vector3.ZERO

@export
var distance_travelled: float = 0

@export
var time_travelled: float = 0

@export
var last_position: Vector3

func _init(
	original_position_: Vector3 = Vector3.ZERO
) -> void:
	original_position = original_position_
	last_position = original_position_
