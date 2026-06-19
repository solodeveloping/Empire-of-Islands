@tool
class_name Housing_ECS
extends Entity

# TODO : don't need this
# Goes against ECS
# Should be done per building

func define_components() -> Array:
	return [
		C_Transform.new(),
		C_Health.new(100),
		C_HousingCapacity.new(4, 0)
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform
