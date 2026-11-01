@tool
extends Entity
class_name MapExit2D_ECS

func define_components() -> Array:
	return [
		C_MapShipExitPoint.new(),
		C_Transform2D.new(),
	]

func on_ready():
	var c_trans = get_component(C_Transform2D) as C_Transform2D
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform
