extends Component
class_name C_CanDeAggro

@export
var can_deaggro_by_distance_travelled: bool = true

@export
var max_distance_travelled: float = 0

@export
var can_deaggro_by_distance_to_starting_point: bool = false

@export
var max_distance_to_starting_point: float = 0

@export
var can_deaggro_by_time: bool = false

@export
var max_aggro_time: float = 0

func _init(
	can_deaggro_by_distance_travelled_: bool = false,
	max_distance_travelled_: float = 0,
	can_deaggro_by_distance_to_starting_point_: bool = false,
	max_distance_to_starting_point_: float = 0,
	can_deaggro_by_time_: bool = false,
	max_aggro_time_: float = 0,
) -> void:
	can_deaggro_by_distance_travelled = can_deaggro_by_distance_travelled_
	max_distance_travelled = max_distance_travelled_
	
	can_deaggro_by_distance_to_starting_point = can_deaggro_by_distance_to_starting_point_
	max_distance_to_starting_point = max_distance_to_starting_point_
	
	can_deaggro_by_time = can_deaggro_by_time_
	max_aggro_time = max_aggro_time_
