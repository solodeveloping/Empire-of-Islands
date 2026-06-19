class_name C_Workers
extends Component

@export
var workers: Dictionary[int, WorkerQuantity] = {}

func _init(
	workers_: Dictionary[int, WorkerQuantity] = {},
):
	workers = workers_
