class_name C_Workers
extends Component

# TODO: rename to worker by pop type

@export
var workers: Dictionary[int, WorkerQuantity] = {}

@export
var present_workers: Dictionary[int, WorkerQuantity] = {}

# Info: this is designed to add workers only for the worker you need
func _init(
	workers_: Dictionary[int, WorkerQuantity] = {},
	present_workers_: Dictionary[int, WorkerQuantity] = {},
):
	workers = workers_
	if present_workers_.is_empty():
		present_workers_ = {}
		for key in workers.keys():
			var val: WorkerQuantity =  workers.get(key)
			present_workers.set(
				key,
				WorkerQuantity.new(
					val.worker_type,
					val.worker_count,
				)
			)
	else:
		present_workers = present_workers_
