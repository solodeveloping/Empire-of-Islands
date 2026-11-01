@tool
extends Area3D
class_name BuildingEditableChildrenArea

signal state_changed()
signal multimesh_instance_area_entered(area: MultiMeshInstanceArea)
signal multimesh_instance_area_exited(area: MultiMeshInstanceArea)

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var overlapping_areas: Array[Area3D] = []
var overlapping_bodies: Array[Node3D] = []

var is_empty: bool:
	get:
		return overlapping_areas.is_empty() and overlapping_bodies.is_empty()

func _ready() -> void:
	print("BuildingEditableChildrenArea %s %s %s" % [
		get_path(),
		collision_layer,
		collision_mask,
	])

func _on_area_entered(area: Area3D) -> void:
	# TODO : handle self sensors
	print("_on_area_entered %s %s" % [
		area.name,
		area.get_path()
	])
	
	if area is MultiMeshInstanceArea:
		multimesh_instance_area_entered.emit(area)
	else:
		#if area.get_parent() is SquareExtension_1:
			#print("parent is SquareExtension_1")
			#return
		overlapping_areas.append(area)
	
	#overlapping_areas.append(area)
	
	state_changed.emit()

func _on_area_exited(area: Area3D) -> void:
	#print("_on_area_exited %s %s" % [
		#area.name,
		#self.main_area_3d.get_path()
	#])
	if area is MultiMeshInstanceArea:
		multimesh_instance_area_exited.emit(area)
	else:
		overlapping_areas.erase(area)
	
	#overlapping_areas.erase(area)
	
	state_changed.emit()

func _on_body_entered(body: Node3D) -> void:
	#print(
		#"_on_body_entered ",
		#body.name,
		#body.get_path(),
	#)
	if body is MultiMeshInstanceCollider:
		return
		
	overlapping_bodies.append(body)
	
	state_changed.emit()

func _on_body_exited(body: Node3D) -> void:
	#print("_on_body_exited ", body.name)
	#var parent_ = body.get_parent()
	if body is MultiMeshInstanceCollider:
		return
	
	overlapping_bodies.erase(body)
	
	state_changed.emit()
