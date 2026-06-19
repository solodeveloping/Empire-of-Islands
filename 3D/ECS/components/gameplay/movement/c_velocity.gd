class_name C_Velocity
extends Component

@export var velocity: Vector3 = Vector3.ZERO

func _init(velocity_: Vector3 = Vector3.ZERO) -> void:
	velocity = velocity_
