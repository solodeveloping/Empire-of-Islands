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

@onready var event_bus: EventBus = %EventBus

@onready var audio_player: AudioPlayer = $AudioPlayer

@onready var world: World = $World

@onready var city_center_1: MainSquare_ECS = $Buildings/CityCenter1
@onready var dock_1: Dock_ECS = $Buildings/Dock1

@onready var range_indicator: CSGCombiner3D = $RangeIndicator

@onready var camera_3d: Camera3D = $Camera3D

@onready var gui: GUI = $GUI

# TODO : detect which one
@onready var island_1: IslandGECS1 = $Island1

@onready var buildings: Node3D = $Buildings

@onready var sail_ship_1: Ship3D_ECS = $SailShip1

@onready var right_click_target: Node3D = $RightClickTarget

# TODO : move this elsewhere
# plus checks, got exits etc
@onready var exits: Node3D = $Exits

@onready var o_population_observer: O_PopulationObserver = $World/Systems/gameplay/O_PopulationObserver

var current_building: Entity
var current_building_id: Buildings.Ids
var current_building_angle: float = 0
var building_rotation_speed: float = 100

var current_dock_buoy_id: int = 0

var city: Entity

var rtsCamera: RTSCamera

# TODO : it's shit for now, worker does not work
# Need population vs needed
# FIXME: can't use population because of call to the_factory
var populations: Array[int] = [0, 0, 0, 0]:
	set(value):
		populations = value
		notify_population_updated()
		
var workers: Array[int] = [0, 0, 0, 0]:
	set(value):
		populations = value
		notify_workers_updated()

func population_increase(population_type: Populations.Types, amount: int):
	populations[population_type] += amount
	notify_population_updated()
	
func population_decrease(population_type: Populations.Types, amount: int):
	populations[population_type] -= amount
	notify_population_updated()
	
func notify_population_updated():
	event_bus.population_updated.emit(populations)
	#var arr = populations.duplicate()
	##Helper.sub_each(arr, the_factory.workers)
	#event_bus.available_workers_updated.emit(
		#arr
	#)

func workers_increase(population_type: Populations.Types, amount: int):
	print("workers_increase")
	workers[population_type] += amount
	notify_workers_updated()

func workers_decrease(population_type: Populations.Types, amount: int):
	workers[population_type] -= amount
	notify_workers_updated()

func notify_workers_updated():
	event_bus.available_workers_updated.emit(
		workers
	)
	
func _on_population_observer_new_pop_unit_joined(pop_type: int):
	print("_on_population_observer_new_pop_unit_joined")
	population_increase(pop_type, 1)

var production_building_ids: Array[int] = [
	Buildings.Ids.Fishery,
	Buildings.Ids.Lumberjack,
	Buildings.Ids.HunterTent,
]

func _ready() -> void:
	ECS.world = world
	#city = City_ECS.new()
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
	
	#dock_1.get_parent().remove_child(dock_1)
	#ECS.world.add_entity(dock_1)
	#dock_1.add_relationship(Rels.create_belongs_to(city))
	
	dock_1.buoy.add_relationship(
		Rels.create_belongs_to(current_building)
	)
	var c_dock_buoy: C_DockBuoy = C_DockBuoy.new(0)
	#var c_dock_buoy: C_DockBuoy = dock_1.buoy.get_component(C_DockBuoy)
	#c_dock_buoy.id = 0
	dock_1.buoy.add_component(c_dock_buoy)
	ECS.world.add_entity(dock_1.buoy)
	
	#city_center_1.get_parent().remove_child(city_center_1)
	#ECS.world.add_entity(city_center_1)
	#city_center_1.add_relationship(Rels.create_belongs_to(city))
	
	island_1.add_component(C_Island.new("First island"))
	ECS.world.add_entity(island_1)
	island_1.add_to_ecs_world()
	
	event_bus.send_city_name_changed.emit("My First City")
	
	ECS.world.add_entity(sail_ship_1)
	
	for exit in exits.get_children():
		if exit is Entity:
			ECS.world.add_entity(exit)
		else:
			push_error("exit is not an Entity")
			
	o_population_observer.new_pop_unit_joined.connect(
		_on_population_observer_new_pop_unit_joined
	)
	
	audio_player.start_in_game_music()
	
	TimeUtils.call_at_interval(self, 0.1, identify_node_below_mouse)
	
	await get_tree().create_timer(0.5).timeout
	print("timeout done")
	call_deferred("finalize_existing_buildings")

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
				#print("result ", raycast_result)
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
							Buildings.Ids.Tent:
								pass
								# TODO: duplicated with Observer?
								# TODO : make it an option
								#var c_housing: C_HousingCapacity = current_building.get_component(C_HousingCapacity)
								#population_increase(
									#c_housing.pop_type, c_housing.current
								#)
								#ECS.world.emit_event(
									#&"housing_building_added", 
									#current_building,
									##{"some_data": 10}
									#{}
								#)
									
							Buildings.Ids.Lumberjack,\
							Buildings.Ids.Fishery,\
							Buildings.Ids.HunterTent:
								ECS.world.emit_event(
									&"production_building_added", 
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
	for building in buildings.get_children():
		if building.has_method("finalize_construction"):
			building.finalize_construction()
		else:
			printerr("building %s does not have finalize_construction" % [
				building.name
			])
		
		if building is Entity:
			
			ECS.world.add_entity(building)
			building.add_relationship(Rels.create_belongs_to(city))
			
			var c_building: C_Building = building.get_component(C_Building)
			if c_building:
				if c_building.building_type in production_building_ids:
					print("adding workers")
					# TODO : better system
					var c_req: C_WorkerRequirement = building.get_component(C_WorkerRequirement)
					if c_req:
						for req in c_req.requirements:
							workers_increase(req.worker_type, req.worker_count)
					else:
						push_error("no worker requirements")
					
					ECS.world.emit_event(
						&"production_building_added", 
						building,
						{}
					)
			else:
				push_error("building %s does not have C_Building" % [
					building.name,
				])

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
		print("result", raycast_result)

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

	if !raycast_result.is_empty():
		print("result", raycast_result)
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
	print("identify_node_below_mouse")
	var camera = get_viewport().get_camera_3d()
	var space = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * ray_length
	
	var params = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.collision_mask = things_with_names_collision_mask_for_ray

	var raycast_result = space.intersect_ray(params)

	if !raycast_result.is_empty():
			#print("pos ", raycast_result.position)
			print("result ", raycast_result)
			#print("parent", raycast_result.get_parent())
			
			var collider: Node3D = raycast_result.collider
			print("parent", collider.get_parent())
			print("parent2", collider.get_parent().get_parent())
			var island_parent: IslandGECS1 = SceneUtils.find_first_parent_of_type(
				collider, 
				IslandGECS1
			)
			if island_parent:
				print("found island parent %s" % [
					island_parent.name,
				])
				var c_island: C_Island = island_parent.get_component(C_Island)
				if c_island:
					event_bus.send_city_name_changed.emit(
						c_island.island_name,
					)
				else:
					push_error("island does not have C_Island")
			else:
				var collider_parent = collider.get_parent()
				if collider_parent is OceanNode1:
					print("found ocean")
					event_bus.send_city_name_changed.emit(
						collider_parent.ocean_name
					)

func add_current_building_to_tree():
	#add_child(current_building)
	buildings.add_child(current_building)

#region "MultiMesh instance areas (trees etc)"

func _on_multimesh_instance_area_entered_main_area(area: MultiMeshInstanceArea):
	pass

func _on_multimesh_instance_area_exited_main_area(area: MultiMeshInstanceArea):
	pass

#endregion
