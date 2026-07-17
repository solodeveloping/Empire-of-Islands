extends Node3D

const SAMPLE_CAMERA = preload("uid://de8asbx0dukri")
const SAMPLE_PLAYER = preload("uid://wilkunqqgl4")
const RTSCAM = preload("uid://cf7brgwaxlmud")

const RANGE_CYLINDER_INDICATOR = preload("uid://dthmx62xw7kk4")

const TRADE_EXCHANGE_SUMMARY_FLOATING_UI_3D = preload("uid://ot8co8rxmvb2")

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

@export
var building_list_definition: BuildingListDefinition

# TODO: this should go to ship or storage
@export
var initial_resources: ResourceCollectionDefinition

@export
var use_initial_resources: bool = true

@export
var resource_list_definition: ResourceListDefinition

var resource_list_definition_dict: Dictionary[int, ResourceDefinition] = {}

@export
var initial_factions: Array[FactionDef] = []

# TODO: make sure it can't be higher than initial_factions
@export
var local_player_faction_index: int = 0

@export
var faction_storage_prefab: PackedScene

@export
var default_builtin_resources_space_weight_ref_def: BuiltinResourcesSpaceWeightRefList

@export
var default_basic_trade_system_prices: BuiltinTradePriceList

@export_category("Systems")

@export
var pop_unit_work_system: O_PopulationMovementObserver.POP_UNIT_WORK_SYSTEM = O_PopulationMovementObserver.POP_UNIT_WORK_SYSTEM.TIMER_BASED_HIDE_POP

@export
var pop_unit_home_idling_system: O_PopulationMovementObserver.POP_UNIT_HOME_IDLING_SYSTEM = O_PopulationMovementObserver.POP_UNIT_HOME_IDLING_SYSTEM.HIDE

@export
var jobless_leave_island_time: float = 30.0

@export
var looking_for_housing_leave_island_time: float = 30.0

@export_category("Debug")

@export
var enable_debug_display: bool = false

@export
var debug_display_names: bool = false

# FIXME: maybe a World scene would be better
# Allows to customize more easily
# And access stuff
# Maybe
# But need something that allows to detect if everything needed
# is present
@export
var information_debug_scene: PackedScene

@onready var event_bus: EventBus = %EventBus

@onready var audio_player: AudioPlayer = $AudioPlayer

@onready var world: World = $World

@onready var debug: SystemGroup = $World/Systems/debug

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

@onready var o_population_movement_observer: O_PopulationMovementObserver = $World/Systems/gameplay/O_PopulationMovementObserver

@onready var faction_misc_system: FactionMiscSystem = $World/Systems/gameplay/FactionMiscSystem
@onready var o_faction_misc_observer: O_FactionMiscObserver = $World/Systems/gameplay/O_FactionMiscObserver

@onready var population_misc_system: PopulationMiscSystem = $World/Systems/gameplay/PopulationMiscSystem

@onready var o_ship_trading_observer: O_ShipTradingObserver = $World/Systems/gameplay/O_ShipTradingObserver

@onready var the_storages: Node = $TheStorages

@onready var the_buildings_cost: TheBuildingsCost = $TheBuildingsCost

@onready var ge_map_ship_spawner: GE_MapShipSpawner = $World/GE_MapShipSpawner

@onready var ship_bell_audio_stream_player_3d: AudioStreamPlayer3D = $ShipBellAudioStreamPlayer3D

var faction_entities: Array[Entity] = []
var local_player_faction: Faction_ECS
var local_player_c_faction: C_Faction
var local_player_storage: GMSimpleStorage

var current_building: Entity
var current_building_id: Buildings.Ids
var current_building_angle: float = 0
var current_building_def: BuildingDefinition = null
var building_rotation_speed: float = 100
var current_island_for_building: IslandGECS1

# FIXME: should it just be current_building?
var selected_building: Entity
# FIXME: should it be the same?
var selected_unit: Entity
var selected_ship: Entity

var current_dock_buoy_id: int = 0

var map: Node3D
var city: Entity

var current_island: IslandGECS1

var rtsCamera: RTSCamera

# FIXME: have to update it all the time
# If forget: it breaks

# TODO: we'll have to make this per city / island

# TODO : it's shit for now, worker does not work
# Need population vs needed
# FIXME: can't use population because of call to the_factory
var populations: Array[int] = [0, 0, 0, 0]:
	set(value):
		populations = value
		#notify_population_updated()

