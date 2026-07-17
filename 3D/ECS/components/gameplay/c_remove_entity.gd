extends Component
class_name C_RemoveEntity

@export
var remove_immediatly: bool = false

@export
var time_limit: float = 0

@export
var time: float = 0

func _init(
	remove_immediatly_: bool = false,
	time_limit_: float = 0,
) -> void:
	remove_immediatly = remove_immediatly_
	time_limit = time_limit_
