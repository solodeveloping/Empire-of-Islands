class_name C_Production
extends Component

# TODO: variations of production for different time systems
# We decrease currently
# Could just use a timer etc

@export var production_type: int = 0
@export var production_per_cycle: int = 0
@export var production_time: float = 0
@export var time: float = 0

func _init(
	production_type_: int = 0,
	production_per_cycle_: int = 0,
	production_time_: float = 0,
):
	production_type = production_type_
	production_per_cycle = production_per_cycle_
	production_time = production_time_
	time = production_time
