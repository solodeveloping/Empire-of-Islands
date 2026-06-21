class_name C_HousingCapacity
extends Component

@export var current: int = 4
@export var maximum: int = 4
@export var pop_type: int = 0

func _init(maximum_: int = 4, pop_type_: int = 0):
	maximum = maximum_
	current = 0
	pop_type = pop_type_
