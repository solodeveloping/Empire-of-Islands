extends Node2D
class_name StaticMinimapSystem2D

# TODO: world_2d proposal in godot proposals
# TODO: update 3D version with this
# Don't need the initial attempts anymore

@export
var sub_viewport: SubViewport

@export
var sub_viewport_camera: Camera2D

@export
var tile_map_layer: TileMapLayer

@export
var extra_padding := Vector2(0, 0)

@export
var minimap_with_shader_texture_rect: TextureRect

## smaller means more zoomed in
@export
var current_zoom: float = 0.4

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

var minimap_center: Vector2 = Vector2.ZERO

var time: float = 0
var refresh_time: float = 0.25

func _ready() -> void:
	print("StaticMinimapSystem2D:_ready")
	#print("camera %s %s" % [
		#sub_viewport.get_camera_2d(),
		#sub_viewport_camera,
	#])
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
	
	# This is the used rect of the tile_map_layer
	var used_rect: Rect2i = tile_map_layer.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		push_error("used_rect is ZERO")
		return
	
	# map_to_local returns cell center's positions
	# the end of Rect2i is exclusive
	var end: Vector2i = used_rect.end - Vector2i.ONE
	var points := [
		tile_map_layer.to_global(tile_map_layer.map_to_local(used_rect.position)),
		tile_map_layer.to_global(tile_map_layer.map_to_local(Vector2i(end.x, used_rect.position.y))),
		tile_map_layer.to_global(tile_map_layer.map_to_local(Vector2i(used_rect.position.x, end.y))),
		tile_map_layer.to_global(tile_map_layer.map_to_local(end)),
	]
	
	print("points %s" % [
		points,
	])
	
	# (8160.0, 16.0)
	# middle right of the diamond

	# expand all points
	# it makes so the Rect2 encloses the points
	var rect2: Rect2 = Rect2(
		# position
		points[0],
		# size
		Vector2.ZERO
	)
	for point in points:
		rect2 = rect2.expand(point)
	
	# FIXME: there is probably a better way?
	
	# this is one X unit
	var x_step: Vector2 = tile_map_layer.map_to_local(used_rect.position + Vector2i.RIGHT) \
		- tile_map_layer.map_to_local(used_rect.position)
	
	# this is one Y unit
	var y_step: Vector2 = tile_map_layer.map_to_local(used_rect.position + Vector2i.DOWN) \
		- tile_map_layer.map_to_local(used_rect.position)
	
	# FIXME: useless?
	# padding as vect2
	var padding: Vector2 = (x_step.abs() + y_step.abs()) * 0.5 + extra_padding

	# extend the rect by the given amount on each side
	# must be positive to grow
	rect2 = rect2.grow_individual(
		padding.x,
		padding.y,
		padding.x,
		padding.y
	)
	
	print("StaticMinimapSystem2D rect: %s" % [
		rect2,
	])
	
	# center the sub_viewport's camera on the bound's center
	sub_viewport_camera.global_position = rect2.get_center()
	
	# assing it to the minimap_center value for the shader
	minimap_center = rect2.get_center()
	
	# no size in sub_viewport.get_viewport()
	
	#print("1", sub_viewport_camera.get_viewport_rect().size)
	#print("2", sub_viewport.size)
	
	# same as sub_viewport.size but is Vector2 not Vector2i
	var sub_viewport_size: Vector2 = sub_viewport_camera.get_viewport_rect().size
	# rect2 is big
	# sub_viewport_size is smaller
	# dividing gives a ratio
	# min make sure we see all
	var zoom: float = min(
		sub_viewport_size.x / rect2.size.x,
		sub_viewport_size.y / rect2.size.y
	)
	# Higher values are more zoomed in
	sub_viewport_camera.zoom = Vector2.ONE * zoom
	
	# TODO: no editor support, make issue or proposal
	sub_viewport.world_2d = get_viewport().world_2d
	
	if current_zoom <= min_zoom_level_for_shader:
		is_zoom_in_enabled = false
		event_bus.send_minimap_disable_zoom_in.emit()
		current_zoom = min_zoom_level_for_shader
	if current_zoom >= max_zoom_level_for_shader:
		is_zoom_out_enabled = false
		event_bus.send_minimap_disable_zoom_out.emit()
		current_zoom = max_zoom_level_for_shader
	
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/texture_size",
		sub_viewport.size
	)
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/current_zoom_level",
		current_zoom
	)
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/map_center_global_position",
		Vector2(
			minimap_center.x,
			minimap_center.y,
		)
	)
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/map_world_size",
		rect2.size
	)
	
	render()

func render():
	#print("render")
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await RenderingServer.frame_post_draw
	
	var image = sub_viewport.get_texture().get_image()
	var texture = ImageTexture.create_from_image(image)
	
	#var filename = "user://minimap_%s_2d.png" % [
		#save_count,
	#]
	#image.save_png(filename)
	#var global_path = ProjectSettings.globalize_path(
		#filename
	#)
	#print("path %s" % [
		#global_path,
	#])
	#print("minimap image saved")
	
	minimap_with_shader_texture_rect.texture = texture
	

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
	
	#print("zoom %s" % [
		#current_zoom,
	#])
	
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/current_zoom_level",
		current_zoom
	)
	
	reposition()
	#render()

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
	
	#print("zoom %s" % [
		#current_zoom,
	#])
	
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/current_zoom_level",
		current_zoom
	)
	
	reposition()

