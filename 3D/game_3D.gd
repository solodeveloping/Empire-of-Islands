extends Node3D

const SAMPLE_CAMERA = preload("uid://de8asbx0dukri")
const SAMPLE_PLAYER = preload("uid://wilkunqqgl4")
const RTSCAM = preload("uid://cf7brgwaxlmud")

# Sailors
const HOUSING_TENT = preload("uid://c0crs07wbol7p")
const LUMBERJACK_1 = preload("uid://c0f7np4ixkd1x")
const FISHERMAN_TENT_1 = preload("uid://dgflhswvnmgx3")
const HUNTER_TENT_1 = preload("uid://cdefoo0ghsb74")
const DOCK_1 = preload("uid://bwcqu7lunanpr")
const CITY_CENTER_1 = preload("uid://bmde582hv8jwm")


const RANGE_CYLINDER_INDICATOR = preload("uid://dthmx62xw7kk4")

@export_flags_3d_physics
var buildings_collision_mask_for_ray: int

@export_flags_3d_physics
var left_click_collision_mask_for_ray: int

@export_flags_3d_physics
var right_click_collision_mask_for_ray: int

@export_flags_3d_physics
var things_with_names_collision_mask_for_ray: int

@export
var default_map: MapDefinition

@onready var event_bus: EventBus = %EventBus

@onready var audio_player: AudioPlayer = $AudioPlayer

@onready var world: World = $World

@onready var dynamic_buildings: Node3D = $DynamicBuildings

@onready var range_indicator: CSGCombiner3D = $RangeIndicator

@onready var camera_3d: Camera3D = $Camera3D

@onready var gui: GUI = $GUI

@onready var sail_ship_1: Ship3D_ECS = $SailShip1

@onready var right_click_target: Node3D = $RightClickTarget

# TODO : move this elsewhere
# plus checks, got exits etc
@onready var exits: Node3D = $Exits

@onready var o_population_observer: O_PopulationObserver = $World/Systems/gameplay/O_PopulationObserver

@onready var gm_simple_storage: GMSimpleStorage = $GMSimpleStorage

var current_building: Entity
var current_building_id: Buildings.Ids
var current_building_angle: float = 0
var building_rotation_speed: float = 100

# FIXME: should it just be current_building?
var selected_building: Entity

var current_dock_buoy_id: int = 0

var map: Node3D
var city: Entity

var rtsCamera: RTSCamera

# TODO: we'll have to make this per city / island

# TODO : it's shit for now, worker does not work
# Need population vs needed
# FIXME: can't use population because of call to the_factory
var populations: Array[int] = [0, 0, 0, 0]:
	set(value):
		populations = value
		notify_population_updated()

var housing_capacities: Array[int] = [0, 0, 0, 0]:
	set(value):
		housing_capacities = value
		notify_housing_capacity_updated()

var workers: Array[int] = [0, 0, 0, 0]:
	set(value):
		workers = value
		notify_workers_updated()

var worker_capacities: Array[int] = [0, 0, 0, 0]:
	set(value):
		worker_capacities = value
		notify_worker_capacities_updated()

func population_increase(population_type: Populations.Types, amount: int):
	populations[population_type] += amount
	notify_population_updated()

func population_decrease(population_type: Populations.Types, amount: int):
	populations[population_type] -= amount
	notify_population_updated()

func notify_population_updated():
	# FIXME: should we duplicate it
	# just put a warning?
	event_bus.population_updated.emit(populations)

func housing_capacity_increase(population_type: Populations.Types, amount: int):
	housing_capacities[population_type] += amount
	notify_housing_capacity_updated()

func housing_capacityn_decrease(population_type: Populations.Types, amount: int):
	housing_capacities[population_type] -= amount
	notify_housing_capacity_updated()

func notify_housing_capacity_updated():
	event_bus.housing_capacity_updated.emit(housing_capacities)

func workers_increase(population_type: Populations.Types, amount: int):
	workers[population_type] += amount
	notify_workers_updated()

func workers_decrease(population_type: Populations.Types, amount: int):
	workers[population_type] -= amount
	notify_workers_updated()

