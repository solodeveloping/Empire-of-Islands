extends Component
class_name C_CargoStorage

# TODO: make this an option
# could be a resource
@export
var gold_count: int = 0

@export
var storage: Dictionary[int, CargoResourceStorageDef] = {}

@export
var max_weight: int = 0

@export
var max_space: int = 0

@export
var weight: int = 0

@export
var space: int = 0

func _init(
	gold_count_: int = 0,
	max_weight_: int = 0,
	max_space_: int = 0,
) -> void:
	gold_count = gold_count_
	max_weight = max_weight_
	max_space = max_space_