func _physics_process(delta: float) -> void:
	#return
	time += delta
	if time < refresh_time:
		return
	time = 0
	
	reposition()

func reposition():
	reposition_for_minimap_with_shader()

func reposition_for_minimap_with_shader():
	# move left and X diminish
	# move bottom and Y increase
	
	var pos = get_viewport().get_camera_2d().global_position
	#print("")
	#print("pos %s" % [
		#pos,
	#])
	minimap_with_shader_texture_rect.material.set(
		"shader_parameter/player_global_position",
		Vector2(
			pos.x,
			#8192/2,
			#8192/4,
			# Info: we have this because the Y coord takes twice
			# less place on the image
			# because of the isometric projection
			pos.y / 2,
		)
	)
	
	# Info: for when I had to debug the shader
	
	#for parameter in minimap_with_shader_texture_rect.material.shader.get_shader_uniform_list():
		#print("%s : %s" % [
			#parameter.name,
			#minimap_with_shader_texture_rect.material.get_shader_parameter(parameter.name),
		#])

	#_evaluate_shader_code()

# TODO: would be nice to automatize this
func _evaluate_shader_code():
	var uv: Vector2 = Vector2(0.5, 0.5)
	
	#var zoom_level = zoom_level;
	var clamp_zoom_level = minimap_with_shader_texture_rect.material.get_shader_parameter(
		"clamp_zoom_level"
	)
	var current_zoom_level = minimap_with_shader_texture_rect.material.get_shader_parameter(
		"current_zoom_level"
	)
	var min_zoom_level = minimap_with_shader_texture_rect.material.get_shader_parameter(
		"min_zoom_level"
	)
	var max_zoom_level = minimap_with_shader_texture_rect.material.get_shader_parameter(
		"max_zoom_level"
	)
	var min_visible_size = minimap_with_shader_texture_rect.material.get_shader_parameter(
		"min_visible_size"
	)
	var max_visible_size = minimap_with_shader_texture_rect.material.get_shader_parameter(
		"max_visible_size"
	)
	var zoom_level = current_zoom_level
	if (clamp_zoom_level == true):
		zoom_level = clamp(
			zoom_level,
			min_zoom_level,
			max_zoom_level
		)
	
	var visible_size = Vector2(
		remap(
			zoom_level,
			0,
			1,
			min_visible_size.x,
			max_visible_size.x
		),
		remap(
			zoom_level,
			0,
			1,
			min_visible_size.y,
			max_visible_size.y
		)
	)
	
	# Are there a better way?
	var uv_size = Vector2(
		remap(
			visible_size.x,
			min_visible_size.x,
			max_visible_size.x,
			0,
			1
		),
		remap(
			visible_size.y,
			min_visible_size.y,
			max_visible_size.y,
			0,
			1
		)
	)
	
	var map_size = minimap_with_shader_texture_rect.material.get_shader_parameter(
		"map_size"
	)
	var half_map_size = map_size / 2.0;
	var map_center_global_position = minimap_with_shader_texture_rect.material.get_shader_parameter(
		"map_center_global_position"
	)
	var top_left_global_position: Vector2 = map_center_global_position - half_map_size;
	var bottom_right_global_position = top_left_global_position + map_size
	#var bottom_right_global_position = half_map_size
	var player_global_position = minimap_with_shader_texture_rect.material.get_shader_parameter(
		"player_global_position"
	)
	var player_uv_pos = Vector2(
		remap(
			# 0
			player_global_position.x,
			# -256
			top_left_global_position.x,
			# 256
			bottom_right_global_position.x,
			0,
			#-1.0,
			#-1.0 * uv_size.x,
			1.0
			#1.0 * uv_size.x
		),
		remap(
			player_global_position.y,
			top_left_global_position.y,
			bottom_right_global_position.y,
			#-1.0,
			0.0,
			#-1.0 * uv_size.y,
			1.0
			#1.0 * uv_size.y
		)
	)
	
	#var top_left_uv = player_uv_pos
	#var player_uv_pos_scaled = player_uv_pos * uv_size
	
	# -1 to 1 and 0 to 1
	var start_uv_x = player_uv_pos.x - uv_size.x/2.0
	var start_uv_y = player_uv_pos.y - uv_size.y/2.0
	
	var end_uv_x = start_uv_x + uv_size.x
	var end_uv_y = start_uv_y + uv_size.y
	
	var result_uv = Vector2(
		remap(
			uv.x,
			0,
			1,
			#start_uv_x,
			start_uv_x,
			#end_uv_x
			end_uv_x
		),
		remap(
			uv.y,
			0,
			1,
			#start_uv_y,
			start_uv_y,
			#end_uv_y
			end_uv_y
		)
	)
	print("")