func notify_workers_updated():
	event_bus.available_workers_updated.emit(
		workers
	)

func worker_capacities_increase(population_type: Populations.Types, amount: int):
	worker_capacities[population_type] += amount
	notify_worker_capacities_updated()

func worker_capacities_decrease(population_type: Populations.Types, amount: int):
	worker_capacities[population_type] -= amount
	notify_worker_capacities_updated()

func notify_worker_capacities_updated():
	event_bus.worker_capacities_updated.emit(
		worker_capacities
	)

func _on_OPopulationObserver_new_pop_unit_joined(pop_type: int) -> void:
	print("_on_OPopulationObserver_new_pop_unit_joined")
	population_increase(pop_type, 1)

func _on_OBuildingAddedObserver_housing_capacity_increased(
	pop_type: int,
	amount: int
) -> void:
	housing_capacity_increase(
		pop_type,
		amount,
	)

func _on_OPopulationObserver_pop_unit_found_work(pop_type: int) -> void:
	workers_increase(pop_type, 1)

func _on_OBuildingAddedObserver_workers_capacity_increased(
	pop_type: int,
	amount: int
) -> void:
	worker_capacities_increase(
		pop_type,
		amount,
	)

var production_building_ids: Array[int] = [
	Buildings.Ids.Fishery,
	Buildings.Ids.Lumberjack,
	Buildings.Ids.HunterTent,
]
var housing_building_ids: Array[int] = [
	Buildings.Ids.Tent,
	Buildings.Ids.House,
	Buildings.Ids.StoneHouse,
]

func _ready() -> void:
	ECS.world = world
	
	map = default_map.map_scene.instantiate()
	add_child(map)
	
	city = Entity.new()
	city.add_component(C_City.new(
		"First city",
	))
	ECS.world.add_entity(city)
	#ECS.world.add_entity(entity, [C_Health.new(100), C_Velocity.new()])
	
	# TODO : a prefab so that we can customize it
	camera_3d.get_parent().remove_child(camera_3d)
	rtsCamera = RTSCAM.instantiate()
	add_child(rtsCamera)
	#instance.projection = Camera3D.PROJECTION_ORTHOGONAL
	
	event_bus.ask_create_building.connect(_on_ask_create_building)
	
	NodeUtils.remove_all_children(range_indicator)
	range_indicator.hide()
	
	event_bus.send_city_name_changed.emit("My First City")
	
	ECS.world.add_entity(sail_ship_1)
	
	for exit in exits.get_children():
		if exit is Entity:
			ECS.world.add_entity(exit)
		else:
			push_error("exit is not an Entity")
	
	audio_player.start_in_game_music()
	
	#TimeUtils.call_at_interval(self, 0.1, identify_node_below_mouse)
	
	# FIXME: don't remember why we do this but was necessary?
	await get_tree().create_timer(0.5).timeout
	print("timeout done")
	# TODO : system to queue stuff
	call_deferred("finalize_existing_buildings")
	call_deferred("call_after_init_is_done")

func call_after_init_is_done():
	# TODO: only do this once ECS and everything has started
	TimeUtils.call_at_interval(self, 0.1, identify_node_below_mouse)
	
	#var buoys = ECS.world.query.with_all([C_DockBuoy]).execute()
	#print("found %s buoys" % [
		#buoys.size(),
	#])
	#for buoy in buoys:
		#print("name %s" % [
			#buoy.name,
		#])

func _process(delta: float) -> void:
	world.process(delta, 'gameplay')

func _physics_process(delta: float) -> void:
	world.process(delta, 'physics')
	
	# TODO: dont intersect with curve
	
	if current_building:
		var camera = get_viewport().get_camera_3d()
		var space = get_world_3d().direct_space_state
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_length = 1000

		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * ray_length
		
		var params = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		
		params.collide_with_bodies = true
		params.collide_with_areas = false
		params.collision_mask = buildings_collision_mask_for_ray

		var raycast_result = space.intersect_ray(params)

		if !raycast_result.is_empty():
				#print("position ", raycast_result.position)
				#print(
					#"result.collider %s %s %s" % [
						#raycast_result.collider.name,
						#raycast_result.collider.get_parent().name,
						#raycast_result.collider.get_parent().get_parent().name,
					#]
				#)
				current_building.position = raycast_result.position
		else:
			#print("no result")
			pass

