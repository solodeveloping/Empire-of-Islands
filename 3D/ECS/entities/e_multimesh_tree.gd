@tool
class_name E_TreeMultiMesh_ECS
extends Entity

func define_components() -> Array:
	return [
		C_Tree.new(100), 
	]

var grid_multimesh_index: int = 0
var grid_multimesh_inner_coord: Vector3i = Vector3i.ZERO
var multimesh_instance_index: int = 0
