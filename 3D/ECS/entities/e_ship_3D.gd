@tool
extends Entity
class_name Ship3D_ECS

func define_components() -> Array:
	return [
		C_Ship.new(),
		C_Name.new("Ship"),
		C_Health.new(100.0),
		C_Movement.new(10.0),
		C_Transform.new(),
		C_NavigationAgent3D.new("NavigationAgent3D"),
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform
