class_name C_Health
extends Component

@export var current: float = 100.0
@export var maximum: float = 100.0

func _init(max_health_: float = 100.0):
	maximum = max_health_
	current = max_health_
