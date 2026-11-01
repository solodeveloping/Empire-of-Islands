extends TextureRect
class_name FOWTextureRect2D

#@onready var sprite: Sprite2D = $Sprite2D

const MAX_OBJECT_COUNT_SHADER: int = 512

# size of one object in bytes
const OBJECT_BYTE_SIZE: int = 32

@export
var only_use_local_player_faction_id: bool = true

@export
var output_width: int = 512

@export
var output_height: int = 512

@export
var texture_rect: TextureRect

@onready var target_mask: Node2D = $"../../TargetMask"

@onready var ship_navigation_region_2d: NavigationRegion2D = $"../../ShipNavigationRegion2D"

var target_world_position := Vector2(500, 300)

var entities: Array[Entity] = []

var event_bus: EventBus
var objects: PackedVector4Array = PackedVector4Array()

#var node_2ds: Array[UnitVisionRangeDefinition] = []

var local_player_faction_id: int = 0

var was_initialized: bool = false

var map_rect: Rect2

var rd: RenderingDevice

var shader_rid: RID
var pipeline_rid: RID
# Could have multiple?
var uniform_set_rid: RID
var node_2ds_buffer_rid: RID

var output_texture_rid: RID

var display_texture: Texture2DRD
var previous_texture_rid: RID
var current_texture_rid: RID
var uniform_sets: Array[RID] = []
var buffer_state: int = 0

func _ready() -> void:
	var current_scene = get_tree().current_scene
	if current_scene.has_node("EventBus"):
		print("TestDisplayShipsData: has EventBus")
		event_bus = current_scene.get_node("EventBus")
		
		event_bus.send_visible_entity_added.connect(
			_on_event_bus_send_visible_entity_added
		)
		event_bus.send_visible_entity_removed.connect(
			_on_event_bus_send_visible_entity_removed
		)
		
		event_bus.send_local_player_faction_id_changed.connect(
			_on_event_bus_send_local_player_faction_id_changed
		)
		
	
	var rect = get_scene_aabb(current_scene)
	#print("rect", rect)
	#print("nav_mesh rect", ship_navigation_region_2d.get_bounds())
	
	map_rect = rect
	
	material.set_shader_parameter(
		"world_size",
		rect.size,
	)
	material.set_shader_parameter(
		"world_origin",
		rect.position,
	)
	_initialize_compute_shader()
	
	_refresh_shader_objects()
	
	
func _initialize_compute_shader():
	var shader_file: RDShaderFile = ResourceLoader.load(
		"uid://bcqp2k7udvdte",
		"",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP,
	)
	
	#rd = RenderingServer.create_local_rendering_device()
	rd = RenderingServer.get_rendering_device()
	
	if rd == null:
		push_error(
			"A RenderingDevice is unavailable. " +
		    "Use Forward+ or Mobile instead of Compatibility."
		)
	
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader_rid = rd.shader_create_from_spirv(shader_spirv)
	
	# to recreate only if the shader changes
	pipeline_rid = rd.compute_pipeline_create(shader_rid)
	
	create_textures()
	
	material.set_shader_parameter(
		"small_tex",
		display_texture
	)
	
	if texture_rect:
		texture_rect.texture = display_texture
	
	_create_objects_buffer()
	_create_uniform_sets()
	
func _exit_tree() -> void:
	if rd == null:
		return

	rd.free_rid(node_2ds_buffer_rid)
	#rd.free_rid(uniform_set_rid)
	
	rd.free_rid(current_texture_rid)
	rd.free_rid(previous_texture_rid)
	rd.free_rid(output_texture_rid)
	
	rd.free_rid(pipeline_rid)
	rd.free_rid(shader_rid)

func _process(_delta: float) -> void:
	# TODO: could cache it
	var viewport: Viewport = get_viewport()

	self.material.set_shader_parameter(
		"viewport_size",
		viewport.get_visible_rect().size
	)
	#print("viewport_size", viewport.get_visible_rect().size)

	# Info:
	# https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html
	# Left: more global, right: more precise
	# affine_inverse: go further to the right
	# canvas_pos = get_global_transform() * local_pos
	# local_pos = get_global_transform().affine_inverse() * canvas_pos
	# var screen_coord = get_viewport().get_screen_transform() * get_global_transform_with_canvas() * local_pos
	
	# TODO: could cache it
	var camera = get_viewport().get_camera_2d()
	material.set_shader_parameter(
		"camera_position",
		camera.get_screen_center_position()
	)
	material.set_shader_parameter(
		"camera_zoom",
		camera.zoom
	)
	
	var screen_to_world: Transform2D = camera.get_canvas_transform().affine_inverse()
	material.set_shader_parameter("screen_to_world_origin", screen_to_world.origin)
	material.set_shader_parameter("screen_to_world_x", screen_to_world.x)
	material.set_shader_parameter("screen_to_world_y", screen_to_world.y)
	
	_refresh_objects_positions()
	
	#render()
	render2()
	

