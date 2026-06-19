class_name C_PopUnit
extends Component

@export var pop_type: int = 0
@export var is_working: bool = false

func _init(pop_type_: int = 0, is_working_: bool = false):
	pop_type = pop_type_
	is_working = is_working_