# TODO: condition to debug / open UI
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	# TODO : stop the timer once built
	if current_building:
		# Info: type autocmpletion only work if 1 assessment at a time
		if event is InputEventMouseButton:
			if event.pressed:
				match event.button_index:
					# cancel the construction
					MOUSE_BUTTON_RIGHT:
						current_building.get_parent().remove_child(current_building)
						current_building = null
						event_bus.send_building_creation_aborted.emit(current_building_id)
						rtsCamera.changing_distance_enabled = true
					# attempt to build
					MOUSE_BUTTON_LEFT:
						if !current_building.is_constructible:
							# TODO: a sound
							audio_player.play_invalid_construction()
							if current_building_id == Buildings.Ids.Warehouse:
								current_building._print_state()
							elif current_building_id == Buildings.Ids.Tent:
								current_building._print_state()
							return
						
						print("")
						print("finalizing building construction")
						
						range_indicator.hide()
						# FIXME : should be done all the time?
						# FIXME : cant convert? when using Node3D
						#var building_as_entity = current_building as Entity
						#var building_as_entity: Entity = current_building
						var buildings = ECS.world.query.with_all(
							[C_Transform])\
							.with_relationship([Rels.create_belongs_to(city)])\
							.execute()
						# TODO : continue this
						match current_building_id:
							Buildings.Ids.Tent:
								var found_a_main_square = false
								for building: Entity in buildings:
									if building.has_component(C_MainSquare):
										if building.has_component(C_Range):
											var trans: C_Transform = building.get_component(C_Transform)
											var range_: C_Range = building.get_component(C_Range)
											var dist = current_building.global_position.distance_to(trans.transform.origin)
											if dist <= range_.value:
												print("found a main square")
												found_a_main_square = true
												current_building.add_relationship(Rels.create_belongs_to(building))
												break
								if !found_a_main_square:
									printerr("did not find a main square in the right range")
							
							Buildings.Ids.Lumberjack:
								pass
							_:
								print("current_building_id:", current_building_id)
						
						#print("removing building")
						# TODO : might want to disable handling of trees etc
						# Info: This will trigger physics events
						#current_building.get_parent().remove_child(current_building)
						print("adding building to ECS world")
						ECS.world.add_entity(current_building, null, false)
						
						# Info: we don't have components before it's added to the world
						match current_building_id:
							Buildings.Ids.Tent,\
							Buildings.Ids.House,\
							Buildings.Ids.StoneHouse:
								ECS.world.emit_event(
									ECSEvents.HOUSING_BUILDING_ADDED, 
									current_building,
									{}
								)
							
							Buildings.Ids.Lumberjack,\
							Buildings.Ids.Fishery,\
							Buildings.Ids.HunterTent:
								ECS.world.emit_event(
									ECSEvents.PRODUCTION_BUILDING_ADDED, 
									current_building,
									#{"my_data": 10}
									{}
								)
							Buildings.Ids.Warehouse:
								var buoy: Entity = current_building.buoy
								buoy.add_relationship(
									Rels.create_belongs_to(current_building)
								)
								ECS.world.add_entity(buoy)
							Buildings.Ids.MainSquare:
								pass
							_:
								print("current_building_id:", current_building_id)
						
						# Info: this allows to be able to click on the building creation button again
						# FIXME: maybe do not disable the button, not sure why this is done
						event_bus.send_building_created.emit(current_building_id)
						
						if current_building.has_method("finalize_construction"):
							current_building.finalize_construction()
						else:
							printerr("building does not have method finalize_construction")
						
						# TODO : maybe can disable completely the thing?
						if current_building.has_signal("multimesh_instance_area_entered_main_area"):
							if current_building.multimesh_instance_area_entered_main_area.is_connected(
								_on_multimesh_instance_area_entered_main_area
							):
								current_building.multimesh_instance_area_entered_main_area.disconnect(
									_on_multimesh_instance_area_entered_main_area
								)
						if current_building.has_signal("multimesh_instance_area_exited_main_area"):
							if current_building.multimesh_instance_area_entered_main_area.is_connected(
								_on_multimesh_instance_area_exited_main_area
							):
								current_building.multimesh_instance_area_entered_main_area.connect(
									_on_multimesh_instance_area_exited_main_area
								)
						
						current_building = null
						
						rtsCamera.changing_distance_enabled = true
						
						audio_player.play_valid_construction()
					# rotate the building
					MOUSE_BUTTON_WHEEL_UP:
						current_building_angle += building_rotation_speed * get_process_delta_time()
					# rotate the building
					MOUSE_BUTTON_WHEEL_DOWN:
						current_building_angle -= building_rotation_speed * get_process_delta_time()
				
				# TODO : use a method instead?
				# apply the rotation to the building
				match event.button_index:
					MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
						current_building.rotation_degrees = Vector3(
							0,
							current_building_angle,
							0
						)
	else:
		if event is InputEventMouseButton:
			if event.pressed:
				match event.button_index:
					# TODO : should ensure it's done in physics frame
					MOUSE_BUTTON_LEFT:
						left_click_at_mouse_pos()
					MOUSE_BUTTON_RIGHT:
						right_click_at_mouse_pos()
			else:
				pass