# not using this
func render():
	var compute_list: int = rd.compute_list_begin()
	
	_clear_uniform_set()
	_create_uniform_set()
	
	# should not be created each dispatch
	#pipeline_rid = rd.compute_pipeline_create(shader_rid)
	
	var groups_x := int(ceil(float(output_width) / 8.0))
	var groups_y := int(ceil(float(output_height) / 8.0))

	var parameters := make_parameters_bytes()

	rd.compute_list_bind_compute_pipeline(
		compute_list,
		pipeline_rid
	)
	
	# Info: can use more than 1
	# set = 0 etc in the shader to use the proper one
	rd.compute_list_bind_uniform_set(
		compute_list,
		uniform_set_rid,
		0
	)
	
	# FIXME: just use a buffer?
	# small per-dispatch parameters
	rd.compute_list_set_push_constant(
		compute_list,
		parameters,
		parameters.size()
	)

	rd.compute_list_dispatch(
		compute_list,
		groups_x,
		groups_y,
		1
	)
	
	# This is if we are using the main rendering device
	rd.compute_list_add_barrier(compute_list)
	
	rd.compute_list_end()
	
	# FIXME: not necessary here?
	buffer_state = (buffer_state + 1) % 2
	
	# Info: can't submit/sync if we are using the main rendering device
	#rd.submit()
	#rd.sync()
	
	update_texture_for_display()
	

func _clear_uniform_set():
	if node_2ds_buffer_rid:
		rd.free_rid(node_2ds_buffer_rid)

# Info: this is the more "optimized" version
# TODO: simplify the ship update to have the choice between updating
# before or after
func render2():
	#if !is_enabled:
		#return
	
	# Can't dispatch and read texture before previous one is done writing
	
	# can update here
	# can't update while the compute_list is active
	#var i = 0
	#for entity in ships:
		#var pos: Vector2 = entity.global_position
		#_update_object_buffer(
			#i,
			#pos,
		#)
		#i += 1
	
	# Info: Can't do this without recreating the uniform_sets
	#rd.free_rid(node_2ds_buffer_rid)
	#_create_objects_buffer()
	
	var compute_list: int = rd.compute_list_begin()
	
	dispatch(compute_list)
	# Can only call submit and sync if local device
	#rd.submit()
	# Can't sync on main thread
	#rd.sync()
	
	buffer_state = (buffer_state + 1) % 2
	
	# Info: necessary to use the main rendering device
	rd.compute_list_end()
	
	var i = 0
	for entity in entities:
		var pos: Vector2 = entity.global_position
		_update_object_buffer(
			i,
			pos,
		)
		i += 1
	
	# Info: can't submit if using main rendering device
	#rd.submit()
	
	# if using local device
	update_texture_for_display()

func dispatch(compute_list: int) -> void:
	var groups_x := int(ceil(float(output_width) / 8.0))
	var groups_y := int(ceil(float(output_height) / 8.0))

	var parameters := make_parameters_bytes()
	
	#print("rect %s" % [
		#map_rect,
	#])
	
	# Could have only one if more than one render
	#var compute_list: int = rd.compute_list_begin()

	rd.compute_list_bind_compute_pipeline(
		compute_list,
		pipeline_rid
	)
	
	rd.compute_list_bind_uniform_set(
		compute_list,
		uniform_sets[buffer_state],
		0
	)

	# FIXME: just use a buffer?
	# small per-dispatch parameters
	rd.compute_list_set_push_constant(
		compute_list,
		parameters,
		parameters.size()
	)

	rd.compute_list_dispatch(
		compute_list,
		groups_x,
		groups_y,
		1
	)
	
	rd.compute_list_add_barrier(compute_list)

	#rendering_device.compute_list_end()


