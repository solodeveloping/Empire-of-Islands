## This position a node at the center of the camera view
## And properly collides with the body at the center
extends Node3D
class_name PositionNodeAtCameraCenterView

@export_flags_3d_physics
var physics_layers: int = 0

@export
var camera: Camera3D

@export
var update_time: float = 0.25

@export
var target: Node3D

var time: float = 0

func _physics_process(delta: float) -> void:
	time += delta
	if time < update_time:
		return
	time = 0
	
	var space = get_world_3d().direct_space_state
	
	var target_pos = camera.project_position(
		get_viewport().get_visible_rect().size / 2.0,
		1000,
	)
	
	var params = PhysicsRayQueryParameters3D.create(
		camera.global_position,
		target_pos
	)
	
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.collision_mask = physics_layers

	var raycast_result = space.intersect_ray(params)

	if !raycast_result.is_empty():
		target.global_position = raycast_result.position
	
