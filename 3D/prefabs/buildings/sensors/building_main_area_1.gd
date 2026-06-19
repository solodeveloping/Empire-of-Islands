@tool
extends Node3D
class_name BuildingMainArea1

signal state_changed()
signal multimesh_instance_area_entered(area: MultiMeshInstanceArea)
signal multimesh_instance_area_exited(area: MultiMeshInstanceArea)

@onready var main_area_3d: Area3D = $MainArea3D
@onready var collision_shape_3d: CollisionShape3D = $MainArea3D/CollisionShape3D

@export
var radius := 1.0:
	get:
		return radius
	set(value):
		radius = value
		if collision_shape_3d:
			collision_shape_3d.shape.radius = radius

var overlapping_areas: Array[Area3D] = []
var overlapping_bodies: Array[Node3D] = []

var is_empty: bool:
	get:
		return overlapping_areas.is_empty() and overlapping_bodies.is_empty()

func _ready() -> void:
	collision_shape_3d.shape.radius = radius

func _on_MainArea3d_area_entered(area: Area3D) -> void:
	# TODO : handle self sensors
	#print("BuildingMainArea1:_on_MainArea3d_area_entered %s %s" % [
		#area.name,
		#self.main_area_3d.get_path()
	#])
	
	if area is MultiMeshInstanceArea:
		multimesh_instance_area_entered.emit(area)
	else:
		overlapping_areas.append(area)
	
	#overlapping_areas.append(area)
	
	state_changed.emit()

func _on_MainArea3d_area_exited(area: Area3D) -> void:
	#print("BuildingMainArea1:_on_MainArea3d_area_exited %s %s" % [
		#area.name,
		#self.main_area_3d.get_path()
	#])
	if area is MultiMeshInstanceArea:
		multimesh_instance_area_exited.emit(area)
	else:
		overlapping_areas.erase(area)
	
	#overlapping_areas.erase(area)
	
	state_changed.emit()

func _on_MainArea3d_body_entered(body: Node3D) -> void:
	#print(
		#"_on_MainArea3d_body_entered ",
		#body.name,
		#body.get_parent().name,
	#)
	if body is MultiMeshInstanceCollider:
		return
		#trees.push_back(body)
		#var grid = SceneUtils.find_first_parent_of_type(
			#body,
			#GridMultiMesh
		#)
		#
		#if grid:
			#grid.hide_instance(body)
		#else:
			#printerr("could not find parent")
	#else:
		#overlapping_bodies.append(body)
		
	overlapping_bodies.append(body)
	
	state_changed.emit()

func _on_MainArea3d_body_exited(body: Node3D) -> void:
	#print("_on_MainArea3d_body_exited ", body.name)
	#var parent_ = body.get_parent()
	if body is MultiMeshInstanceCollider:
		return
		#if body in trees:
			#trees.erase(body)
			#var grid = SceneUtils.find_first_parent_of_type(
				#body,
				#GridMultiMesh
			#)
			#
			#if grid:
				#grid.show_instance(body)
		#else:
			#printerr("could not find parent")
	#else:
		#overlapping_bodies.erase(body)
	
	overlapping_bodies.erase(body)
	
	state_changed.emit()