func finalize_existing_buildings():
	print("finalize_existing_buildings")
	# TODO: maybe we should have a better system
	var buildings = SceneUtils.find_all_child_of_type_depth_first(
		map,
		Entity,
	)
	for building in buildings:
		
		if building is Entity:
			ECS.world.add_entity(building)
			
			var c_building: C_Building = building.get_component(C_Building)
			
			if c_building:
				if building.has_method("finalize_construction"):
					building.finalize_construction()
				else:
					printerr("building %s does not have finalize_construction" % [
						building.name
					])
					push_error("building %s does not have finalize_construction" % [
						building.name
					])
				
				building.add_relationship(Rels.create_belongs_to(city))
			
			#var c_building: C_Building = building.get_component(C_Building)
			#if c_building:
				if c_building.building_type in production_building_ids:
					ECS.world.emit_event(
						ECSEvents.PRODUCTION_BUILDING_ADDED, 
						building,
						{}
					)
				elif c_building.building_type in housing_building_ids:
					ECS.world.emit_event(
						ECSEvents.HOUSING_BUILDING_ADDED, 
						building,
						{}
					)
			#else:
				#push_error("building %s does not have C_Building" % [
					#building.name,
				#])

		if building is Dock_ECS:
			print("adding buoy of dock")
			building.buoy.add_relationship(
				# FIXME: part_of component?
				Rels.create_belongs_to(building)
			)
			var c_dock_buoy: C_DockBuoy = C_DockBuoy.new(0)
			building.buoy.add_component(c_dock_buoy)
			# WARN: it's already added by the statement before
			#ECS.world.add_entity(building.buoy)
		
		if building is IslandGECS1:
			building.add_to_ecs_world()

