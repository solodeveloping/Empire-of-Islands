extends Component
class_name C_IsInSpatialBin

@export
var bin_coord: Vector3i

func _init(bin_coord_: Vector3i = Vector3i.ZERO) -> void:
	bin_coord = bin_coord_
