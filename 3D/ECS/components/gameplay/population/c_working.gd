extends Component
class_name C_Working

@export
var working_time: float = 0

@export
var pay_time_limit: float = 0

@export
var pay: int = 0

@export
var is_active: bool = false

func _init(
	working_time_: float = 0,
	pay_time_limit_: float = 0,
	pay_: int = 0,
) -> void:
	working_time = working_time_
	pay_time_limit = pay_time_limit_
	pay = pay_
