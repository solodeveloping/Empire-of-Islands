extends Component
class_name C_Island

# FIXME: should it just be C_Name?
@export var island_name: String = ""

func _init(island_name_: String = "") -> void:
	island_name = island_name_
