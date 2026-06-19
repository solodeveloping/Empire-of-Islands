@tool
class_name PopUnit_ECS
extends Entity

func define_components() -> Array:
	return [
		C_Health.new(100),
		C_PopUnit.new()
	]
