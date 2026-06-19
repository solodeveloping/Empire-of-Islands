class_name C_ResourceRequirement
extends Component

# TODO: maybe a C_Consumption

@export var requirements: Array[Resource_Requirement] = []

func _init(
	requirements_: Array[Resource_Requirement],
):
	requirements = requirements_
