@tool
class_name Storage_ECS
extends Entity

func define_components() -> Array:
	return [
		C_IsStorage.new(),
		C_Health.new(100),
		C_Range.new(100.0)
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform
