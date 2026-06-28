@tool
extends Entity
class_name DockBuoy_ECS

func define_components() -> Array:
	return [
		C_DockBuoy.new(0),
		C_Transform.new(),
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform
