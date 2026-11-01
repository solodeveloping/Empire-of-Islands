class_name C_Movement
extends Component

@export var speed: float = 10.0
@export var rotation_speed: float = 4.0
@export var fast_rotation_speed: float = 8.0

func _init(
	speed_: float = 10.0,
	rotation_speed_: float = 4.0,
	fast_rotation_speed_: float = 8.0,
) -> void:
	speed = speed_
	rotation_speed = rotation_speed_
	fast_rotation_speed = fast_rotation_speed_
