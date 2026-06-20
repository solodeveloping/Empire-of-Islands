extends Node3D
class_name GroundSensorEditable1

signal state_changed()

@export_flags_3d_physics
var ray_ground_layers: int = 0

@onready var sensors: Node3D = $sensors

var is_valid: bool = true

func hide_sprites():
	for sensor in sensors.get_children():
		sensor.hide_sprite()
	
func show_sprites():
	for sensor in sensors.get_children():
		sensor.show_sprite()

func _on_UpdateSensorsTimer_timeout() -> void:
	# TODO: this is not working
	#get_tree().physics_frame.connect(update_rays, Object.CONNECT_ONE_SHOT)
	update_rays()

func update_rays():
	var is_valid_initial_state = is_valid
	is_valid = true
	for sensor in sensors.get_children():
		var world_3d = self.get_world_3d()
		if !world_3d:
			# FIXME: something cleanr
			# might happen if we are removing the node
			return
		var space = world_3d.direct_space_state
		var ray_origin = sensor.global_position# + Vector3(0, 0.5, 0)
		var ray_end = ray_origin + Vector3(0, -1, 0)
		var params = PhysicsRayQueryParameters3D.create(
			ray_origin,
			ray_end
		)
		
		params.collide_with_bodies = true
		params.collide_with_areas = false
		params.collision_mask = ray_ground_layers

		var raycast_result = space.intersect_ray(params)

		if !raycast_result.is_empty():
			sensor.change_sprite_modulate_color(Color.GREEN)
		else:
			sensor.change_sprite_modulate_color(Color.RED)
			is_valid = false
	
	if is_valid != is_valid_initial_state:
		state_changed.emit()
