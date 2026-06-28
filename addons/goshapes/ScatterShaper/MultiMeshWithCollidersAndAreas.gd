@tool
extends MultiMeshInstance3D
class_name MultiMeshWithCollidersAndAreas

@export
var coords: Vector3i = Vector3i.ZERO

var colliders_container: Node3D
var areas_container: Node3D

# Info: we need this because we can't swap child in a node hierarchy
# And move_child introduces too much mental gymnastics
var areas: Array[MultiMeshInstanceArea] = []
var colliders: Array[MultiMeshInstanceCollider] = []

func _ready() -> void:
	Loggie.msg("MultiMeshWithCollidersAndAreas:_ready").info()
	if !has_node("colliders_container"):
		colliders_container = Node3D.new()
		colliders_container.name = "colliders_container"
		SceneUtils.add_child(self, colliders_container)
	else:
		colliders_container = get_node("colliders_container")
	
	if !has_node("areas_container"):
		areas_container = Node3D.new()
		areas_container.name = "areas_container"
		SceneUtils.add_child(self, areas_container)
	else:
		areas_container = get_node("areas_container")
	
	# FIXME: this is assuming it has not be reordered
	# We could reorder
	# Just pushing an error for now
	var i = 0
	for area: Node3D in areas_container.get_children():
		if area is MultiMeshInstanceArea:
			if area.instance_id != i:
				push_error("area instance_id %s is not it's position %s in the container" % [
					area.instance_id,
					i,
				])
			areas.push_back(area)
		else:
			push_error("area %s is not MultiMeshInstanceArea script: %s path: %s" % [
				area.name,
				area.get_script(),
				self.get_path(),
			])
		
		i += 1
		
	i = 0
	for collider: Node3D in colliders_container.get_children():
		if collider is MultiMeshInstanceCollider:
			if collider.instance_id != i:
				push_error("collider instance_id %s is not it's position %s in the container" % [
					collider.instance_id,
					i,
				])
			colliders.push_back(collider)
		else:
			push_error("collider %s is not MultiMeshInstanceCollider script: %s path: %s" % [
				collider.name,
				collider.get_script(),
				self.get_path(),
			])
			
		i += 1

func add_instance(
	id: int,
	transform_: Transform3D,
	collider: StaticBody3D = null,
	area: Area3D = null
):
	# Info: we consider we have added the instance for now
	var collider_id = -1
	if collider:
		# Info: we do this because of a Godot bug
		# https://github.com/godotengine/godot/issues/120619
		collider.hide()
		collider_id = colliders_container.get_child_count()
		collider.set_script(MultiMeshInstanceCollider)
		#if collider is MultiMeshInstanceCollider:
		collider.multimesh_coord = coords
		collider.instance_id = id
		# TODO : change it once godot has done some issues
		# https://github.com/godotengine/godot/pull/74659
		var my_transform = transform_ * collider.transform
		#var saved_transform: Transform3D = collider.transform
		#var saved_transform: Transform3D = collider.global_transform
		#var saved_global_pos = collider.global_position
		collider.get_parent().remove_child(collider)
		SceneUtils.add_child(colliders_container, collider)
		collider.transform = my_transform
		collider.name = "_MM_Collider3D_%s__%s_%s_%s" % [
			id,
			coords.x,
			coords.y,
			coords.z
		]
	if area:
		area.set_script(MultiMeshInstanceArea)
		if area is MultiMeshInstanceArea:
			area.multimesh_coord = coords
			area.instance_id = id
			area.collider_id = collider_id
			var my_transform = transform_ * area.transform
			area.get_parent().remove_child(area)
			var area_parent: Node3D
			var area_name = "%s_%s_%s" % [
				coords.x,
				coords.y,
				coords.z
			]
			SceneUtils.add_child(areas_container, area)
			area.transform = my_transform
			area.name = "_MM_Area3D_%s__%s_%s_%s" % [
				id,
				coords.x,
				coords.y,
				coords.z
			]
			
	# TODO : would implement here area.set_collider_id

