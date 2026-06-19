@tool
extends Node3D

@export_tool_button("generate") var draw_multimesh_button = draw_multimesh

@export var count: int = 1000
@export var do_many_multimeshes = true
#@export var multimeshes_count = 4
@export var x_mm_count = 2
@export var y_mm_count = 2
@export var colors: Array[Array] = []

@onready var multi_mesh_instance_3d: MultiMeshInstance3D = $MultiMeshInstance3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var palm_tree_1: MeshInstance3D = $PalmTree_1_1/PalmTree_1
@onready var many_multi_meshes: Node3D = $ManyMultiMeshes

func _process(_delta: float) -> void:
	var aabb: AABB = mesh_instance_3d.get_aabb()
	#var aabb: AABB = palm_tree_1.get_aabb()
	aabb.size += Vector3(0, 3, 0)
	aabb = mesh_instance_3d.global_transform * aabb
	#aabb = palm_tree_1.global_transform * aabb
	#DebugDraw3D.draw_box(
		#aabb.position,
		#Quaternion.IDENTITY,
		#aabb.size + Vector3(0, 1, 0),# + Vector3(200, 10, 200),
		#Color(0, 1, 0)
	#)
	# It has not Y
	DebugDraw3D.draw_aabb(
		aabb,
		Color(0, 1, 0)
	)
	
	#var mm_aabb = multi_mesh_instance_3d.multimesh.get_aabb()
	if do_many_multimeshes == false:
		var mm_aabb = multi_mesh_instance_3d.multimesh["custom_aabb"]
		mm_aabb = multi_mesh_instance_3d.global_transform * mm_aabb
		DebugDraw3D.draw_aabb(
			mm_aabb,
			Color.REBECCA_PURPLE
		)
	else:
		if !many_multi_meshes:
			return
		
		DebugDraw3D.scoped_config().set_thickness(0.5)
		
		var inst_count = x_mm_count * y_mm_count
		#print("childs ", many_multi_meshes.get_child_count())
		if many_multi_meshes.get_child_count() >= inst_count:
			#print("draw aabbs")
			var i = 0
			for y in y_mm_count:
				for x in x_mm_count:
					#var i = y + x
					#print(i)
					var mm: MultiMeshInstance3D = many_multi_meshes.get_child(i)
					var mm_aabb = mm.multimesh["custom_aabb"]
					mm_aabb = mm.global_transform * mm_aabb
					DebugDraw3D.draw_aabb(
						mm_aabb,
						colors[x][y]
					)
					
					i += 1
	

func draw_multimesh():
	if do_many_multimeshes == false:
		NodeUtils.remove_all_children(many_multi_meshes)
		colors = []
		
		var aabb: AABB = mesh_instance_3d.get_aabb()
		multi_mesh_instance_3d.multimesh.instance_count = count
		print("size", aabb.size)
		
		#DebugDraw3D.draw_box(
			#aabb.position,
			#Quaternion.IDENTITY,
			#aabb.size, 
			#Color(0, 1, 0)
		#)
		
		for i in count:
			var x = randf_range(0, aabb.size.x)
			var y = randf_range(0, aabb.size.z)
			var position = Transform3D()
			position = position.translated(
				#Vector3(x - 50, 54, y - 50)
				Vector3(x - 50, 0, y - 50)
			)
			multi_mesh_instance_3d.multimesh.set_instance_transform(
				i,
				position
				#Transform3D(
					#Basis(),
					#Vector3(x - 50, 54, y - 50)
				#)
			)
	else:
		NodeUtils.remove_all_children(many_multi_meshes)
		colors = []
		
		var aabb: AABB = mesh_instance_3d.get_aabb()
		
		var size_x = aabb.size.x / x_mm_count
		var size_y = aabb.size.z / y_mm_count
		
		var offset_x = aabb.size.x / 2 * -1
		var offset_y = aabb.size.z / 2 * -1
		
		print("offset_x ", offset_x)
		print("offset_y ", offset_y)
		
		multi_mesh_instance_3d.multimesh.instance_count = 0
		
		var per_instance_count = int(count / (x_mm_count * y_mm_count))
		
		for y in y_mm_count:
			colors.push_back([])
			for x in x_mm_count:
				var multimesh = MultiMeshInstance3D.new()
				many_multi_meshes.add_child(multimesh)
				
				multimesh.owner = EditorInterface.get_edited_scene_root()
				
				var mm = MultiMesh.new()
				multimesh.multimesh = mm
				
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.instance_count = per_instance_count
				mm.mesh = palm_tree_1.mesh
				
				multimesh.global_position = Vector3(
					x * size_x + offset_x, 0, y * size_y + offset_y
				)
				var mm_aabb = AABB(
					Vector3(0, 0, 0),
					#multimesh.global_position,
					#multimesh.position,
					Vector3(size_x, 3, size_y)
				)
				mm.custom_aabb = mm_aabb
				
				#many_multi_meshes.add_child(multimesh)
				
				var color = Color(
					randf_range(0, 1),
					randf_range(0, 1),
					randf_range(0, 1),
				)
				colors[y].push_back(color)
				
				for i in per_instance_count:
					var x2 = randf_range(0, mm_aabb.size.x)
					var y2 = randf_range(0, mm_aabb.size.z)
					var position = Transform3D()
					position = position.translated(
						#Vector3(x - 50, 54, y - 50)
						Vector3(x2, 0, y2)
					)
					multimesh.multimesh.set_instance_transform(
						i,
						position
						#Transform3D(
							#Basis(),
							#Vector3(x - 50, 54, y - 50)
						#)
					)
			
		
