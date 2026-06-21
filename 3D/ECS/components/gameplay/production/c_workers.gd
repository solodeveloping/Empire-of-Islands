class_name C_Workers
extends Component

# TODO: rename to worker by pop type

@export
var workers: Dictionary[int, WorkerQuantity] = {}

# Info: this is designed to add workers only for the worker you need
func _init(
	workers_: Dictionary[int, WorkerQuantity] = {},
):
	workers = workers_
