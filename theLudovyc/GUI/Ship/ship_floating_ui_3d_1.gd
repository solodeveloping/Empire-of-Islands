extends Node3D
class_name ShipFloatingUI3D_1

# FIXME: is this still used?
# I think it's not

@onready var ship_floating_ui_for_3d_1: ShipFloatingUIFor3D_1 = $SubViewport/ShipFloatingUIFor3D_1

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var sub_viewport: SubViewport = $SubViewport

@onready var sprite_3d_2: Sprite3D = $Sprite3D2

@export
var min_scale: float = 0.2

@export
var max_scale: float = 1

func set_content(
	entity: Entity,
	local_player_faction_id: int,
):
	ship_floating_ui_for_3d_1.set_content(
		entity,
		local_player_faction_id
	)
	sub_viewport.size = ship_floating_ui_for_3d_1.size
	
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func update_scale():
	# TODO: can do this more often
	
	# TODO: increase size of UI and diminish size: clearer UI

	var cam = get_viewport().get_camera_3d()
	var dist = cam.global_position.distance_to(
		self.global_position
	)
	
	dist = clampf(
		dist,
		0,
		100,
	)
	
	var scale = remap(
		dist,
		0,
		100,
		min_scale,
		max_scale,
	)
	
	sprite_3d.scale = Vector3(
		scale,
		scale,
		scale
	)

# TODO: this is bad
# still get called when not visible

func _on_UpdateSpriteScaleTimer_timeout() -> void:
	update_scale()
