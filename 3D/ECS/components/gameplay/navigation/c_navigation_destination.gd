class_name C_NavigationDestination
extends Component

@export var target: Vector3 = Vector3.ZERO

func _init(target_: Vector3 = Vector3.ZERO) -> void:
	target = target_