var housing_capacities: Array[int] = [0, 0, 0, 0]:
	set(value):
		housing_capacities = value
		#notify_housing_capacity_updated()

var workers: Array[int] = [0, 0, 0, 0]:
	set(value):
		workers = value
		#notify_workers_updated()

var worker_capacities: Array[int] = [0, 0, 0, 0]:
	set(value):
		worker_capacities = value
		#notify_worker_capacities_updated()

func population_increase(population_type: Populations.Types, amount: int):
	populations[population_type] += amount
	#notify_population_updated()

func population_decrease(population_type: Populations.Types, amount: int):
	populations[population_type] -= amount
	#notify_population_updated()

func notify_population_updated():
	# FIXME: should we duplicate it
	# just put a warning?
	event_bus.population_updated.emit(populations)

func housing_capacity_increase(population_type: Populations.Types, amount: int):
	housing_capacities[population_type] += amount
	#notify_housing_capacity_updated()

func housing_capacity_decrease(population_type: Populations.Types, amount: int):
	housing_capacities[population_type] -= amount
	#notify_housing_capacity_updated()

func notify_housing_capacity_updated():
	event_bus.housing_capacity_updated.emit(housing_capacities)

func workers_increase(population_type: Populations.Types, amount: int):
	workers[population_type] += amount
	#notify_workers_updated()

func workers_decrease(population_type: Populations.Types, amount: int):
	workers[population_type] -= amount
	#notify_workers_updated()

func notify_workers_updated():
	event_bus.available_workers_updated.emit(
		workers
	)

func worker_capacities_increase(population_type: Populations.Types, amount: int):
	worker_capacities[population_type] += amount
	#notify_worker_capacities_updated()

func worker_capacities_decrease(population_type: Populations.Types, amount: int):
	worker_capacities[population_type] -= amount
	#notify_worker_capacities_updated()

func notify_worker_capacities_updated():
	event_bus.worker_capacities_updated.emit(
		worker_capacities
	)

func _on_OPopulationObserver_new_pop_unit_joined(
	pop_type: int,
	island: Entity,
) -> void:
	print("_on_OPopulationObserver_new_pop_unit_joined")
	if island == current_island:
		var summary: C_PopulationSummary = island.get_component(
			C_PopulationSummary
		)
		if summary:
			event_bus.population_updated.emit(
				summary.populations
			)
	population_increase(pop_type, 1)

func _on_OBuildingAddedObserver_housing_capacity_increased(
	pop_type: int,
	amount: int,
	island: Entity,
) -> void:
	if island == current_island:
		print("current island housing_capacity_increased")
		var summary: C_PopulationSummary = island.get_component(
			C_PopulationSummary
		)
		if summary:
			event_bus.housing_capacity_updated.emit(
				summary.housing_capacities
			)
			
	housing_capacity_increase(
		pop_type,
		amount,
	)

func _on_OPopulationObserver_pop_unit_found_work(
	pop_type: int,
	island: Entity,
) -> void:
	if island == current_island:
		print("current island workers increased")
		var summary: C_PopulationSummary = island.get_component(
			C_PopulationSummary
		)
		if summary:
			event_bus.available_workers_updated.emit(
				summary.workers
			)
	workers_increase(pop_type, 1)

# FIXME: could pass the C_PopulationSummary
func _on_OPopulationObserver_pop_unit_left_work(
	pop_type: int,
	island: Entity
) -> void:
	if island == current_island:
		print("current island workers decreased")
		var summary: C_PopulationSummary = island.get_component(
			C_PopulationSummary
		)
		if summary:
			event_bus.available_workers_updated.emit(
				summary.workers
			)
	workers_decrease(pop_type, 1)

func _on_OBuildingAddedObserver_workers_capacity_increased(
	pop_type: int,
	amount: int,
	island: Entity,
) -> void:
	if island == current_island:
		print("current island workers_capacity_increased")
		var summary: C_PopulationSummary = island.get_component(
			C_PopulationSummary
		)
		if summary:
			event_bus.worker_capacities_updated.emit(
				summary.worker_capacities
			)
		
	worker_capacities_increase(
		pop_type,
		amount,
	)