func update_texture_for_display():
	var data: PackedByteArray = rd.texture_get_data(
		current_texture_rid,
		0
	)
	# Info: in rgb8
	# values are from 0 to 255
	#for i in range(0, data.size(), 4):
		#var r: int = data[i]
		#var g: int = data[i + 1]
		#var b: int = data[i + 2]
		#var a: int = data[i + 3]
		#if r > 0 and g > 0:
			#print("color %s %s %s %s" % [
				#r,g,b,a
			#])
		
	var image: Image = Image.create_from_data(
		output_width,
		output_height,
		false,
		Image.FORMAT_RGBA8,
		#Image.FORMAT_RF,
		data
	)
	var texture = ImageTexture.create_from_image(image)
	#texture_rect_current.texture = texture
	texture_rect.texture = texture
	#
	#var data2 := rd.texture_get_data(
		#previous_texture,
		#0
	#)
	#var image2 := Image.create_from_data(
		#output_width,
		#output_height,
		#false,
		##Image.FORMAT_RGBA8,
		#Image.FORMAT_RF,
		#data2
	#)
	#var texture2 = ImageTexture.create_from_image(image2)
	##texture_rect_previous.texture = texture2

func is_position_explored(world_position: Vector2):
	# TODO: we could implement this
	# We're using the physics for now
	pass

# Info: there is a fast bit method but: too complicated
# var lower := int(pow(2.0, floor(log(value) / log(2.0))))
func next_power_of_two(value: float) -> int:
	if value <= 2.0:
		return 2
	# compute log2
	var log2 = log(value) / log(2.0)
	# take upper bound
	var exponent = ceil(log2)
	# return nearest upper power of two
	return int(pow(2.0, exponent))

func get_scene_aabb(root: Node2D) -> Rect2:
	var result: Rect2
	
	print("root viewport_rect %s" % [
		root.get_viewport_rect(),
	])

	for node in root.find_children("*", "CanvasItem", true, false):
		var item : CanvasItem = node as CanvasItem
		if !item.is_visible_in_tree():
			continue

		var rect: Rect2 = item.get_viewport_rect()
		var to_root: Transform2D = root.get_global_transform().affine_inverse() * item.get_global_transform()
		var bounds: Rect2 = to_root * rect
		
		if result == null:
			result = bounds
		else:
			result = result.merge(bounds)

	return result

func _on_event_bus_send_visible_entity_added(
	entity: Entity,
):
	print("_on_event_bus_send_visible_entity_added %s %s" % [
		entity.get_path(),
		entity.ecs_id,
	])
	if entities.has(entity):
		return
	
	# FIXME: this is not fast
	if only_use_local_player_faction_id:
		var r_faction = entity.get_relationship(
			Rels.belongs_to_faction
		)
		if r_faction.target == null:
			return
		var c_faction: C_Faction = r_faction.target.get_component(
			C_Faction
		)
		if c_faction.faction_id != local_player_faction_id:
			return
	
	entities.push_back(entity)
	
	_refresh_shader_objects()

func _on_event_bus_send_visible_entity_removed(
	ship: Entity,
):
	print("_on_event_bus_send_visible_entity_removed")
	# FIXME: not fast
	if entities.has(ship):
		return
	entities.erase(ship)
	
	_refresh_shader_objects()

func _on_event_bus_send_local_player_faction_id_changed(
	local_player_faction_id_: int,
):
	local_player_faction_id = local_player_faction_id_

func _refresh_shader_objects():
	objects = PackedVector4Array()
	for i in MAX_OBJECT_COUNT_SHADER:
		objects.append(Vector4.ZERO)
	
	#objects[0] = Vector4(
		#target_mask.global_position.x,
		#target_mask.global_position.y,
		#0,
		#0,
	#)
	
	_refresh_objects_positions()

func _refresh_objects_positions():
	if entities.size() > MAX_OBJECT_COUNT_SHADER:
		push_error("more ships than MAX_OBJECT_COUNT_SHADER %s %s" % [
			entities.size(),
			MAX_OBJECT_COUNT_SHADER,
		])
	
	var count: int = min(
		entities.size(),
		MAX_OBJECT_COUNT_SHADER,
	)
	for i in count:
		var entity: Entity = entities[i]
		var radius: float = 250
		var c_circular: C_CircularVision = entity.get_component(
			C_CircularVision
		)
		if c_circular:
			radius = c_circular.radius
		objects[i] = Vector4(
			entity.global_position.x,
			entity.global_position.y,
			0,
			radius,
		)
	
	material.set_shader_parameter("objects", objects)
	material.set_shader_parameter("object_count", count)

#region "Compute shader initialize"

# not using this
func _create_uniform_set() -> void:
	#print("_create_uniform_set")
	
	var uniforms: Array[RDUniform] = []
	
	_create_objects_buffer()
	
	var states := [
		[previous_texture_rid, current_texture_rid,],
		[current_texture_rid, previous_texture_rid,],
	]
	
	uniforms.append(make_image_uniform(0, states[buffer_state][0]))
	uniforms.append(make_image_uniform(1, states[buffer_state][1]))
	uniforms.append(make_image_uniform(2, output_texture_rid))
	
	var node_2ds_uniform := RDUniform.new()
	node_2ds_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	node_2ds_uniform.binding = 3
	node_2ds_uniform.add_id(node_2ds_buffer_rid)
	uniforms.append(node_2ds_uniform)

	uniform_set_rid = rd.uniform_set_create(
		uniforms,
		shader_rid,
		0
	)

func _create_uniform_sets() -> void:
	print("_create_uniform_sets")
	uniform_sets.clear()

	var states := [
		[previous_texture_rid, current_texture_rid,],
		[current_texture_rid, previous_texture_rid,],
	]

	for state in states:
		var uniforms: Array[RDUniform] = []

		uniforms.append(make_image_uniform(0, state[0]))
		uniforms.append(make_image_uniform(1, state[1]))
		uniforms.append(make_image_uniform(2, output_texture_rid))
		
		var node_2ds_uniform := RDUniform.new()
		node_2ds_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		node_2ds_uniform.binding = 3
		node_2ds_uniform.add_id(node_2ds_buffer_rid)
		uniforms.append(node_2ds_uniform)
		
		uniform_sets.append(
			rd.uniform_set_create(uniforms, shader_rid, 0)
		)
		

func create_textures() -> void:
	_create_output_texture()
	
	var texture_format := RDTextureFormat.new()

	texture_format.width = output_width
	texture_format.height = output_height
	texture_format.depth = 1
	texture_format.array_layers = 1
	texture_format.mipmaps = 1
	texture_format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	#wave_format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	#texture_format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	texture_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM

	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
	)

	var texture_view := RDTextureView.new()

	var initial_data := create_float_texture_data()

	previous_texture_rid = rd.texture_create(
		texture_format,
		texture_view,
		[initial_data]
	)

	current_texture_rid = rd.texture_create(
		texture_format,
		texture_view,
		[initial_data]
	)

	if not previous_texture_rid.is_valid():
		push_error("Could not create previous texture")

	if not current_texture_rid.is_valid():
		push_error("Could not create current texture")

func _create_output_texture() -> void:
	var format := RDTextureFormat.new()
	format.width = output_width
	format.height = output_height
	#format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
	)

	var view := RDTextureView.new()

	#output_texture_rid = rd.texture_create(format, view)
	var initial_data := create_float_texture_data()
	output_texture_rid = rd.texture_create(
		format,
		view,
		[initial_data]
	)
	
	display_texture = Texture2DRD.new()
	display_texture.texture_rd_rid = output_texture_rid

func create_float_texture_data() -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(output_height * output_width * 4)
	#bytes.resize(output_height * output_width)

	for y in range(output_height):
		for x in range(output_width):
			var offset: int = (y * output_height + x) * 4
			# this is kinda shit
			#bytes.encode_float(offset, 1.0)
			# s8, u8; not sure which one I should use
			#var offset: int = (y * output_height + x)
			#var value: int = 1
			#if y <= 64:
				#value = 1
			#bytes.encode_u8(offset, value)
			# rgba
			# don't forget the a, set value to 1
			bytes[offset]     = roundi(clampf(0.0, 0.0, 1.0) * 255.0)
			bytes[offset + 1] = roundi(clampf(0.0, 0.0, 1.0) * 255.0)
			bytes[offset + 2] = roundi(clampf(0.0, 0.0, 1.0) * 255.0)
			bytes[offset + 3] = roundi(clampf(1.0, 0.0, 1.0) * 255.0)

	return bytes

# Call it with output_height * output_width
func create_float_texture_data_2(
	size_: int,
	initial_value: float
) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(size_ * 4)
	for i in range(size_):
		bytes.encode_float(i * 4, initial_value)
	return bytes