func _on_ask_create_building(building_id: Buildings.Ids):
	
	# TODO: check resources
	# TODO: queue system
	
	NodeUtils.remove_all_children(range_indicator)
	range_indicator.show()
	
	current_building_id = building_id
	
	rtsCamera.changing_distance_enabled = false
	
	# TODO : mutualize
	match building_id:
		Buildings.Ids.Tent:
			var buildings_ = ECS.world.query.with_relationship([Rels.create_belongs_to(city)])\
				.execute()
			if buildings_.is_empty():
				printerr("did not find a building")
			# TODO : could do other cities in another color
			for building: Entity in buildings_:
				if building.has_component(C_MainSquare):
					if building.has_component(C_Range):
						var range_: C_Range = building.get_component(C_Range)
						var indicator: CSGCylinder3D = RANGE_CYLINDER_INDICATOR.instantiate()
						indicator.radius = range_.value
						range_indicator.add_child(indicator)
						
						indicator.global_position = building.global_position
			
			# This adds the substracted shapes
			for indicator: CSGCylinder3D in range_indicator.get_children():
				var new_indicator: CSGCylinder3D = RANGE_CYLINDER_INDICATOR.instantiate()
				new_indicator.radius = indicator.radius - 0.2
				new_indicator.height = indicator.height #- 0.1
				new_indicator.operation = CSGShape3D.OPERATION_SUBTRACTION
				range_indicator.add_child(new_indicator)
						
				new_indicator.global_position = indicator.global_position# + Vector3(0, 0.0, 0)
						
			current_building = HOUSING_TENT.instantiate()
			add_current_building_to_tree()
			
			# FIXME: should not be done here
			#current_building.add_relationship(Rels.create_belongs_to(city))
		Buildings.Ids.Lumberjack:
			var buildings_ = ECS.world.query.with_relationship([Rels.create_belongs_to(city)])\
				.execute()
			if buildings_.is_empty():
				printerr("did not find a building")
			# TODO : could do other cities in another color
			for building: Entity in buildings_:
				if building.has_component(C_Storage):
					if building.has_component(C_Range):
						var range_: C_Range = building.get_component(C_Range)
						var indicator: CSGCylinder3D = RANGE_CYLINDER_INDICATOR.instantiate()
						indicator.radius = range_.value
						range_indicator.add_child(indicator)
						
						indicator.global_position = building.global_position
			
			# This adds the substracted shapes
			for indicator: CSGCylinder3D in range_indicator.get_children():
				var new_indicator: CSGCylinder3D = RANGE_CYLINDER_INDICATOR.instantiate()
				new_indicator.radius = indicator.radius - 0.2
				new_indicator.height = indicator.height #- 0.1
				new_indicator.operation = CSGShape3D.OPERATION_SUBTRACTION
				range_indicator.add_child(new_indicator)
						
				new_indicator.global_position = indicator.global_position# + Vector3(0, 0.0, 0)
						
			current_building = LUMBERJACK_1.instantiate()
			add_current_building_to_tree()
			
			#current_building.add_relationship(Rels.create_belongs_to(city))
			
		Buildings.Ids.Fishery:
			var buildings_ = ECS.world.query.with_relationship([Rels.create_belongs_to(city)])\
				.execute()
			if buildings_.is_empty():
				printerr("did not find a building")
			# TODO : could do other cities in another color
			for building: Entity in buildings_:
				if building.has_component(C_Storage):
					if building.has_component(C_Range):
						var range_: C_Range = building.get_component(C_Range)
						var indicator: CSGCylinder3D = RANGE_CYLINDER_INDICATOR.instantiate()
						indicator.radius = range_.value
						range_indicator.add_child(indicator)
						
						indicator.global_position = building.global_position
			
			# This adds the substracted shapes
			for indicator: CSGCylinder3D in range_indicator.get_children():
				var new_indicator: CSGCylinder3D = RANGE_CYLINDER_INDICATOR.instantiate()
				new_indicator.radius = indicator.radius - 0.2
				new_indicator.height = indicator.height #- 0.1
				new_indicator.operation = CSGShape3D.OPERATION_SUBTRACTION
				range_indicator.add_child(new_indicator)
						
				new_indicator.global_position = indicator.global_position# + Vector3(0, 0.0, 0)
						
			current_building = FISHERMAN_TENT_1.instantiate()
			add_current_building_to_tree()
			
		Buildings.Ids.HunterTent:
			var buildings_ = ECS.world.query.with_relationship([Rels.create_belongs_to(city)])\
				.execute()
			if buildings_.is_empty():
				printerr("did not find a building")
			# TODO : could do other cities in another color
			for building: Entity in buildings_:
				if building.has_component(C_Storage):
					if building.has_component(C_Range):
						var range_: C_Range = building.get_component(C_Range)
						var indicator: CSGCylinder3D = RANGE_CYLINDER_INDICATOR.instantiate()
						indicator.radius = range_.value
						range_indicator.add_child(indicator)
						
						indicator.global_position = building.global_position
			
			# This adds the substracted shapes
			for indicator: CSGCylinder3D in range_indicator.get_children():
				var new_indicator: CSGCylinder3D = RANGE_CYLINDER_INDICATOR.instantiate()
				new_indicator.radius = indicator.radius - 0.2
				new_indicator.height = indicator.height #- 0.1
				new_indicator.operation = CSGShape3D.OPERATION_SUBTRACTION
				range_indicator.add_child(new_indicator)
						
				new_indicator.global_position = indicator.global_position# + Vector3(0, 0.0, 0)
						
			current_building = HUNTER_TENT_1.instantiate()
			add_current_building_to_tree()
			
		# TODO: should be something else?
		Buildings.Ids.Warehouse:
			current_building = DOCK_1.instantiate()
			add_current_building_to_tree()
			
		Buildings.Ids.MainSquare:
			current_building = CITY_CENTER_1.instantiate()
			add_current_building_to_tree()
			
		_:
			printerr("building not handled", building_id)
			
	if current_building.has_signal("multimesh_instance_area_entered_main_area"):
		print("connecting _on_multimesh_instance_area_entered_main_area")
		current_building.multimesh_instance_area_entered_main_area.connect(
			_on_multimesh_instance_area_entered_main_area
		)
	else:
		printerr("could not find the signal multimesh_instance_area_entered_main_area, signals: ",
			current_building.get_signal_list()
		)
	if current_building.has_signal("multimesh_instance_area_exited_main_area"):
		current_building.multimesh_instance_area_exited_main_area.connect(
			_on_multimesh_instance_area_exited_main_area
		)
	else:
		printerr("could not find the signal multimesh_instance_area_exited_main_area, signals: ",
			current_building.get_signal_list()
		)

