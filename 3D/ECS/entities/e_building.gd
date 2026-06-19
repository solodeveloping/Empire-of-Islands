@tool
class_name Building_ECS
extends Entity

func define_components() -> Array:
	return [C_Health.new(100)]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform
