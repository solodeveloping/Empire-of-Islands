class_name C_BuildingStoredResources
extends Component

@export var stacks: Dictionary[int, Resource_Stack] = {}

func _init(
	stacks_: Dictionary[int, Resource_Stack],
):
	stacks = stacks_
