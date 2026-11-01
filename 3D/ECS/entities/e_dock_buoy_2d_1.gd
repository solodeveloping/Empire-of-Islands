@tool
extends Entity
class_name DockBuoy2D_ECS

# TODO : old school graphic is too low poly

func define_components() -> Array:
	return [
		C_DockBuoy.new(0),
		C_Transform2D.new(),
		C_CircularVision.new(250),
	]

func on_ready():
	ECSBuilding2DUtils.setup_trans_and_vision(
		self
	)
