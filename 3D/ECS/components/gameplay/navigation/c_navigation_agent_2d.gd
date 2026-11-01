extends Component
class_name C_NavigationAgent2D

# FIXME: should we split 2D and 3D
# And have a "common" folder?

@export
var navigation_agent_2d_path: String

func _init(navigation_agent_2d_path_: String = "") -> void:
	navigation_agent_2d_path = navigation_agent_2d_path_
