@tool
extends Entity
class_name IslandGECS1

@export
var tree_containers: Array[Goshape] = []

var tree_grid_multimesh_container: Array[GridMultiMesh] = []

func define_components() -> Array:
	return [
		C_Transform.new(),
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform

func add_to_ecs_world():
	for container in tree_containers:
		var grids = container.find_children("*", "GridMultiMesh")
		for grid: GridMultiMesh in grids:
			tree_grid_multimesh_container.push_back(grid)
			for coord in grid.coord_to_multimesh.keys():
				var multimesh: MultiMeshInstance3D = grid.coord_to_multimesh.get(coord)
				for i in multimesh.multimesh.visible_instance_count:
					var trans = multimesh.multimesh.get_instance_transform(i)
					var entity = E_TreeMultiMesh_ECS.new()
					# TODO : this is not updated when we hide/show trees based on physics
					var c_transform = C_Transform.new()
					c_transform.transform = trans
					entity.add_component(c_transform)
					entity.grid_multimesh_index = tree_grid_multimesh_container.size()
					entity.grid_multimesh_inner_coord = coord
					entity.multimesh_instance_index = i
					
					entity.add_relationship(
						Rels.create_belongs_to(self)
					)
					
					ECS.world.add_entity(entity)