func hide_instance(
	area: MultiMeshInstanceArea
):
	if area.is_hidden:
		#print("MultiMeshWithCollidersAndAreas:hide_instance instance is already hidden %s %s %s %s" % [
			#area.name,
			#self.name,
			#self.multimesh.visible_instance_count,
			#area.instance_id,
		#])
		return
	#print("MultiMeshWithCollidersAndAreas:hide_instance %s %s is_hidden:%s" % [
		#area.name,
		#self.name,
		#area.is_hidden,
	#])
	#
	#print("hide_instance mm visible count %s %s %s" % [
		#self.name,
		#self.multimesh.visible_instance_count,
		#area.name,
	#])
	
	var last_visible_id = self.multimesh.visible_instance_count - 1
	#print("last_visible_id ", last_visible_id, " ", area.name)
	if last_visible_id < 0:
		var multimesh_ = self.multimesh
		var inst_count = multimesh_.visible_instance_count
		var name_ = self.name
		#push_error("last_visible_id < 0 name: %s visible inst count: %s inst count: %s inst name %s" % [
			#self.name,
			#self.multimesh.visible_instance_count,
			#self.multimesh.instance_count,
			#area.name,
		#])
		#printerr("error when handling %s" % [
			#area.name,
		#])
		return
	
	if last_visible_id != area.instance_id:
		var last_trans = self.multimesh.get_instance_transform(
			last_visible_id
		)
		var visible_trans = self.multimesh.get_instance_transform(
			area.instance_id
		)
		self.multimesh.set_instance_transform(
			area.instance_id,
			last_trans
		)
		self.multimesh.set_instance_transform(
			last_visible_id,
			visible_trans
		)
		
		var other_area: MultiMeshInstanceArea = areas.get(last_visible_id)
		
		if area.collider_id != -1:
			var collider: MultiMeshInstanceCollider = colliders.get(area.collider_id)
			if collider:
				collider.instance_id = last_visible_id
				
				area.collider_id = collider.instance_id
			else:
				push_error("collider is null")
				
			var other_collider: MultiMeshInstanceCollider = colliders.get(other_area.collider_id) 
			if other_collider:
				other_collider.instance_id = area.instance_id
		
				other_area.collider_id = other_collider.instance_id
			else:
				push_error("other_collider is null")
				
			colliders.set(collider.instance_id, collider)
			colliders.set(other_collider.instance_id, other_collider)
		else:
			push_warning("area collider id is -1")
		
		other_area.instance_id = area.instance_id
		area.instance_id = last_visible_id
		
		areas.set(area.instance_id, area)
		areas.set(other_area.instance_id, other_area)
		
	else:
		print("same id as last_visible_id ", area.name)
	
	#print("visible instance count before %s %s %s %s" % [
		#self.multimesh.visible_instance_count,
		#area.name,
		#self.name,
		#self.get_path(),
	#])
	
	self.multimesh.visible_instance_count -= 1
	
	area.is_hidden = true
	
	#print("visible instance count after %s %s %s %s" % [
		#self.multimesh.visible_instance_count,
		#area.name,
		#self.name,
		#self.get_path(),
	#])
	
	var collider = colliders.get(area.collider_id)
	
	#print("collider ", collider.name, " ", area.name)
	if collider:
		if collider is StaticBody3D:
			collider.process_mode = Node.PROCESS_MODE_DISABLED
			#print("mode", collider.process_mode)
			#collider.set_deferred("disabled", true)