func left_click_at_mouse_pos():
	var camera = get_viewport().get_camera_3d()
	var space = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * ray_length
	
	var params = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	params.collide_with_bodies = false
	params.collide_with_areas = true
	params.collision_mask = left_click_collision_mask_for_ray

	var raycast_result = space.intersect_ray(params)

	if !raycast_result.is_empty():
		print("left_click_at_mouse_pos", raycast_result)
		var collider: Node3D = raycast_result.collider
		if !collider:
			print("no collider")
			deselect_selected_building()
			return
		
		var entity_parent: Entity = SceneUtils.find_first_parent_of_type(
			collider,
			Entity,
		)
		if !entity_parent:
			print("did not find an Entity parent")
			deselect_selected_building()
			return
		
		var c_building: C_Building = entity_parent.get_component(C_Building)
		if !c_building:
			print("clicked on something that is not a building %s %s" % [
				collider.get_path(),
				entity_parent.get_path(),
			])
			deselect_selected_building()
			return
		
		print("selecting building")
		
		selected_building = entity_parent
		event_bus.send_building_3D_selected.emit(entity_parent)
	else:
		deselect_selected_building()

func right_click_at_mouse_pos():
	var camera = get_viewport().get_camera_3d()
	var space = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * ray_length
	
	var params = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.collision_mask = right_click_collision_mask_for_ray

	var raycast_result = space.intersect_ray(params)
	
	# TODO: rally points could be set here
	if selected_building:
		deselect_selected_building()

	if !raycast_result.is_empty():
		#print("result", raycast_result)
		var position_: Vector3 = raycast_result["position"]
		var target: C_NavigationDestination = C_NavigationDestination.new(
			position_
		)
		right_click_target.global_position = position_
		#sail_ship_1.add_component(target)
		ECS.world.emit_event(
			&"add_component_to_entity_requested", 
			sail_ship_1,
			{
				"component": target,
			}
		)

