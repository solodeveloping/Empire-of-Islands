extends Component
class_name C_NotGettingPaid

@export
var time: float = 0

@export
var stop_working_time_limit: float = 0

@export
var stopped_working: bool = false

func _init(stop_working_time_limit_: float = 0) -> void:
	stop_working_time_limit = stop_working_time_limit_
