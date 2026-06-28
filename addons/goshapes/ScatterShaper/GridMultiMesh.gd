@tool
extends Node3D
class_name GridMultiMesh

@export
var grid_size := Vector3i(16, 16, 16)

@export
var max_instance_count_per_multimesh: int = 500

@export
var mesh: Mesh

@export
var coord_to_multimesh: Dictionary[Vector3i, MultiMeshInstance3D] = {}

@export
var debug_aabbs: bool = false

@export
var multimesh_aabb_debug_colors: Dictionary[Vector3i, Color] = {}

var visual_container: Node3D

func _ready() -> void:
	Loggie.msg("GridMultiMesh:_ready").info()
	if !has_node("visual_container"):
		visual_container = Node3D.new()
		visual_container.name = "visual_container"
		SceneUtils.add_child(self, visual_container)
	else:
		visual_container = get_node("visual_container")
	

func _process(delta: float) -> void:
	if debug_aabbs:
		Loggie.msg("GridMultiMesh:_process:debug_aabbs").info()
		for key in coord_to_multimesh.keys():
			var mm: MultiMeshInstance3D = coord_to_multimesh.get(key)
			var color = multimesh_aabb_debug_colors.get(key)
			
			#var mm_aabb = mm.multimesh["custom_aabb"]
			var mm_aabb = mm.get_aabb()
			mm_aabb = mm.global_transform * mm_aabb
			DebugDraw3D.draw_aabb(
				mm_aabb,
				color
			)

func add_instance(
	transform_: Transform3D,
	collider: StaticBody3D = null,
	area: Area3D = null
):
	var coords: Vector3i = get_coord_from_transform(transform_)
	
	var multimesh: MultiMeshInstance3D = coord_to_multimesh.get(coords)
	if !multimesh:
		multimesh = MultiMeshInstance3D.new()
		multimesh.set_script(MultiMeshWithCollidersAndAreas)
		SceneUtils.add_child(self.visual_container, multimesh)
		if multimesh is MultiMeshWithCollidersAndAreas:
		
			#multimesh.position = Vector3(
				#coords * grid_size
			#)
			multimesh.name = "_MM__%s_%s_%s" % [
				coords.x,
				coords.y,
				coords.z,
			]
			multimesh.coords = coords
			multimesh.multimesh = MultiMesh.new()
			multimesh.multimesh.mesh = mesh
			multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.multimesh.instance_count = max_instance_count_per_multimesh
			multimesh.multimesh.visible_instance_count = 1
			#multimesh.multimesh.custom_aabb = AABB(
				#Vector3.ZERO,
				#Vector3(grid_size)
			#)
			multimesh.multimesh.set_instance_transform(
				0,
				transform_
			)
			
			coord_to_multimesh.set(coords, multimesh)
			
			multimesh_aabb_debug_colors.set(
				coords, 
				Color(
					randf_range(0, 1),
					randf_range(0, 1),
					randf_range(0, 1),
				)
			)
			
			multimesh.add_instance(
				0,
				transform_,
				collider,
				area,
			)
	else:
		# if we already have the multimesh for the grid coord
		if multimesh.multimesh.visible_instance_count == multimesh.multimesh.instance_count:
			push_warning("too many instances %s vs %s" % [
				multimesh.multimesh.visible_instance_count,
				multimesh.multimesh.instance_count
			])
			return
		if multimesh is MultiMeshWithCollidersAndAreas:
			var id = multimesh.multimesh.visible_instance_count
			multimesh.multimesh.visible_instance_count += 1
			multimesh.multimesh.set_instance_transform(
				id,
				transform_
			)
			
			multimesh.add_instance(
				id,
				transform_,
				collider,
				area,
			)

func assign_aabbs():
	for key in coord_to_multimesh.keys():
		var mm: MultiMeshInstance3D = coord_to_multimesh.get(key)
		var aabb = mm.get_aabb()
		mm.multimesh.custom_aabb = aabb

func get_coord_from_transform(transform_: Transform3D) -> Vector3i:
	var coord = Vector3i(
		floor(transform_.origin.x / grid_size.x),
		floor(transform_.origin.y / grid_size.y),
		floor(transform_.origin.z / grid_size.z),
	)
	return coord

func hide_instance(
	area: MultiMeshInstanceArea
):
	#print("GridMultiMesh:hide_instance %s" % [
		#area.name,
	#])
	var mm: MultiMeshWithCollidersAndAreas = coord_to_multimesh.get(area.multimesh_coord)
	
	mm.hide_instance(area)

func show_instance(
	area: MultiMeshInstanceArea
):
	#print("GridMultiMesh:show_instance %s %s" % [
		#area.name,
		#area.instance_id
	#])
	
	var mm: MultiMeshWithCollidersAndAreas = coord_to_multimesh.get(area.multimesh_coord)
	
	mm.show_instance(area)
