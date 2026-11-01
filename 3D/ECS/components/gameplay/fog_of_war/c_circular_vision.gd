extends Component
class_name C_CircularVision

@export var radius: float = 100.0
@export var offset: Vector2 = Vector2.ZERO

func _init(
	radius_: float = 100.0,
	offset_: Vector2 = Vector2.ZERO,
) -> void:
	radius = radius_
	offset = offset_
