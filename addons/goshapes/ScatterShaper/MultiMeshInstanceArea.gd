@tool
extends Area3D
class_name MultiMeshInstanceArea

@export
var multimesh_coord: Vector3i = Vector3i.ZERO
@export
var instance_id: int = 0
@export
var collider_id: int = -1
@export
var is_hidden: bool = false
