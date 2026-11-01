extends Node
class_name StaticMinimapSystem

# TODO: remove old system
# thought of using a moving image at first
# we are using a shader instead

## This will be set by the main since we are instancing a RTSCamera
@export
#var player_camera: Camera3D
var center_target_node: Node3D

@export
var sub_viewport: SubViewport

## This is the Orthogonal/TopDown camera
@export
var minimap_camera: Camera3D

@export
var minimap_texture_rect: TextureRect

@export
var minimap_with_shader_texture_rect: TextureRect

@export
var minimap_mask_texture_rect: TextureRect

@export
var minimap_size: float = 512

@export
var minimap_center: Vector3 = Vector3.ZERO

# Scale: 2.0 makes the image bigger: zooming in
# And smaller makes it smaller, zooming out	
@export
var min_scale_zoom_value: float = 1

@export
var max_scale_zoom_value: float = 2

@export
var zoom_step_above_1: float = 0.1

@export
var zoom_step_below_1: float = 0.1

@export
var min_zoom_level_for_shader: float = 0.1

@export
var max_zoom_level_for_shader: float = 1.0

var event_bus: EventBus

var save_count: int = 0

var is_zoom_in_enabled: bool = true
var is_zoom_out_enabled: bool = true

var current_zoom: float = 1.0

var time: float = 0
var refresh_time: float = 0.25

func _ready() -> void:
	if get_tree().current_scene.has_node("EventBus"):
		event_bus = get_tree().current_scene.get_node("EventBus")
		
		event_bus.send_minimap_data_changed.connect(
			_on_event_bus_send_minimap_data_changed
		)
		
		event_bus.ask_minimap_zoom_in.connect(
			_on_event_bus_ask_minimap_zoom_in
		)
		
		event_bus.ask_minimap_zoom_out.connect(
			_on_event_bus_ask_minimap_zoom_out
		)
	
	# For texture system
	#current_zoom = minimap_texture_rect.scale.x
	#if current_zoom >= max_scale_zoom_value:
		#is_zoom_in_enabled = false
		#event_bus.send_minimap_disable_zoom_in.emit()
	#if current_zoom <= min_scale_zoom_value:
		#is_zoom_out_enabled = false
		#event_bus.send_minimap_disable_zoom_out.emit()
	
	if current_zoom <= min_zoom_level_for_shader:
		is_zoom_in_enabled = false
		event_bus.send_minimap_disable_zoom_in.emit()
	if current_zoom >= max_zoom_level_for_shader:
		is_zoom_out_enabled = false
		event_bus.send_minimap_disable_zoom_out.emit()
	
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/texture_size",
		sub_viewport.size
	)
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/map_size",
		Vector2(minimap_camera.size, minimap_camera.size)
	)
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/current_zoom_level",
		current_zoom
	)
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/map_center_global_position",
		Vector2(
			minimap_center.x,
			minimap_center.z,
		)
	)
	
	render()

func _on_event_bus_send_minimap_data_changed():
	print("_on_event_bus_send_minimap_data_changed")
	render()

# We increase the scale
func _on_event_bus_ask_minimap_zoom_in():
	_on_event_bus_ask_minimap_zoom_in_for_shader()
	
func _on_event_bus_ask_minimap_zoom_in_for_shader():
	# zoom in is zoom_level going down here
	if current_zoom <= min_zoom_level_for_shader:
		printerr("current_zoom <= min_zoom_level_for_shader")
		is_zoom_in_enabled = false
		event_bus.send_minimap_disable_zoom_in.emit()
		return
	
	if current_zoom <= 1.0:
		current_zoom -= zoom_step_below_1
	else:
		current_zoom -= zoom_step_above_1
	
	if current_zoom <= min_zoom_level_for_shader:
		is_zoom_in_enabled = false
		event_bus.send_minimap_disable_zoom_in.emit()
	
	if is_zoom_out_enabled == false:
		if current_zoom < max_zoom_level_for_shader:
			is_zoom_out_enabled = true
			event_bus.send_minimap_enable_zoom_out.emit()
	
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/current_zoom_level",
		current_zoom
	)
	
	reposition()
	#render()

