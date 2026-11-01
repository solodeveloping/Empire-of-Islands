extends Component
## Use this to reduce workload on entities that could move but are not
class_name C_IsMoving

@export
var c_is_moving: bool = true

func _init(c_is_moving_: bool = true) -> void:
	c_is_moving = c_is_moving_
