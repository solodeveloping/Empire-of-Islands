@tool
extends Entity
class_name TentLumberjack2D

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.Warehouse),
		C_Name.new("Dock"),
		C_Health.new(100),
		C_IsStorage.new(),
		C_Range.new(100.0),
		C_Transform2D.new(),
		C_Dock.new(),
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