func _on_event_bus_ask_minimap_zoom_in_for_texture():
	# Assuming they're not the same value
	if !is_zoom_in_enabled:
		printerr("!is_zoom_in_enabled")
		return
	
	if current_zoom >= 1.0:
		current_zoom += zoom_step_above_1
	else:
		current_zoom += zoom_step_below_1
	
	minimap_texture_rect.scale.x = current_zoom
	minimap_texture_rect.scale.y = current_zoom
	
	if current_zoom >= max_scale_zoom_value:
		is_zoom_in_enabled = false
		event_bus.send_minimap_disable_zoom_in.emit()
	
	if !is_zoom_out_enabled:
		if current_zoom >= min_scale_zoom_value:
			is_zoom_out_enabled = true
			event_bus.send_minimap_enable_zoom_out.emit()
	
	reposition()
	render()

# We diminish the scale
func _on_event_bus_ask_minimap_zoom_out():
	_on_event_bus_ask_minimap_zoom_out_for_shader()
	
func _on_event_bus_ask_minimap_zoom_out_for_shader():
	# zoom out is zoom_level going up here
	if current_zoom >= max_zoom_level_for_shader:
		printerr("current_zoom >= max_zoom_level_for_shader")
		is_zoom_out_enabled = false
		event_bus.send_minimap_disable_zoom_out.emit()
		return
	
	if current_zoom >= 1.0:
		current_zoom += zoom_step_above_1
	else:
		current_zoom += zoom_step_below_1
	
	if current_zoom >= max_zoom_level_for_shader:
		is_zoom_out_enabled = false
		event_bus.send_minimap_disable_zoom_out.emit()
	
	if is_zoom_in_enabled == false:
		if current_zoom > min_zoom_level_for_shader:
			is_zoom_in_enabled = true
			event_bus.send_minimap_enable_zoom_in.emit()
	
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/current_zoom_level",
		current_zoom
	)
	
	reposition()
	
	
func _on_event_bus_ask_minimap_zoom_out_for_texture():
	if !is_zoom_out_enabled:
		printerr("!is_zoom_out_enabled")
		return
	
	if current_zoom <= 1.0:
		current_zoom -= zoom_step_below_1
	else:
		current_zoom -= zoom_step_above_1
	
	minimap_texture_rect.scale.x = current_zoom
	minimap_texture_rect.scale.y = current_zoom
	
	if current_zoom <= min_scale_zoom_value:
		is_zoom_out_enabled = false
		event_bus.send_minimap_disable_zoom_out.emit()
	
	if !is_zoom_in_enabled:
		if current_zoom <= max_scale_zoom_value:
			is_zoom_in_enabled = true
			event_bus.send_minimap_enable_zoom_in.emit()
	
	reposition()
	render()

func render():
	minimap_camera.size = minimap_size
	
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await RenderingServer.frame_post_draw
	
	var image = sub_viewport.get_texture().get_image()
	var texture = ImageTexture.create_from_image(image)
	
	#var filename = "user://minimap_%s.png" % [
		#save_count,
	#]
	#image.save_png(filename)
	#save_count += 1
	#
	minimap_texture_rect.texture = texture
	minimap_with_shader_texture_rect.texture = texture

func _physics_process(delta: float) -> void:
	#return
	time += delta
	if time < refresh_time:
		return
	time = 0
	
	reposition()

func reposition():
	#reposition_for_normal_texture()
	reposition_for_minimap_with_shader()