func make_parameters_bytes() -> PackedByteArray:
	var bytes := PackedByteArray()

	bytes.resize(28)

	bytes.encode_s32(0, output_width)
	bytes.encode_s32(4, output_height)
	bytes.encode_s32(8, int(map_rect.size.x))
	bytes.encode_s32(12, int(map_rect.size.y))
	bytes.encode_s32(16, int(map_rect.position.x))
	bytes.encode_s32(20, int(map_rect.position.y))
	#print("setting size %s" % [
		#ships.size(),
	#])
	bytes.encode_s32(24, entities.size())

	return bytes

func _create_objects_buffer():
	#print("")
	#var node_2ds_data := PackedFloat32Array()
	var node_2ds_data := PackedByteArray()
	
	# TODO: could be more optimized?
	# Don't really need it since it's done once for the 2nd method
	node_2ds_data.resize(0)
	
	#print("creating object buffer %s" % [
		#MAX_OBJECT_COUNT_SHADER,
	#])
	
	var i = 0
	#for node in node_2ds:
	for j in MAX_OBJECT_COUNT_SHADER:
		var offset: int = node_2ds_data.size()
		node_2ds_data.resize(offset + OBJECT_BYTE_SIZE)
		
		#var position_: Vector2 = node.position
		var position_: Vector2 = Vector2.ZERO
		var radius: float = 250
		if entities.size() > j:
			#print("using ship positions %s" % [
				#ships[j].global_position,
			#])
			position_ =  entities[j].global_position
			var c_circular: C_CircularVision = entities[i].get_component(
				C_CircularVision
			)
			if c_circular:
				radius = c_circular.radius
		elif entities.size() == 0:
			position_ = Vector2.ZERO
		
		# Info: this details memory layout info for glsl / GPUs
		# https://gist.github.com/teoxoy/936891c16c2a3d1c3c5e7204ac6cd76c
		
		# id
		node_2ds_data.encode_s32(offset, i)
		offset += 4
		# type
		#node_2ds_data.encode_u32(offset, node.type)
		node_2ds_data.encode_u32(offset, 0)
		
		# data padding => radius + padding
		offset += 4
		node_2ds_data.encode_float(offset, radius)
		offset += 4
		node_2ds_data.encode_float(offset, 0.0)
		
		# IMPORTANT: use 16 offset for a vec4
		# Can't start at an arbitrary position
		# std430: vec4 has to start at % 16
		
		var alt_x = randf_range(
			map_rect.position.x,
			map_rect.position.x + map_rect.size.x,
		)
		var alt_y = randf_range(
			map_rect.position.y,
			map_rect.position.y + map_rect.size.y,
		)
		
		offset += 4
		#node_2ds_data.encode_float(offset, alt_x)
		node_2ds_data.encode_float(offset, position_.x)
		offset += 4
		#node_2ds_data.encode_float(offset, alt_y)
		node_2ds_data.encode_float(offset, position_.y)
		offset += 4
		#node_2ds_data.encode_float(offset, 0.0)
		node_2ds_data.encode_float(offset, alt_x)
		#node_2ds_data.encode_float(offset, position_.x)
		offset += 4
		#node_2ds_data.encode_float(offset, 0.0)
		node_2ds_data.encode_float(offset, alt_y)
		#node_2ds_data.encode_float(offset, position_.y)
		
		i += 1

	#var node_2ds_bytes := node_2ds_data.to_byte_array()

	node_2ds_buffer_rid = rd.storage_buffer_create(
		node_2ds_data.size(),
		node_2ds_data
	)

func _update_object_buffer(
	index: int,
	position_: Vector2
):
	#print("_update_object_buffer %s %s" % [
		#index,
		#position_
	#])
	var array: PackedByteArray = PackedByteArray()
	# 16 is the first region, then there is another 16 region for the pos
	var byte_offset_start:  int = index * OBJECT_BYTE_SIZE + 16
	var byte_offset: int = 0
	array.resize(8)
	array.encode_float(0, position_.x)
	byte_offset += 4
	array.encode_float(byte_offset, position_.y)
	var err: Error = rd.buffer_update(
		node_2ds_buffer_rid,
		byte_offset_start,
		array.size(),
		array
	)
	if err:
		push_error(err)
	

#region "utils"

func make_image_uniform(
	binding: int,
	texture_rid: RID
) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = binding
	uniform.add_id(texture_rid)

	return uniform

#endregion

#endregion