func notify_summary_changed():
	if current_island:
		var summary: C_PopulationSummary = current_island.get_component(
			C_PopulationSummary
		)
		if summary:
			event_bus.population_updated.emit(
				summary.populations
			)
			event_bus.housing_capacity_updated.emit(
				summary.housing_capacities
			)
			event_bus.available_workers_updated.emit(
				summary.workers
			)
			event_bus.worker_capacities_updated.emit(
				summary.worker_capacities
			)
		var c_island: C_Island = current_island.get_component(C_Island)
		if c_island:
			event_bus.send_city_name_changed.emit(
				c_island.island_name,
			)
			event_bus.send_mouse_over_object_changed.emit(
				c_island.island_name,
				current_island,
			)
	else:
		event_bus.population_updated.emit(
			[0,0,0,0]
		)
		event_bus.housing_capacity_updated.emit(
			[0,0,0,0]
		)
		event_bus.available_workers_updated.emit(
			[0,0,0,0]
		)
		event_bus.worker_capacities_updated.emit(
			[0,0,0,0]
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
	
	if enable_debug_display:
		var instance = Node.new()
		instance.set_script(MiscDebugSystem)
		if instance is MiscDebugSystem:
			print("Adding MiscDebugSystem")
			instance.information_debug_scene = information_debug_scene
			instance.group = "debug"
			debug.add_child(instance)
			ECS.world.add_system(instance)
	
	# TODO: implement the others
	o_population_movement_observer.pop_unit_work_system = pop_unit_work_system
	match pop_unit_work_system:
		O_PopulationMovementObserver.POP_UNIT_WORK_SYSTEM.TIMER_BASED_HIDE_POP:
			pass
		_:
			printerr("pop_unit_work_system %s is not implemented" % [
				pop_unit_work_system,
			])
	o_population_movement_observer.pop_unit_home_idling_system = pop_unit_home_idling_system
	match pop_unit_home_idling_system:
		O_PopulationMovementObserver.POP_UNIT_HOME_IDLING_SYSTEM.HIDE,\
		O_PopulationMovementObserver.POP_UNIT_HOME_IDLING_SYSTEM.IDLE:
			pass
		_:
			printerr("pop_unit_home_idling_system %s is not implemented" % [
				pop_unit_home_idling_system,
			])
	
	population_misc_system.jobless_leave_island_time = jobless_leave_island_time
	population_misc_system.looking_for_housing_leave_island_time = looking_for_housing_leave_island_time
	
	ge_map_ship_spawner.initial_factions = initial_factions
	var faction_id = 0
	for faction in initial_factions:
		var faction_entity: Faction_ECS = Faction_ECS.new()
		faction_entity.add_component(
			C_Faction.new(faction, faction_id)
		)
		ECS.world.add_entity(faction_entity)
		faction_entities.push_back(faction_entity)
		faction_id += 1
		
		var storage: GMSimpleStorage = faction_storage_prefab.instantiate()
		storage.has_infinite_resources = faction.has_infinite_resources
		the_storages.add_child(storage)
		
		faction_entity.storage_node = storage
	
	ge_map_ship_spawner.set_faction_entities(faction_entities)
	ge_map_ship_spawner.default_basic_trade_system_prices = default_basic_trade_system_prices
	
	faction_misc_system.faction_entities = faction_entities
	o_faction_misc_observer.faction_entities = faction_entities
	
	local_player_faction = faction_entities.get(local_player_faction_index)
	local_player_storage = the_storages.get_child(
		local_player_faction_index
	)
	local_player_c_faction = local_player_faction.get_component(
		C_Faction
	)
	
	if resource_list_definition.list.is_empty():
		printerr("resource_list_definition.list is empty")
	
	var trades: Array[TradeResourceDefinition] = []
	for resource_def in resource_list_definition.list:
		var trade: TradeResourceDefinition = TradeResourceDefinition.new()
		trade.resource_id = resource_def.builtin_resource_id
		trade.item_name = Resources.get_resource_name(
			trade.resource_id
		)
		trade.enabled = false
		trade.res_icon_normal = resource_def.normal_icon
		trade.res_icon_disabled = resource_def.grey_icon
		
		trades.push_back(
			trade
		)
		
		# push inside the dict
		resource_list_definition_dict.set(
			resource_def.builtin_resource_id,
			resource_def,
		)
	
	if trades.is_empty() \
		or trades.size() != resource_list_definition.list.size():
			printerr("trades.size() is bad %s %s" % [
				trades.size(),
				resource_list_definition.list.size(),
			])
	
	var local_c_faction: C_Faction = local_player_faction.get_component(
		C_Faction
	)
	local_c_faction.set_global_trades(trades)
	
	if local_c_faction.global_trades.is_empty() \
		or local_c_faction.global_trades_as_dict.is_empty():
			printerr("local faction global_trades is empty")
	
	event_bus.send_trades_updated.emit(
		local_c_faction.global_trades
	)
	
	o_ship_trading_observer.set_default_builtin_resources_space_weight_ref_def(
		default_builtin_resources_space_weight_ref_def
	)
	ge_map_ship_spawner.set_default_builtin_resources_space_weight_ref_def(
		default_builtin_resources_space_weight_ref_def
	)
	
	# TODO: other global_trades for factions
	# use the ref
	
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
	# TODO: adjust zoom speed based on altitude
	rtsCamera = RTSCAM.instantiate()
	rtsCamera.camera_speed = 50.0
	rtsCamera.camera_zoom_speed = 500.0
	rtsCamera.camera_zoom_max = 500.0
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
	
	the_buildings_cost.set_costs(
		building_list_definition,
	)
	
	initialize_storage()
	
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
	
	# Info: we have to do this after because UI is not init otherwise
	var local_c_faction: C_Faction = local_player_faction.get_component(
		C_Faction
	)
	
	event_bus.send_trades_updated.emit(
		local_c_faction.global_trades
	)
	
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
	world.process(delta, 'debug')

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
				
				var island_parent: IslandGECS1 = SceneUtils.find_first_parent_of_type(
					raycast_result.collider, 
					IslandGECS1
				)
				if island_parent:
					#print("found island")
					current_building.position = raycast_result.position
					current_island_for_building = island_parent
				else:
					#print("no island")
					pass
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
						cancel_build_current_building()
					# attempt to build
					MOUSE_BUTTON_LEFT:
						attempt_build_current_building()
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

func cancel_build_current_building():
	current_building.get_parent().remove_child(current_building)
	current_building = null
	event_bus.send_building_creation_aborted.emit(current_building_id)
	rtsCamera.changing_distance_enabled = true

func attempt_build_current_building():
	if !current_building.is_constructible:
		# TODO: a sound
		audio_player.play_invalid_construction()
		if current_building_id == Buildings.Ids.Warehouse:
			current_building._print_state()
		elif current_building_id == Buildings.Ids.Tent:
			current_building._print_state()
		return
		
	if !current_island_for_building:
		audio_player.play_invalid_construction()
		return
	
	if !has_resources_to_construct_building(current_building_def):
		audio_player.play_invalid_construction()
		return
	
	for cost: CostDefinition in current_building_def.costs:
		var result: GMTakeResult = local_player_storage.take_at_least(
			cost.resource,
			cost.cost,
		)
		if !result.successful:
			push_error("could not take the resources %s %s" % [
				cost.resource,
				cost.cost,
			])
		var storage: GMStorageRef = local_player_storage.get_storage(
			cost.resource
		)
		event_bus.send_resource_updated.emit(
			storage.item_id,
			storage.quantity,
		)
	
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
				{
					"island": current_island_for_building,
				}
			)
		
		Buildings.Ids.Lumberjack,\
		Buildings.Ids.Fishery,\
		Buildings.Ids.HunterTent:
			ECS.world.emit_event(
				ECSEvents.PRODUCTION_BUILDING_ADDED, 
				current_building,
				{
					"island": current_island_for_building,
				}
			)
		Buildings.Ids.Warehouse:
			print("adding buoy to world")
			var buoy: Entity = current_building.buoy
			buoy.add_relationship(
				Rels.create_belongs_to(current_building)
			)
			ECS.world.add_entity(buoy)
		Buildings.Ids.MainSquare:
			pass
		_:
			print("current_building_id:", current_building_id)
	
	ECS.world.emit_event(
		ECSEvents.GENERIC_BUILDING_ADDED, 
		current_building,
		{
			"island": current_island_for_building,
		}
	)
	
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
	current_building_def = null
	current_island_for_building = null
	
	rtsCamera.changing_distance_enabled = true
	
	audio_player.play_valid_construction()

func finalize_existing_buildings():
	print("finalize_existing_buildings")
	map.add_buildings_to_ecs(city)
	# FIXME: this is terrible
	# but we have to
	var entity: Entity = Entity.new()
	entity.add_component(C_Island.new())
	ECS.world.add_entity(entity)
	ECS.world.emit_event(
		ECSEvents.ASSIGN_FACTION_TO_ENTITIES_REQUESTED,
		entity,
		{}
	)
	ECS.world.remove_entity(entity)

func _on_ask_create_building(building_id: Buildings.Ids):
	
	# TODO: queue system?
	if current_building:
		cancel_build_current_building()
	
	if !building_list_definition.builtin_buildings.has(building_id):
		if !building_list_definition.extra_buildings.has(building_id):
			printerr("building %s is not present" % [
				building_id,
			])
			#event_bus.send_building_creation_aborted.emit(building_id)
			#event_bus.send_show_buildings_button_ui.emit()
			return
		current_building_def = building_list_definition.extra_buildings.get(building_id)
	else:
		current_building_def = building_list_definition.builtin_buildings.get(building_id)
	
	if current_building_def.scene == null:
		push_error("scene of building definition is null for %s" % [
			building_id
		])
		#event_bus.send_building_creation_aborted.emit(building_id)
		#event_bus.send_show_buildings_button_ui.emit()
		return
	
	# TODO : make this an option
	if !has_resources_to_construct_building(current_building_def):
		audio_player.play_invalid_construction()
		# FIXME: without this it won't allow us to click back on button
		#event_bus.send_building_creation_aborted.emit(building_id)
		#event_bus.send_show_buildings_button_ui.emit()
		return
	
	current_building = current_building_def.scene.instantiate()
	
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
			
			
			# FIXME: should not be done here
			#current_building.add_relationship(Rels.create_belongs_to(city))
		Buildings.Ids.Lumberjack:
			var buildings_ = ECS.world.query.with_relationship([Rels.create_belongs_to(city)])\
				.execute()
			if buildings_.is_empty():
				printerr("did not find a building")
			# TODO : could do other cities in another color
			for building: Entity in buildings_:
				if building.has_component(C_IsStorage):
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
			
			
			#current_building.add_relationship(Rels.create_belongs_to(city))
			
		Buildings.Ids.Fishery:
			var buildings_ = ECS.world.query.with_relationship([Rels.create_belongs_to(city)])\
				.execute()
			if buildings_.is_empty():
				printerr("did not find a building")
			# TODO : could do other cities in another color
			for building: Entity in buildings_:
				if building.has_component(C_IsStorage):
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
			
			
		Buildings.Ids.HunterTent:
			var buildings_ = ECS.world.query.with_relationship([Rels.create_belongs_to(city)])\
				.execute()
			if buildings_.is_empty():
				printerr("did not find a building")
			# TODO : could do other cities in another color
			for building: Entity in buildings_:
				if building.has_component(C_IsStorage):
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
			
			
		# TODO: should be something else?
		Buildings.Ids.Warehouse:
			pass
			
		Buildings.Ids.MainSquare:
			pass
			
		_:
			printerr("building not handled", building_id)
			return
	
	add_current_building_to_tree()
	
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

#region "raycasting"

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
			deselect_selected_entity()
			return
		
		# FIXME: would probably endup finding an entity if it's an island
		var entity_parent: Entity = SceneUtils.find_first_parent_of_type(
			collider,
			Entity,
		)
		if !entity_parent:
			print("did not find an Entity parent")
			deselect_selected_entity()
			return
		
		var c_building: C_Building = entity_parent.get_component(C_Building)
		if c_building:
			print("selecting building")
			selected_building = entity_parent
			event_bus.send_building_3D_selected.emit(entity_parent)
			return
		
		var c_pop_unit: C_PopUnit = entity_parent.get_component(C_PopUnit)
		if c_pop_unit:
			print("selecting C_PopUnit")
			selected_unit = entity_parent
			event_bus.send_unit_3D_selected.emit(entity_parent)
			return
			
		var c_ship: C_Ship = entity_parent.get_component(C_Ship)
		if c_ship:
			print("selecting C_Ship")
			selected_ship = entity_parent
			event_bus.send_ship_3D_selected.emit(entity_parent)
			return
		
		print("clicked on something that is not a building nor an unit %s %s" % [
			collider.get_path(),
			entity_parent.get_path(),
		])
		deselect_selected_entity()
	else:
		deselect_selected_entity()

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
		if selected_unit:
			print("moving selected_unit")
			var array: Array = []
			var dest: C_NavigationDestination = selected_unit.get_component(
				C_NavigationDestination
			)
			if dest:
				dest.target = position_
			else:
				array.push_back(target)
			
			var c_move: C_PopMovingToTarget = selected_unit.get_component(C_PopMovingToTarget)
			if c_move:
				c_move.move_target_type = C_PopMovingToTarget.MOVE_TARGET_TYPE.ORDER
			
			else:
				array.push_back(
					C_PopMovingToTarget.new(
						C_PopMovingToTarget.MOVE_TARGET_TYPE.ORDER
					)
				)
			ECS.world.emit_event(
				ECSEvents.ADD_COMPONENTS_TO_ENTITY_REQUESTED,
				selected_unit,
				{
					"components": array,
				}
			)
		elif selected_ship:
			# TODO : verify faction here
			var array: Array = []
			var dest: C_NavigationDestination = selected_ship.get_component(
				C_NavigationDestination
			)
			if dest:
				dest.target = position_
			else:
				array.push_back(target)
			
			var c_move: C_PopMovingToTarget = selected_ship.get_component(C_PopMovingToTarget)
			if c_move:
				c_move.move_target_type = C_PopMovingToTarget.MOVE_TARGET_TYPE.ORDER
			
			else:
				array.push_back(
					C_PopMovingToTarget.new(
						C_PopMovingToTarget.MOVE_TARGET_TYPE.ORDER
					)
				)
			ECS.world.emit_event(
				ECSEvents.ADD_COMPONENTS_TO_ENTITY_REQUESTED,
				selected_ship,
				{
					"components": array,
				}
			)
		else:
			ECS.world.emit_event(
				ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED,
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
				if island_parent != current_island:
					current_island = island_parent
					notify_summary_changed()
			else:
				push_error(
					"island %s does not have C_Island %s" % [
						collider.name,
						collider.get_path(),
					]
				)
		else:
			var collider_parent = collider.get_parent()
			if collider_parent is OceanNode1:
				#print("found ocean")
				current_island = null
				notify_summary_changed()
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

#endregion

func add_current_building_to_tree():
	#add_child(current_building)
	dynamic_buildings.add_child(current_building)

func deselect_selected_entity():
	if selected_building:
		deselect_selected_building()
	if selected_unit:
		event_bus.send_unit_3D_deselected.emit(selected_unit)
		selected_unit = null
	if selected_ship:
		event_bus.send_ship_3D_deselected.emit(selected_ship)
		selected_ship = null

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

func _on_ProductionSystem_produced_resources(
	changes_per_faction: Dictionary[int, Dictionary]
) -> void:
	print("_on_ProductionSystem_produced_resources %s" % [
		changes_per_faction.size(),
	])
	var changes: Dictionary[int, int] = changes_per_faction.get(
		local_player_faction_index,
	)
	if !changes:
		return
	for key in changes.keys():
		var quantity = local_player_storage.get_storage(key)
		#print("has %s of %s (produced %s)" % [
			#quantity.quantity,
			#key,
			#changes.get(key),
		#])
		event_bus.send_resource_updated.emit(
			key, quantity.quantity
		)

func _on_EventBus_ask_demolish_current_building() -> void:
	# Info: destroy / demolish / remove building
	print("_on_EventBus_ask_demolish_current_building")
	var trees: Array[MultiMeshInstanceArea] = []
	if selected_building.has_method("get_hidden_trees"):
		trees = selected_building.get_hidden_trees()
	
	selected_building.enabled = false
	
	# FIXME: if there is a disconnect, this could break
	var c_housing: C_HousingCapacity = selected_building.get_component(C_HousingCapacity)
	if c_housing and c_housing.current > 0:
		var pop_units = ECS.world.query\
			#.with_all([C_PopUnit])\
			.with_relationship([Rels.create_lives_in(selected_building)])\
			.execute()\
			.duplicate()
		if !pop_units.is_empty():
			#o_population_observer.find_and_assign_housing_to_pop_units(
				#pop_units,
				#selected_building,
			#)
			ECS.world.emit_event(
				ECSEvents.HOUSING_BUILDING_REASSIGN_POP_UNITS_REQUESTED,
				selected_building,
				{
					"pop_units": pop_units,
				}
			)
	
	var c_production: C_Production = selected_building.get_component(C_Production)
	if c_production:
		var pop_units = ECS.world.query\
			#.with_all([C_PopUnit])\
			.with_relationship([Rels.create_works_at(selected_building)])\
			.execute()\
			.duplicate()
		if !pop_units.is_empty():
			#o_population_observer.find_and_assign_production_building_to_pop_units(
				#pop_units,
				#selected_building,
			#)
			ECS.world.emit_event(
				ECSEvents.PRODUCTION_BUILDING_REASSIGN_POP_UNITS_REQUESTED,
				selected_building,
				{
					"pop_units": pop_units,
				}
			)
		else:
			print("building %s does not have workers" % [
				selected_building.name,
			])
	
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

func initialize_storage():
	print("initialize_storage")
	if !use_initial_resources:
		Loggie.msg("not using inital resources").color("blue")
		return
	for res: BuiltinResourceQuantityDefinition in initial_resources.builtin_resources.values():
		print("setting storage for %s %s" % [
			res.resource_type,
			res.quantity,
		])
		local_player_storage.set_storage(
			res.resource_type,
			res.quantity,
			-1
		)
		event_bus.send_resource_updated.emit(
			res.resource_type,
			res.quantity,
		)
	for res: ResourceQuantityDefinition in initial_resources.custom_resources.values():
		local_player_storage.set_storage(
			res.resource_type,
			res.quantity,
			-1
		)
		event_bus.send_resource_updated.emit(
			res.resource_type,
			res.quantity,
		)
	
	local_player_c_faction.gold_count = initial_resources.gold_count
	event_bus.money_updated.emit(
		local_player_c_faction.gold_count
	)

func has_resources_to_construct_building(def: BuildingDefinition) -> bool:
	var has_resources: bool = true
	for cost in def.costs:
		if local_player_storage.has_at_least(
			cost.resource,
			cost.cost,
		):
			continue
		has_resources = false
		break
	return has_resources

func _on_EventBus_ask_change_ocean_visual(selected_ocean_visual_id: int) -> void:
	map.select_ocean_visual(selected_ocean_visual_id)

func _on_EventBus_ask_debug_spawn_ship() -> void:
	ge_map_ship_spawner.try_spawn_ship()

func _on_NavigationSystem_ship_arrived_at_dock(
	_ship: Entity,
	dock: Entity
) -> void:
	# TODO: find another sound
	ship_bell_audio_stream_player_3d.global_position = dock.global_position
	ship_bell_audio_stream_player_3d.play()

func _on_FeedSystem_consumed_resources(changes_per_faction: Dictionary[int, Dictionary]) -> void:
	print("_on_FeedSystem_consumed_resources")
	if changes_per_faction.is_empty():
		printerr("_on_FeedSystem_consumed_resources changes is empty")
		return
	if !changes_per_faction.has(local_player_faction_index):
		return
	var changes: Dictionary[int, int] = changes_per_faction.get(
		local_player_faction_index,
	)
	if !changes:
		return
	for key in changes.keys():
		var quantity = local_player_storage.get_storage(key)
		if quantity == null:
			# FIXME: can be null if its neutral entity with infinite resources
			printerr("initialize resources")
			continue
		event_bus.send_resource_updated.emit(
			key, quantity.quantity
		)

func _on_FeedSystem_pop_units_died(
	changes_per_faction: Dictionary[int, Dictionary]
) -> void:
	print("_on_FeedSystem_pop_units_died")
	for changes: Dictionary[int, int] in changes_per_faction.values():
		for key in changes.keys():
			population_decrease(
				key,
				changes.get(key)
			)

func _on_FeedSystem_workers_died(
	changes_per_faction: Dictionary[int, Dictionary]
) -> void:
	print("_on_FeedSystem_workers_died")
	for changes: Dictionary[int, int] in changes_per_faction.values():
		for key in changes.keys():
			workers_decrease(
				key,
				changes.get(key)
			)

func _on_FeedSystem_island_population_changed(
	islands: Dictionary[Entity, int]
) -> void:
	for island: Entity in islands.keys():
		if island == current_island:
			print("current island workers decreased")
			var summary: C_PopulationSummary = island.get_component(
				C_PopulationSummary
			)
			if summary:
				event_bus.available_workers_updated.emit(
					summary.workers
				)
				event_bus.population_updated.emit(
					summary.populations
				)

func _on_PaySystem_gold_count_changed(
	changes_per_faction: Dictionary[int, int]
) -> void:
	print("_on_PaySystem_gold_count_changed")
	if changes_per_faction.has(local_player_faction_index):
		#var c_storage: C_Storage = local_player_faction.get_component(
			#C_Storage
		#)
		event_bus.money_updated.emit(
			local_player_c_faction.gold_count
		)

func _on_OShipMiscObserver_island_population_changed(island: Entity) -> void:
	print("_on_OShipMiscObserver_island_population_changed")
	if island == current_island:
		print("current island workers decreased")
		var summary: C_PopulationSummary = island.get_component(
			C_PopulationSummary
		)
		if summary:
			#event_bus.available_workers_updated.emit(
				#summary.workers
			#)
			event_bus.population_updated.emit(
				summary.populations
			)

func _on_EventBus_notify_market_menu_closed() -> void:
	rtsCamera.is_movement_disabled = false

func _on_EventBus_notify_market_menu_opened() -> void:
	rtsCamera.is_movement_disabled = true

func _on_OShipTradingObserver_exchange_realized(
	dock_changes: StorageChangeDef,
	ship_changes: StorageChangeDef,
	dock: Entity,
	ship: Entity,
) -> void:
	print("_on_OShipTradingObserver_exchange_realized dock %s" % [
		JSON.stringify(JSON.from_native(dock_changes, true)),
	])
	print("_on_OShipTradingObserver_exchange_realized ship %s" % [
		JSON.stringify(JSON.from_native(ship_changes, true)),
	])
	# TODO: emit gold instance too
	if dock_changes.faction_id == local_player_faction_index \
		or ship_changes.faction_id == local_player_faction_index:
		#var c_storage: C_Storage = local_player_faction.get_component(
			#C_Storage
		#)
		event_bus.money_updated.emit(local_player_c_faction.gold_count)
	else:
		print("exchange is not for local player")
		# TODO: could have an option for this
		return
	
	var offset_limit: int = 5
	
	if true:
		var instance: TradeExchangeSummaryFloatingUI3D = TRADE_EXCHANGE_SUMMARY_FLOATING_UI_3D.instantiate()
		var offset: Vector3 = Vector3(
			randi_range(-offset_limit, offset_limit),
			5,
			randi_range(-offset_limit, offset_limit),
		)
		instance.global_position = dock.global_position + offset
		add_child(instance)
		var res_def: ResourceDefinition = resource_list_definition_dict.get(
			Resources.Types.Gold,
		)
		instance.set_content(
			res_def.normal_icon,
			str(dock_changes.gold_change),
		)
		instance.start_tween()
		
	if true:
		var instance: TradeExchangeSummaryFloatingUI3D = TRADE_EXCHANGE_SUMMARY_FLOATING_UI_3D.instantiate()
		var offset: Vector3 = Vector3(
			randi_range(-offset_limit, offset_limit),
			5,
			randi_range(-offset_limit, offset_limit),
		)
		instance.global_position = ship.global_position + offset
		add_child(instance)
		var res_def: ResourceDefinition = resource_list_definition_dict.get(
			Resources.Types.Gold,
		)
		instance.set_content(
			res_def.normal_icon,
			str(ship_changes.gold_change),
		)
		instance.start_tween()
	
	# TODO : emit money sound
	#if dock_changes.faction_id == local_player_faction_index:
	print("dock_changes.faction_id == local_player_faction_index")
	for key in dock_changes.resources_changes.keys():
		var quantity = local_player_storage.get_storage(key)
		event_bus.send_resource_updated.emit(
			key, quantity.quantity
		)
		
		var value = dock_changes.resources_changes.get(
			key
		)
		var instance: TradeExchangeSummaryFloatingUI3D = TRADE_EXCHANGE_SUMMARY_FLOATING_UI_3D.instantiate()
		var offset: Vector3 = Vector3(
			randi_range(-offset_limit, offset_limit),
			5,
			randi_range(-offset_limit, offset_limit),
		)
		instance.global_position = dock.global_position + offset
		add_child(instance)
		var res_def: ResourceDefinition = resource_list_definition_dict.get(
			key
		)
		instance.set_content(
			res_def.normal_icon,
			str(value),
		)
		instance.start_tween()
	
	#if ship_changes.faction_id == local_player_faction_index:
	print("ship_changes.faction_id == local_player_faction_index")
	for key in ship_changes.resources_changes.keys():
		var quantity = local_player_storage.get_storage(key)
		event_bus.send_resource_updated.emit(
			key, quantity.quantity
		)
		
		var value = ship_changes.resources_changes.get(
			key
		)
		var instance: TradeExchangeSummaryFloatingUI3D = TRADE_EXCHANGE_SUMMARY_FLOATING_UI_3D.instantiate()
		var offset: Vector3 = Vector3(
			randi_range(-offset_limit, offset_limit),
			5,
			randi_range(-offset_limit, offset_limit),
		)
		instance.global_position = ship.global_position + offset
		add_child(instance)
		var res_def: ResourceDefinition = resource_list_definition_dict.get(
			key
		)
		instance.set_content(
			res_def.normal_icon,
			str(value),
		)
		instance.start_tween()
