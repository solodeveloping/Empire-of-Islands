class_name C_Tree
extends Component

@export var current_wood_quantity: float = 100.0
@export var maximum_wood_quantity: float = 100.0

func _init(maximum_wood_quantity_: float = 100.0):
	maximum_wood_quantity = maximum_wood_quantity_
	current_wood_quantity = maximum_wood_quantity_
