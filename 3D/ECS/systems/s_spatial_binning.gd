extends System
class_name SpatialBinningSystem

@export
var grid_size := Vector3i(16, 64, 16)

@export
var debug_enabled: bool = false

var bins: Dictionary[Vector3i, Array] = {}

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_IsInSpatialBin,
				C_Movement,
			])\
			#.enabled()\
			.iterate([
				C_IsInSpatialBin,
				C_Movement,
			])\
			,
			assign_entities
		],
		# FIXME: this could be done in an event system?
		# Or is it fine like this?
		[
			ECS.world.query.with_all([
				C_Transform,
			])\
			.with_none([
				C_IsInSpatialBin
			])\
			#.enabled()\
			#.iterate([
				#C_Transform,
			#])\
			,
			assign_initialize_entities
		],
	]

var time: float = 0
var draw_refresh: float = 1

var update_bins_time: float = 0
var update_bins_time_limit: float = 0.5

func _ready() -> void:
	time = 0
	update_bins_time = 0

func _process(delta: float) -> void:
	if debug_enabled == false:
		return
	
	time -= delta
	if time > 0:
		return
	time = draw_refresh
	for key in bins.keys():
		var bin: Array[Entity] = bins.get(key)
		#if bin.is_empty():
			#printerr("bin %s is empty" % [
				#key,
			#])
		var pos: Vector3 = Vector3(grid_size) * Vector3(key)
		DebugDraw3D.draw_box(
			pos,
			Quaternion.IDENTITY,
			Vector3(grid_size),
			Color.BLUE_VIOLET,
			false,
			draw_refresh * 1,
		)
		var text_offset: Vector3 = Vector3(
			grid_size.x / 2,
			grid_size.y / 2,
			grid_size.z / 2,
		)
		DebugDraw3D.draw_text(
			#pos,
			#pos + Vector3(grid_size),
			pos + text_offset,
			"%s" % [
				bin.size(),	
			],
			200,
			Color.BLUE_VIOLET,
			draw_refresh * 1,
		)

func assign_entities(
	entities: Array[Entity],
	components: Array,
	delta: float
):
	# TODO: log them by frame at some point
	#print("")
	#print("assign_entities %s %s %s" % [
		#Engine.get_physics_frames(),
		#entities.size(),
		#_components.size(),
	#])
	#var i = 0
	#for arr in _components:
		#print("arr %s %s" % [
			#i,
			#arr.size(),
		#])
		#i += 1
	
	update_bins_time -= delta
	if update_bins_time > 0:
		return
	update_bins_time = update_bins_time_limit
	
	var C_IsInSpatialBin_Index: int = 0
	
	# TODO: system to detect if it moved or not
	# But not slower than just computing it
	for i in entities.size():
		#print("assign_entities %s" % [
			#entity.name,
		#])
		var entity: Entity = entities[i]
		var bin_coord: Vector3i
		if "global_position" in entity:
			bin_coord = get_coord_from_position(
				entity.global_position,
			)
		else:
			# TODO: not sure we are syncing those
			# trees are other MultiMesh entities
			var c_transform: C_Transform = entity.get_component(
				C_Transform
			)
			bin_coord = get_coord_from_transform(
				c_transform.transform,
			)
		
		var spatial_bin: C_IsInSpatialBin = components[C_IsInSpatialBin_Index][i]
		
		if spatial_bin.bin_coord == bin_coord:
			#print("is in same bin")
			continue
			
		# TODO : fix shark and boat
		# they are in negative bins
		
		#print("is in different bin %s %s" % [
			#entity.global_position,
			#bin_coord,
		#])
		
		var current_bin: Array[Entity] = bins.get(
			spatial_bin.bin_coord,
		)
		var target_bin: Array[Entity]
		if bins.has(bin_coord):
			target_bin = bins.get(
				bin_coord
			)
		else:
			#print("adding bin")
			target_bin = []
			bins.set(
				bin_coord,
				target_bin,
			)
		
		current_bin.erase(entity)
		if current_bin.is_empty():
			# TODO: implement something for this
			# Like with a timer
			# But timers are not safe I think, not sure
			pass
		
		target_bin.push_back(entity)
		
		spatial_bin.bin_coord = bin_coord

func assign_initialize_entities(
	entities: Array[Entity],
	_components: Array,
	_delta: float
):
	# TODO: system to detect if it moved or not
	# But not slower than just computing it
	for entity in entities:
		var bin_coord: Vector3i
		if "global_position" in entity:
			bin_coord = get_coord_from_position(
				entity.global_position,
			)
		else:
			# trees are other MultiMesh entities
			var c_transform: C_Transform = entity.get_component(
				C_Transform
			)
			bin_coord = get_coord_from_transform(
				c_transform.transform,
			)
		var target_bin: Array[Entity]
		if bins.has(bin_coord):
			target_bin = bins.get(
				bin_coord
			)
		else:
			target_bin = []
			bins.set(
				bin_coord,
				target_bin,
			)
		
		target_bin.push_back(entity)
		
		cmd.add_component(
			entity,
			C_IsInSpatialBin.new(
				bin_coord
			)
		)

func get_coord_from_transform(transform_: Transform3D) -> Vector3i:
	var coord = Vector3i(
		floor(transform_.origin.x / grid_size.x),
		floor(transform_.origin.y / grid_size.y),
		floor(transform_.origin.z / grid_size.z),
	)
	return coord

func get_coord_from_position(position_: Vector3) -> Vector3i:
	var coord = Vector3i(
		floor(position_.x / grid_size.x),
		floor(position_.y / grid_size.y),
		floor(position_.z / grid_size.z),
	)
	return coord

func query_entities_around_point(
	position: Vector3,
	distance: float,
	look_in_close_by_bins: bool = false
) -> Array[Entity]:
	var bin_coord: Vector3i = get_coord_from_position(
		position
	)
	if look_in_close_by_bins == false:
		return _get_entities_around_point(
			position,
			distance,
			bin_coord
		)
	
	var coords = Vector3i(
		floor(distance / grid_size.x),
		floor(distance / grid_size.y),
		floor(distance / grid_size.z),
	)
	# If the distance is below grid size in all directions
	if coords == Vector3i.ZERO:
		return _get_entities_around_point(
			position,
			distance,
			bin_coord
		)
	
	var closest_bin_result = _get_entities_around_point(
		position,
		distance,
		bin_coord
	)
	
	# TODO : debug this
	
	for y in range(-coords.y, coords.y):
		for x in range(-coords.x, coords.x):
			for z in range(-coords.z, coords.z):
				var offset: Vector3i = Vector3i(
					x,
					y,
					z,
				)
				if offset == Vector3i.ZERO:
					continue
				
				var new_bin_coord: Vector3i = bin_coord + offset
				var bin_result = _get_entities_around_point(
					position,
					distance,
					new_bin_coord,
				)
				closest_bin_result.append_array(
					bin_result,
				)
	
	return closest_bin_result

func _get_entities_around_point(
	position: Vector3,
	distance: float,
	bin_coord: Vector3i,
) -> Array[Entity]:
	var result: Array[Entity] = []
	var bin: Array[Entity] = bins.get(
		bin_coord
	)
	if bin == null:
		return result
	
	for entity in bin:
		if position.distance_to(entity.global_position) <= distance:
			result.push_back(entity)
	
	return result
