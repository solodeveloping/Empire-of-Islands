@tool
extends Entity
class_name TentHousing2D_ECS

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.Tent),
		C_Transform2D.new(),
		C_Health.new(100),
		C_HousingCapacity.new(4, 0),
		# TODO: should it be done elsewhere?
		C_NotFullyOccupied.new(),
		C_Name.new("Tent"),
		C_CircularVision.new(250),
	]

func on_ready():
	ECSBuilding2DUtils.setup_trans_and_vision(
		self
	)

var visual_node: Node
func set_visual_node(node: Node):
	visual_node = node

func get_visual_node() -> Node:
	return visual_node