func show_instance(
	area: MultiMeshInstanceArea
):
	if !area.is_hidden:
		return
	
	# Info: there is no guarantee the next index is the right one
	# Entering/leaving is not necessarily ordered
	
	#print("show_instance %s %s %s is_hidden:%s" % [
		#area.name,
		#area.instance_id,
		#self.name,
		#area.is_hidden
	#])
	#
	#print("show_instance mm visible count %s %s %s" % [
		#self.name,
		#self.multimesh.visible_instance_count,
		#area.name,
	#])
	
	# If 3 visible
	# x,x,x,y
	# Next count will be 4
	# If index is 4    : fine
	# If index is 5    : needs to switch
	# If index is < 4  : bug
	
	# FIXME : there is a bug here
	if area.instance_id < self.multimesh.visible_instance_count:
		push_error("instance_id is %s < visible_instance_count %s : %s %s" % [
			area.instance_id,
			self.multimesh.visible_instance_count,
			area.name,
			self.name,
		])
		return
	elif area.instance_id == self.multimesh.visible_instance_count:
		self.multimesh.visible_instance_count += 1
	else:
		#push_error("instance_id is > visible_instance_count %s %s %s" % [
			#area.instance_id,
			#area.name,
			#self.name,
		#])
		var other_instance_id = self.multimesh.visible_instance_count
		
		switch_instances(area, area.instance_id, other_instance_id)
		
		self.multimesh.visible_instance_count += 1
	
	area.is_hidden = false
	
	#print("visible instance count %s %s %s" % [
		#self.multimesh.visible_instance_count,
		#area.name,
		#self.name,
	#])
	
	var collider = colliders.get(area.collider_id)
	if collider:
		if collider is StaticBody3D:
			collider.process_mode = Node.PROCESS_MODE_INHERIT
			#collider.set_deferred("disabled", false)

func switch_instances(
	area: MultiMeshInstanceArea,
	current_instance_id: int,
	other_instance_id: int,
):
	var last_trans = self.multimesh.get_instance_transform(
		other_instance_id
	)
	var visible_trans = self.multimesh.get_instance_transform(
		current_instance_id
	)
	self.multimesh.set_instance_transform(
		current_instance_id,
		last_trans
	)
	self.multimesh.set_instance_transform(
		other_instance_id,
		visible_trans
	)
	
	var other_area: MultiMeshInstanceArea = areas.get(other_instance_id)
	
	if area.collider_id != -1:
		var collider: MultiMeshInstanceCollider = colliders.get(area.collider_id)
		if collider:
			collider.instance_id = other_instance_id
			
			area.collider_id = collider.instance_id
		else:
			push_error("collider is null")
			
		var other_collider: MultiMeshInstanceCollider = colliders.get(other_area.collider_id) 
		if other_collider:
			other_collider.instance_id = area.instance_id
	
			other_area.collider_id = other_collider.instance_id
		else:
			push_error("other_collider is null")
			
		colliders.set(collider.instance_id, collider)
		colliders.set(other_collider.instance_id, other_collider)
	else:
		push_warning("area collider id is -1")
	
	other_area.instance_id = area.instance_id
	area.instance_id = other_instance_id
	
	areas.set(area.instance_id, area)
	areas.set(other_area.instance_id, other_area)

#region "collider version"

# Info: does not work currently

#func hide_instance_collider_version(
	#instance: MultiMeshInstanceCollider
#):
	#var mm: MultiMeshInstance3D = coord_to_multimesh.get(instance.multimesh_coord)
	#var last_visible_id = mm.multimesh.visible_instance_count - 1
	#var last_trans = mm.multimesh.get_instance_transform(
		#last_visible_id
	#)
	#var visible_trans = mm.multimesh.get_instance_transform(
		#instance.instance_id
	#)
	#mm.multimesh.set_instance_transform(
		#instance.instance_id,
		#last_trans
	#)
	#mm.multimesh.set_instance_transform(
		#last_visible_id,
		#visible_trans
	#)
	#mm.multimesh.visible_instance_count -= 1
	#
	#instance.instance_id = last_visible_id
#
#func show_instance_collider_version(
	#instance: MultiMeshInstanceCollider
#):
	#var mm: MultiMeshInstance3D = coord_to_multimesh.get(instance.multimesh_coord)
	#mm.multimesh.visible_instance_count += 1

#endregion
