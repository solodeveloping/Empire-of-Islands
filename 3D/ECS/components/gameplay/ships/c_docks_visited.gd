extends Component
class_name C_DocksVisited

@export var visited_dock_buoy_ids: Array[int] = []
@export var max_docks_to_visit: int = 0

func _init(max_docks_to_visit_: int = 0):
	max_docks_to_visit = max_docks_to_visit_
