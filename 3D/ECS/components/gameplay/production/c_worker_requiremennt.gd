class_name C_WorkerRequirement
extends Component

# TODO: maybe a C_Consumption

@export 
var requirements: Array[Worker_Requirement] = []

func _init(
	requirements_: Array[Worker_Requirement] = [],
):
	requirements = requirements_
