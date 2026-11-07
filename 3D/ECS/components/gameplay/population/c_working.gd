extends Component
class_name C_Working

# TODO: when should it be considered to be working?
# maybe it should relate to present_workers

@export
var working_time: float = 0

@export
var pay_time_limit: float = 0

@export
var pay: int = 0

@export
var is_active: bool = false

func _init(
	# FIXME: can we remove this?
	# should be 0
	working_time_: float = 0,
	# is the actual worktime
	pay_time_limit_: float = 0,
	pay_: int = 0,
	is_active_: bool = false
) -> void:
	print("C_Working:_init")
	working_time = working_time_
	pay_time_limit = pay_time_limit_
	pay = pay_
	is_active = is_active_
