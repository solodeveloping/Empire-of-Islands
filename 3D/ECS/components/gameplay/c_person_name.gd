extends Component
class_name C_PersonName

# TODO: other types of names
# Like middle names

@export
var first_name: String = ""

@export
var last_name: String = ""

func _init(
	first_name_: String = "",
	last_name_: String = "",
) -> void:
	first_name = first_name_
	last_name = last_name_