# TODO?: could get inspiration from the shader and implement
# the correct zoom functionality
# Info: not working that well
# maybe we need to scale the offset or something
func reposition_for_normal_texture():
	# Scale: 2.0 makes the image bigger: zooming in
	# And smaller makes it smaller, zooming out
	var minimap_texture_rect_size_x_scaled = minimap_texture_rect.size.x * minimap_texture_rect.scale.x
	var minimap_texture_rect_size_y_scaled = minimap_texture_rect.size.y * minimap_texture_rect.scale.y
	
	# Gives us the position relative to the texture
	#var cam_pos_scaled_x: float = remap(
		#center_target_node.global_position.x - minimap_center.x,
		#-minimap_size / 2.0,
		#minimap_size / 2.0,
		#-sub_viewport.size.x / 2.0,
		#sub_viewport.size.x / 2.0
	#)
	## In 3D, this is not y, it's z
	#var cam_pos_scaled_y: float = remap(
		#center_target_node.global_position.z - minimap_center.y,
		#-minimap_size / 2.0,
		#minimap_size / 2.0,
		#-sub_viewport.size.y / 2.0,
		#sub_viewport.size.y / 2.0
	#)
	var half_sub_viewport_scaled = (sub_viewport.size.x/2) * minimap_texture_rect.scale.x
	var cam_pos_scaled_x: float = remap(
		center_target_node.global_position.x - minimap_center.x,
		-minimap_size / 2.0,
		minimap_size / 2.0,
		-half_sub_viewport_scaled,
		half_sub_viewport_scaled
	)
	# In 3D, this is not y, it's z
	var cam_pos_scaled_y: float = remap(
		center_target_node.global_position.z - minimap_center.y,
		-minimap_size / 2.0,
		minimap_size / 2.0,
		-half_sub_viewport_scaled,
		half_sub_viewport_scaled
	)
	
	#print("target %s %s %s %s" % [
		#center_target_node.get_path(),
		#get_viewport().get_camera_3d().global_position,
		#center_target_node.global_position,
		#minimap_camera.global_position,
	#])
	#print("StaticMinimapSystem %s %s %s" % [
		#center_target_node.global_position,
		#cam_pos_scaled_x,
		#cam_pos_scaled_y,
	#])
	#print("zoom %s" % [
		#current_zoom,
	#])
	
	var texture_min_x_pos: float = -(minimap_texture_rect_size_x_scaled - minimap_mask_texture_rect.size.x)
	var texture_min_y_pos: float = -(minimap_texture_rect_size_y_scaled - minimap_mask_texture_rect.size.y)
	
	#var texture_max_x_pos: float = 0
	#var texture_max_y_pos: float = 0
	
	#print("StaticMinimapSystem texture_min_x_pos %s" % [
		#texture_min_x_pos,
	#])
	#print("StaticMinimapSystem texture_min_y_pos %s" % [
		#texture_min_y_pos,
	#])
	
	var pos_x: float = remap(
		cam_pos_scaled_x,
		#-sub_viewport.size.x / 2,
		-half_sub_viewport_scaled,
		#-sub_viewport.size.x / 2,
		half_sub_viewport_scaled,
		0.0,
		texture_min_x_pos,
	)
	var pos_y: float = remap(
		cam_pos_scaled_y,
		#-sub_viewport.size.y / 2,
		-half_sub_viewport_scaled,
		#sub_viewport.size.y / 2,
		half_sub_viewport_scaled,
		0.0,
		texture_min_y_pos,
	)
	
	minimap_texture_rect.position = Vector2(
		pos_x,
		pos_y,
	)
	
	print("StaticMinimapSystem: result %s" % [
		minimap_texture_rect.position,
	])

# When centered, the zoom center keeps at the same pos
func reposition_for_texture_2d():
	# the position is at 130,130 when centered (approx)
	# and size 512
	# top left is 256 256 if correctly setup
	pass

func reposition_for_minimap_with_shader():
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/player_global_position",
		Vector2(
			center_target_node.global_position.x,
			center_target_node.global_position.z,
		)
	)