func identify_node_below_mouse():
	#print("identify_node_below_mouse")
	var camera = get_viewport().get_camera_3d()
	var space = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * ray_length
	
	var params = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	params.collide_with_bodies = true
	#params.collide_with_areas = false
	params.collide_with_areas = true
	params.collision_mask = things_with_names_collision_mask_for_ray

	var raycast_result = space.intersect_ray(params)

	if !raycast_result.is_empty():
		#print("pos ", raycast_result.position)
		#print("result ", raycast_result)
		
		# FIXME: all these things rely on their identity being associated
		# with a proper object above
		# example: collider with island as parent
		# could be a rock but still result in "Island"
		
		var collider: Node3D = raycast_result.collider
		if collider is MultiMeshInstanceCollider:
			event_bus.send_mouse_over_object_changed.emit(
				"Tree",
				collider,
			)
			return
		#print("parent", collider.get_parent())
		#print("parent2", collider.get_parent().get_parent())
		var island_parent: IslandGECS1 = SceneUtils.find_first_parent_of_type(
			collider, 
			IslandGECS1
		)
		if island_parent:
			#print("found island parent %s" % [
				#island_parent.name,
			#])
			var c_island: C_Island = island_parent.get_component(C_Island)
			if c_island:
				event_bus.send_city_name_changed.emit(
					c_island.island_name,
				)
				event_bus.send_mouse_over_object_changed.emit(
					c_island.island_name,
					collider,
				)
			else:
				push_error(
					"island %s does not have C_Island" % [
						collider.name,
					]
				)
		else:
			var collider_parent = collider.get_parent()
			if collider_parent is OceanNode1:
				#print("found ocean")
				event_bus.send_city_name_changed.emit(
					collider_parent.ocean_name
				)
				event_bus.send_mouse_over_object_changed.emit(
					collider_parent.ocean_name,
					collider,
				)
			
			else:
				#print("something else %s %s" % [
					#collider_parent.name,
					#collider.get_path(),
				#])
				var entity_parent: Entity = SceneUtils.find_first_parent_of_type(
					collider, 
					Entity
				)
				if entity_parent:
					var c_name: C_Name = entity_parent.get_component(C_Name)
					if c_name:
						event_bus.send_mouse_over_object_changed.emit(
							c_name.name_,
							collider,
						)
					else:
						Loggie.msg("found something else").color("orange").bold().warn()
					# TODO: generate using other methods
				else:
					event_bus.send_mouse_over_object_changed.emit(
						collider_parent.name,
						collider,
					)

	else:
		pass

func add_current_building_to_tree():
	#add_child(current_building)
	dynamic_buildings.add_child(current_building)

func deselect_selected_building():
	if !selected_building:
		return
	event_bus.send_building_3D_deselected.emit(selected_building)
	selected_building = null

#region "MultiMesh instance areas (trees etc)"

# FIXME: unused

func _on_multimesh_instance_area_entered_main_area(_area: MultiMeshInstanceArea):
	pass

func _on_multimesh_instance_area_exited_main_area(_area: MultiMeshInstanceArea):
	pass

#endregion

func _on_ProductionSystem_produced_resources(changes: Dictionary[int, int]) -> void:
	#print("_on_ProductionSystem_produced_resources %s" % [
		#changes.size(),
	#])
	for key in changes.keys():
		var quantity = gm_simple_storage.get_storage(key)
		#print("has %s of %s (produced %s)" % [
			#quantity.quantity,
			#key,
			#changes.get(key),
		#])
		event_bus.resource_updated.emit(
			key, quantity.quantity
		)

func _on_EventBus_ask_demolish_current_building() -> void:
	var trees: Array[MultiMeshInstanceArea] = []
	if selected_building.has_method("get_hidden_trees"):
		trees = selected_building.get_hidden_trees()
		
	# TODO : reassign pop_units
	
	ECS.world.remove_entity(selected_building)
	selected_building = null
	
	if trees.is_empty() == false:
		for area in trees:
			var grid: GridMultiMesh = SceneUtils.find_first_parent_of_type(
				area,
				GridMultiMesh
			)
			
			if grid:
				grid.show_instance(area)
				
			area.process_mode = Node.PROCESS_MODE_INHERIT
	
	event_bus.send_current_building_demolished.emit()
