class_name C_WorkerRequirement
extends Component

@export 
var requirements: Dictionary[int, Worker_Requirement] = {}

func _init(
	requirements_: Array[Worker_Requirement] = [],
):
	# Info: transforming to Dictionary
	for requirement in requirements_:
		requirements.set(
			requirement.worker_type,
			requirement
		)
