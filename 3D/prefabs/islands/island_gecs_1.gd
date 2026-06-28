@tool
extends Entity
class_name IslandGECS1

@export
var tree_containers: Array[Goshape] = []

var tree_grid_multimesh_container: Array[GridMultiMesh] = []

@export_tool_button("display_primitive_count")
var display_primitive_count = _display_primitive_count

@export_tool_button("count_physics_bodies")
var count_physics_bodies = _count_physics_bodies

@export_tool_button("hide_all_collider_containers")
var hide_all_collider_containers = _hide_all_collider_containers

@export_tool_button("show_all_collider_containers")
var show_all_collider_containers = _show_all_collider_containers

@export_tool_button("hide_all_area_containers")
var hide_all_area_containers = _hide_all_area_containers

@export_tool_button("show_all_area_containers")
var show_all_area_containers = _show_all_area_containers

@export_tool_button("hide_all_colliders")
var hide_all_colliders = _hide_all_colliders

@export_tool_button("show_all_colliders")
var show_all_colliders = _show_all_colliders

@export_tool_button("hide_all_collision_shapes")
var hide_all_collision_shapes = _hide_all_collision_shapes

@export_tool_button("show_all_collision_shapes")
var show_all_collision_shapes = _show_all_collision_shapes

func define_components() -> Array:
	return [
		C_Transform.new(),
		C_PopulationSummary.new(),
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

func _ready() -> void:
	Loggie.msg("IslandGECS1:_ready").info()

func _display_primitive_count():
	_display_primitive_count_rec(self, 0)

func _display_primitive_count_rec(node: Node, indent: int):
	var indent_string = ""
	for i in indent:
		indent_string += "  "
	if "mesh" in node:
		var mesh: Mesh = node.mesh
		var array_mesh = ArrayMesh.new()
		if mesh is PrimitiveMesh:
			array_mesh.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES,
				mesh.get_mesh_arrays()
			)
		else:
			array_mesh = mesh
		
		var vertex_total: int = 0
		var face_total: int = 0
		var surface_count: int = array_mesh.get_surface_count()
		
		for i in surface_count:
			var mdt := MeshDataTool.new()
			mdt.create_from_surface(array_mesh, i)
			vertex_total += mdt.get_vertex_count()
			face_total += mdt.get_face_count()
		
		Loggie.msg("%s %s Vertices %s Triangles %s" % [
			indent_string,
			node.name,
			vertex_total,
			face_total,
		]).info()
	for child in node.get_children(true):
		_display_primitive_count_rec(child, indent + 1)

class ComputePhysicsBodiesResult:
	var collision_object_count: int = 0
	var collision_shape_count: int = 0

func _count_physics_bodies():
	var result: ComputePhysicsBodiesResult = ComputePhysicsBodiesResult.new()
	_count_physics_bodies_rec(self, result)
	Loggie.msg("Collision objects (bodies): %s, shapes: %s" % [
		result.collision_object_count,
		result.collision_shape_count,
	]).info()

func _count_physics_bodies_rec(node: Node, result: ComputePhysicsBodiesResult):
	if node is CollisionObject3D:
		result.collision_object_count += 1
	if node is CollisionShape3D:
		result.collision_shape_count += 1
	for child in node.get_children(true):
		_count_physics_bodies_rec(child, result)

func _hide_all_collider_containers():
	var all_multimeshes = SceneUtils.find_all_child_of_type_depth_first(
		self,
		MultiMeshWithCollidersAndAreas
	)
	for mm: MultiMeshWithCollidersAndAreas in all_multimeshes:
		mm.colliders_container.hide()

func _show_all_collider_containers():
	var all_multimeshes = SceneUtils.find_all_child_of_type_depth_first(
		self,
		MultiMeshWithCollidersAndAreas
	)
	for mm: MultiMeshWithCollidersAndAreas in all_multimeshes:
		mm.colliders_container.show()

func _hide_all_area_containers():
	var all_objs = SceneUtils.find_all_child_of_type_depth_first(
		self,
		MultiMeshWithCollidersAndAreas
	)
	for obj: MultiMeshWithCollidersAndAreas in all_objs:
		obj.areas_container.hide()

func _show_all_area_containers():
	var all_objs = SceneUtils.find_all_child_of_type_depth_first(
		self,
		MultiMeshWithCollidersAndAreas
	)
	for obj: MultiMeshWithCollidersAndAreas in all_objs:
		obj.areas_container.show()

# FIXME: could be optimized
func _hide_all_colliders():
	var all_objs = SceneUtils.find_all_child_of_type_depth_first(
		self,
		CollisionObject3D,
		true
	)
	for obj: CollisionObject3D in all_objs:
		obj.hide()

func _show_all_colliders():
	var all_objs = SceneUtils.find_all_child_of_type_depth_first(
		self,
		CollisionObject3D,
		true
	)
	for obj: CollisionObject3D in all_objs:
		obj.show()

func _hide_all_collision_shapes():
	var all_objs = SceneUtils.find_all_child_of_type_depth_first(
		self,
		CollisionShape3D,
		true
	)
	for obj: CollisionShape3D in all_objs:
		obj.hide()

func _show_all_collision_shapes():
	var all_objs = SceneUtils.find_all_child_of_type_depth_first(
		self,
		CollisionShape3D,
		true
	)
	for obj: CollisionShape3D in all_objs:
		obj.show()
