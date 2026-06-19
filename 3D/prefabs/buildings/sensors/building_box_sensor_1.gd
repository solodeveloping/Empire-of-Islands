@tool
extends Node3D
class_name BuildingRiverWaterSensor1

# TODO: rename it to BuildingBoxSensor1?

signal state_changed()
signal multimesh_instance_area_entered(area: MultiMeshInstanceArea)
signal multimesh_instance_area_exited(area: MultiMeshInstanceArea)

@onready var collision_shape_3d: CollisionShape3D = $MainArea3D/CollisionShape3D

@export
var size: Vector3:
	get:
		return size
	set(value):
		size = value
		if collision_shape_3d:
			collision_shape_3d.shape.size = size

var overlapping_areas: Array[Area3D] = []
var overlapping_bodies: Array[Node3D] = []

var is_empty: bool:
	get:
		return overlapping_areas.is_empty() and overlapping_bodies.is_empty()

#func _ready():
	#var inspector = EditorInterface.get_inspector()
	#inspector.property_edited.connect(_on_property_edited)
#
#func _on_property_edited(property: String):
	#var inspector = EditorInterface.get_inspector()
	#var edited_object = inspector.get_edited_object()
	#if edited_object:
		#print("Edited: ", edited_object.name, " - Property: ", property)

func _on_MainArea3d_area_entered(area: Area3D) -> void:
	# TODO : handle self sensors
	if area is MultiMeshInstanceArea:
		multimesh_instance_area_entered.emit(area)
	else:
		overlapping_areas.append(area)
	
	#overlapping_areas.append(area)
	
	state_changed.emit()

func _on_MainArea3d_area_exited(area: Area3D) -> void:
	if area is MultiMeshInstanceArea:
		multimesh_instance_area_exited.emit(area)
	else:
		overlapping_areas.erase(area)
	
	#overlapping_areas.erase(area)
	
	state_changed.emit()

func _on_MainArea3d_body_entered(body: Node3D) -> void:
	#print("_on_MainArea3d_body_entered")
	if body is MultiMeshInstanceCollider:
		return
	overlapping_bodies.append(body)
	
	state_changed.emit()

func _on_MainArea3d_body_exited(body: Node3D) -> void:
	if body is MultiMeshInstanceCollider:
		return
	overlapping_bodies.erase(body)
	
	state_changed.emit()
