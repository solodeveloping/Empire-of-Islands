extends Node3D
class_name Game3D

const SAMPLE_CAMERA = preload("uid://de8asbx0dukri")
const SAMPLE_PLAYER = preload("uid://wilkunqqgl4")
const OWN_RTS_CAMERA = preload("uid://cwdh31b0w8vwk")

const RANGE_CYLINDER_INDICATOR = preload("uid://dthmx62xw7kk4")
const RANGE_BOX_INDICATOR = preload("uid://bp86o35g1m40")

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
var resource_growth_stages_array: BuiltinResourceGrowthStagesArray

# TODO: remove this
@export
var initial_factions: Array[FactionDef] = []
@export
var initial_factions_list: FactionListDefinition

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

@onready var production_system: ProductionSystem = $World/Systems/gameplay/ProductionSystem

@onready var o_population_observer: O_PopulationObserver = $World/Systems/gameplay/O_PopulationObserver

@onready var o_population_movement_observer: O_PopulationMovementObserver = $World/Systems/gameplay/O_PopulationMovementObserver

@onready var faction_misc_system: FactionMiscSystem = $World/Systems/gameplay/FactionMiscSystem
@onready var o_faction_misc_observer: O_FactionMiscObserver = $World/Systems/gameplay/O_FactionMiscObserver

@onready var population_misc_system: PopulationMiscSystem = $World/Systems/gameplay/PopulationMiscSystem

@onready var o_ship_trading_observer: O_ShipTradingObserver = $World/Systems/gameplay/O_ShipTradingObserver

@onready var o_spawn_observer: O_SpawnObserver = $World/Systems/gameplay/O_SpawnObserver

@onready var the_storages: Node = $TheStorages

@onready var the_buildings_cost: TheBuildingsCost = $TheBuildingsCost

@onready var ge_map_ship_spawner: GE_MapShipSpawner = $World/GE_MapShipSpawner

@onready var ship_bell_audio_stream_player_3d: AudioStreamPlayer3D = $ShipBellAudioStreamPlayer3D

@onready var minimap_camera_3d: CameraFollowTarget_XZ = $SubViewport/MinimapCamera3D

@onready var static_minimap_system: StaticMinimapSystem = $StaticMinimapSystem

@onready var position_node_at_camera_center_view: PositionNodeAtCameraCenterView = $PositionNodeAtCameraCenterView

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
var snap_to_object_enabled: bool = true
var freeze_building_location: bool = false

# FIXME: should it just be current_building?
var selected_building: Entity
# FIXME: should it be the same?
var selected_unit: Entity
var selected_ship: Entity
var selected_animal: Entity
var selected_ground_bed: GroundDirtBed_1
var selected_ground_bed_parent: Entity
var selected_ground_bed_id: int

# FIXME: not satisfied with this system
# it's kinda bad
var mouse_over_loot: Entity
var mouse_over_animal: Entity
var mouse_over_building: Entity

enum MOUSE_OVER_TYPE {
	LOOT,
	ANIMAL,
	BUILDING,
	OCEAN,
	ISLAND,
	TREE,
	ENTITY_UNKNOWN,
	NOTHING,
}

var current_mouse_over_type: MOUSE_OVER_TYPE = MOUSE_OVER_TYPE.NOTHING

var current_dock_buoy_id: int = 0

var map: Node3D
var city: Entity

var current_island: IslandGECS1

var rtsCamera: RTSCamera

# TODO
# https://github.com/godotengine/godot/issues/24699
# "Pass" does not pass
# Must accept_event if want to handle
# or ignore
# _gui_input() or _input()
# https://github.com/godotengine/godot/issues/19402

#region "populations"

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

func _on_OBuildingAddedObserver_pop_unit_found_work(
	pop_type: int,
	island: Entity
) -> void:
	_handle_pop_unit_found_work(
		pop_type,
		island,
	)

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

func _on_OBuildingRemovedObserver_housing_capacity_decreased(
	pop_type: int,
	amount: int,
	island: Entity
) -> void:
	if island == current_island:
		print("current island housing_capacity_decreased")
		var summary: C_PopulationSummary = island.get_component(
			C_PopulationSummary
		)
		if summary:
			event_bus.housing_capacity_updated.emit(
				summary.housing_capacities
			)
			
	housing_capacity_decrease(
		pop_type,
		amount,
	)

func _on_OBuildingRemovedObserver_workers_capacity_decreased(
	pop_type: int,
	amount: int,
	island: Entity
) -> void:
	if island == current_island:
		print("current island workers_capacity_decreased")
		var summary: C_PopulationSummary = island.get_component(
			C_PopulationSummary
		)
		if summary:
			event_bus.worker_capacities_updated.emit(
				summary.worker_capacities
			)
		
	worker_capacities_decrease(
		pop_type,
		amount,
	)

func _on_OPopulationObserver_pop_unit_found_work(
	pop_type: int,
	island: Entity,
) -> void:
	_handle_pop_unit_found_work(
		pop_type,
		island,
	)

func _handle_pop_unit_found_work(
	pop_type: int,
	island: Entity,
):
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

#endregion

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
	
	StaticFactions.local_player_faction_id = local_player_faction_index
	
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
	
	ge_map_ship_spawner.initial_factions = initial_factions_list.factions
	var faction_id = 0
	for faction in initial_factions_list.factions:
		var faction_entity: Faction_ECS = Faction_ECS.new()
		
		var c_faction: C_Faction = C_Faction.new(faction, faction_id)
		
		# could have predefined relations
		for i in initial_factions_list.factions.size():
			# we put ourselves
			# this way we can use Array[id] instead of a dict
			var relation: FactionRelationDef
			if faction.initial_default_faction_relationship:
				relation = FactionRelationDef.new(
					i,
					faction.initial_default_faction_relationship.relation_value
				)
			else:
				# TODO: could be a global setting
				relation = FactionRelationDef.new(
					i,
					500
				)
			c_faction.relationships.push_back(
				relation
			)
		
		faction_entity.add_component(
			c_faction
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
	
	o_spawn_observer.set_faction_entities(faction_entities)
	
	local_player_faction = faction_entities.get(local_player_faction_index)
	local_player_storage = the_storages.get_child(
		local_player_faction_index
	)
	local_player_c_faction = local_player_faction.get_component(
		C_Faction
	)
	
	event_bus.send_local_player_faction_storage_changed.emit(
		local_player_storage
	)
	event_bus.send_local_player_faction_changed.emit(
		local_player_faction,
		local_player_c_faction
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
	
	production_system.set_resource_growth_stages_array(
		resource_growth_stages_array
	)
	
	event_bus.ask_change_ground_bed_resource_id.connect(
		_on_event_bus_ask_change_ground_bed_resource_id
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
	var own_rts_camera: OwnRTSCamera = OWN_RTS_CAMERA.instantiate()
	add_child(own_rts_camera)
	rtsCamera = own_rts_camera.rts_camera
	# TODO: make it an option
	#instance.projection = Camera3D.PROJECTION_ORTHOGONAL
	
	#minimap_camera_3d.target = rtsCamera
	#static_minimap_system.center_target_node = rtsCamera
	position_node_at_camera_center_view.camera = rtsCamera
	static_minimap_system.center_target_node = position_node_at_camera_center_view.target
	minimap_camera_3d.target = position_node_at_camera_center_view.target
	
	event_bus.ask_create_building.connect(
		_on_ask_create_building
	)
	event_bus.ask_rotate_building.connect(
		_on_event_bus_ask_rotate_building
	)
	event_bus.ask_enable_snap_to_objects.connect(
		_on_event_bus_ask_enable_snap_to_objects
	)
	event_bus.ask_disable_snap_to_objects.connect(
		_on_event_bus_ask_disable_snap_to_objects
	)
	event_bus.send_hide_build_position_rotation_ui.emit()
	
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
	
	event_bus.send_local_player_faction_id_changed.emit(
		local_player_faction_index,
	)
	
	ECSEvents.emit_event(
		ECSEvents.SPAWN_ENTITIES_REQUESTED, null
	)
	
	var ships = ECS.world.query.with_all([
		C_Ship,
	]).execute()
	
	event_bus.send_all_ecs_ships_updated.emit(
		ships,
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
	
	if Input.is_action_pressed("place_building"):
		if current_building:
			freeze_building_location = !freeze_building_location

func _physics_process(delta: float) -> void:
	world.process(delta, 'physics')
	
	# TODO: dont intersect with curve
	
	if current_building:
		if freeze_building_location:
			return
		
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
					
					if snap_to_object_enabled:
						if "snap_objects" in current_building:
							var closest_snap: Node3D = null
							var closest_snap_distance: float = 0
							for obj: Node3D in current_building.snap_objects:
								var parent_: Entity = obj.get_parent().get_parent()
								var r_faction = parent_.get_relationship(
									Rels.belongs_to_faction
								)
								var c_faction: C_Faction = r_faction.target.get_component(
									C_Faction
								)
								if c_faction.faction_id == local_player_c_faction.faction_id:
									if closest_snap == null:
										closest_snap = obj
										closest_snap_distance = obj.global_position.distance_to(
											current_building.global_position
										)
									else:
										var distance = obj.global_position.distance_to(
											current_building.global_position
										)
										if distance < closest_snap_distance:
											closest_snap_distance = distance
											closest_snap = obj
								
								# TODO(1): check farm faction
						
							if closest_snap:
								current_building.position = closest_snap.global_position
					
					# TODO: query and display some thing?
					# for farms
					# once we have something to color in yellow or something like this
					
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
	
	#print("event %s" % [
		#event
	#])

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

#region "buildings"

func cancel_build_current_building():
	current_building.get_parent().remove_child(current_building)
	current_building = null
	event_bus.send_building_creation_aborted.emit(current_building_id)
	rtsCamera.changing_distance_enabled = true
	
	event_bus.send_hide_build_position_rotation_ui.emit()

func _on_event_bus_ask_rotate_building(value: float):
	current_building_angle = value
	current_building.rotation_degrees = Vector3(
		0,
		current_building_angle,
		0
	)

func _on_event_bus_ask_enable_snap_to_objects():
	snap_to_object_enabled = true

func _on_event_bus_ask_disable_snap_to_objects():
	snap_to_object_enabled = false

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
		# FIXME: this does not feel good
		if cost.resource == Resources.Types.Gold:
			local_player_c_faction.gold_count -= cost.cost
			event_bus.money_updated.emit(
				local_player_c_faction.gold_count,
			)
			continue
		
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
							current_building.add_relationship(
								Rels.create_belongs_to(building)
							)
							break
			if !found_a_main_square:
				printerr("did not find a main square in the right range")
		
		Buildings.Ids.Warehouse,\
		Buildings.Ids.Lumberjack,\
		Buildings.Ids.Fishery,\
		Buildings.Ids.HunterTent:
			pass
		
		Buildings.Ids.Farm:
			pass
		
		Buildings.Ids.Pasture:
			var farm_like_buildings = ECS.world.query.with_all([
				C_CanExtendFarm,
				C_RangeBox,
				])\
				.with_relationship([
					Rels.create_belongs_to_faction(local_player_faction)
				])\
				.execute()
			
			var building_: Node3D = current_building as Variant as Node3D
			for building: Entity in farm_like_buildings:
				var farm_like_: Node3D = building as Variant as Node3D
				
				var c_range_box: C_RangeBox = building.get_component(
					C_RangeBox
				)
				
				var oriented_rect: OrientedRect2 = OrientedRect2.new(
					Vector2(farm_like_.global_position.x, farm_like_.global_position.z),
					Vector2(c_range_box.size.x, c_range_box.size.z),
					#45,
					farm_like_.rotation_degrees.y,
				)
				
				oriented_rect._debug_points(
					1,
					30
				)
				
				var is_in = oriented_rect.is_point_inside(
					Vector2(
						building_.global_position.x,
						building_.global_position.z
					)
				)
				
				if is_in:
					print("building is inside a farm like building, its an extension")
					
					current_building.add_relationship(
						Rels.create_is_extension_of(building)
					)
					
					break
				
		
		_:
			var name_ = Buildings.get_building_name(
				current_building_id
			)
			printerr("building of id not handled: %s %s" % [
				current_building_id,
				name_,
			])
	
	# FIXME: do not seem to be working
	# Ask the GECS Discord maybe
	current_building.add_relationship(
		Rels.create_belongs_to(local_player_faction)
	)
	
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
			buoy.add_relationship(
				Rels.create_belongs_to_faction(
					local_player_faction
				)
			)
			ECS.world.add_entity(buoy)
		Buildings.Ids.MainSquare:
			pass
		Buildings.Ids.Farm:
			current_building.hide_indicators()
		Buildings.Ids.Pasture:
			current_building.hide_indicators()
		_:
			print("current_building_id:", current_building_id)
	
	ECS.world.emit_event(
		ECSEvents.GENERIC_BUILDING_ADDED, 
		current_building,
		{
			"island": current_island_for_building,
			"faction": local_player_faction,
		}
	)
	
	# Info: this allows to be able to click on the building creation button again
	# FIXME: maybe do not disable the button, not sure why this is done
	event_bus.send_building_created.emit(current_building_id)
	
	if current_building.has_method("finalize_construction"):
		current_building.finalize_construction()
	else:
		printerr("building does not have method finalize_construction")
	
	if current_building.has_method("add_children_entities"):
		current_building.add_children_entities()
	
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
			
	if current_building.has_method("update_minimap_display"):
		current_building.update_minimap_display.call_deferred()
	
	current_building = null
	current_building_def = null
	current_island_for_building = null
	
	rtsCamera.changing_distance_enabled = true
	
	audio_player.play_valid_construction()
	
	event_bus_emit_send_minimap_data_changed.call_deferred()
	
	event_bus.send_hide_build_position_rotation_ui.emit()

func finalize_existing_buildings():
	print("finalize_existing_buildings")
	map.add_entitiess_to_ecs(city)
	ECSEvents.emit_event(
		ECSEvents.ASSIGN_FACTION_TO_ENTITIES_REQUESTED,
		{}
	)
	post_finalize_existing_buildings.call_deferred()

func post_finalize_existing_buildings():
	event_bus.send_minimap_data_changed.emit()

func event_bus_emit_send_minimap_data_changed():
	event_bus.send_minimap_data_changed.emit()

func _on_ask_create_building(building_id: Buildings.Ids):
	
	# TODO: queue system?
	if current_building:
		cancel_build_current_building()
	
	if !building_list_definition.builtin_buildings.has(building_id):
		if !building_list_definition.extra_buildings.has(building_id):
			printerr("game_3d: building %s is not present" % [
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
	
	freeze_building_location = false
	
	current_building = current_building_def.scene.instantiate()
	
	NodeUtils.remove_all_children(range_indicator)
	range_indicator.show()
	
	current_building_id = building_id
	
	rtsCamera.changing_distance_enabled = false
	
	# TODO : mutualize
	match building_id:
		Buildings.Ids.Tent:
			var buildings_ = ECS.world.query.with_relationship([
				Rels.create_belongs_to(city)
				])\
				.execute()
			if buildings_.is_empty():
				printerr("did not find a building in the city")
			# TODO : could do other cities in another color
			for building: Entity in buildings_:
				if building.has_component(C_MainSquare):
					if building.has_component(C_Range):
						var range_: C_Range = building.get_component(C_Range)
						var indicator: CSGCylinder3D = RANGE_CYLINDER_INDICATOR.instantiate()
						indicator.radius = range_.value
						range_indicator.add_child(indicator)
						
						indicator.global_position = building.global_position
			
			if range_indicator.get_child_count() == 0:
				printerr("could not find a C_MainSquare")
			
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
			var buildings_ = ECS.world.query.with_relationship([
				Rels.create_belongs_to(city)
				])\
				.execute()
			if buildings_.is_empty():
				printerr("did not find a building in the city")
			
			if range_indicator.get_child_count() == 0:
				printerr("could not find a C_IsStorage")
			
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
			var buildings_ = ECS.world.query.with_relationship([
				Rels.create_belongs_to(city)
				])\
				.execute()
			
			if buildings_.is_empty():
				printerr("did not find a building in the city")
			
			if range_indicator.get_child_count() == 0:
				printerr("could not find a C_IsStorage")
			
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
			var buildings_ = ECS.world.query.with_relationship([
				Rels.create_belongs_to(city)
				])\
				.execute()
			
			if buildings_.is_empty():
				printerr("did not find a building in the city")
			
			if range_indicator.get_child_count() == 0:
				printerr("could not find a C_IsStorage")
			
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
		
		Buildings.Ids.Farm:
			pass
		
		Buildings.Ids.Pasture:
			var extensions_ = ECS.world.query.with_all([
				C_FarmExtension
				])\
				.execute()
			
			for extension in extensions_:
				extension.show()
			
			# TODO: can do more things
			
			var buildings_ = ECS.world.query.with_all([
				C_CanExtendFarm,
				C_RangeBox,
				])\
				.with_relationship([
					Rels.create_belongs_to_faction(local_player_faction)
				])\
				.execute()
			
			if buildings_.is_empty():
				print("could not find a farm belonging to this player")
			else:
				for building: Entity in buildings_:
					var range_: C_RangeBox = building.get_component(C_RangeBox)
					var indicator: CSGBox3D = RANGE_BOX_INDICATOR.instantiate()
					#indicator.size = Vector3(
						#50,
						#1,
						#50,
					#)
					indicator.size = range_.size
					range_indicator.add_child(indicator)
					
					indicator.global_transform = building.global_transform
				
				for indicator: CSGBox3D in range_indicator.get_children():
					var new_indicator: CSGBox3D = RANGE_BOX_INDICATOR.instantiate()
					new_indicator.size = Vector3(
						indicator.size.x - 0.2,
						indicator.size.y,
						indicator.size.z - 0.2
					)
					new_indicator.operation = CSGShape3D.OPERATION_SUBTRACTION
					range_indicator.add_child(new_indicator)
					
					new_indicator.global_transform = indicator.global_transform
				
		
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
		
	event_bus.send_show_build_position_rotation_ui.emit()

#endregion

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
		
		var parent_ = collider.get_parent()
		# FIXME: would probably endup finding an entity if it's an island
		var entity_parent: Entity = SceneUtils.find_first_parent_of_type(
			collider,
			Entity,
		)
		if !entity_parent:
			print("did not find an Entity parent")
			deselect_selected_entity()
			return
		
		if parent_ is GroundDirtBed_1:
			print("clicked on GroundDirtBed_1")
			
			var index = parent_.get_index()
			selected_ground_bed = parent_
			selected_ground_bed_id = index
			selected_ground_bed_parent = entity_parent
			
			event_bus.send_ground_bed_3D_selected.emit(
				selected_ground_bed,
				selected_ground_bed_id,
				entity_parent,
			)
			
			return
		
		var c_building: C_Building = entity_parent.get_component(
			C_Building
		)
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
			
		var c_is_animal: C_IsAnimal = entity_parent.get_component(C_IsAnimal)
		if c_is_animal:
			print("selecting C_IsAnimal")
			selected_animal = entity_parent
			event_bus.send_animal_3D_selected.emit(entity_parent)
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
			var c_health: C_Health = selected_unit.get_component(
				C_Health
			)
			if c_health.current <= 0:
				return
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
			print("moving selected_ship")
			var c_health: C_Health = selected_ship.get_component(
				C_Health
			)
			if c_health.current <= 0:
				return
			
			var collider: Node3D = raycast_result["collider"]
			var _collider_as_entity = collider as Variant as Entity
			if _collider_as_entity:
				print("something is entity")
				if _collider_as_entity.has_component(
					C_IsLoot
				):
					print("clicked on loot")
					ECS.world.emit_event(
						ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED,
						selected_ship,
						{
							"component": C_LookingForLoot.new(),
						}
					)
				elif _collider_as_entity.has_component(C_PopUnit):
					print("clicked on pop unit")
			elif collider.get_parent() is Entity:
				print("something is entity")
				var entity: Entity = collider.get_parent()
				if entity.has_component(
					C_IsLoot
				):
					print("clicked on loot (2)")
					ECS.world.emit_event(
						ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED,
						selected_ship,
						{
							"component": C_LookingForLoot.new(),
						}
					)
				elif entity.has_component(C_PopUnit):
					print("clicked on pop unit")
			else:
				print("not an entity")
				pass
			
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
			return
			var c_health: C_Health = sail_ship_1.get_component(
				C_Health
			)
			if c_health.current <= 0:
				return
			ECS.world.emit_event(
				ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED,
				sail_ship_1,
				{
					"component": target,
				}
			)
	else:
		print("clicked onto nothing")

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
		_identify_raycast_result(raycast_result)
	else:
		print("mouse is over nothing")
		_handle_mouse_not_over_loot()

func _identify_raycast_result(raycast_result: Variant):
	#print("pos ", raycast_result.position)
	#print("result ", raycast_result)
	
	# FIXME: all these things rely on their identity being associated
	# with a proper object above
	# example: collider with island as parent
	# could be a rock but still result in "Island"
	
	var collider: Node3D = raycast_result.collider
	if collider is MultiMeshInstanceCollider:
		_handle_mouse_over_type_detected(
			MOUSE_OVER_TYPE.TREE,
			null,
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
		_handle_mouse_over_type_detected(
			MOUSE_OVER_TYPE.ISLAND,
			island_parent,
		)
		return
	
	var collider_parent = collider.get_parent()
	if collider_parent is OceanNode1:
		_handle_mouse_over_type_detected(
			MOUSE_OVER_TYPE.OCEAN,
			null,
			collider_parent,
		)
		return
	
	var entity_parent: Entity = SceneUtils.find_first_parent_of_type(
		collider, 
		Entity
	)
	if entity_parent:
		_handle_mouse_over_entity(entity_parent)
		return
	
	print("parent not an entity")
	var _as_entity: Entity = collider as Variant as Entity
	if _as_entity:
		_handle_mouse_over_entity(_as_entity)
		return
	
	# TODO: implement this
	if collider_parent is GroundDirtBed_1:
		print("found ground_dirt_bed")
	

func _handle_mouse_over_entity(entity: Entity):
	print("_handle_mouse_over_entity %s" % [
		entity.get_path(),
	])
	if entity.has_component(C_IsLoot):
		_handle_mouse_over_type_detected(
			MOUSE_OVER_TYPE.LOOT,
			entity,
		)
	elif entity.has_component(C_IsAnimal):
		_handle_mouse_over_type_detected(
			MOUSE_OVER_TYPE.ANIMAL,
			entity,
		)
	elif entity.has_component(C_Building):
		_handle_mouse_over_type_detected(
			MOUSE_OVER_TYPE.BUILDING,
			entity,
		)
	else:
		_handle_mouse_over_type_detected(
			MOUSE_OVER_TYPE.ENTITY_UNKNOWN,
			entity,
		)
	
	var c_name: C_Name = entity.get_component(C_Name)
	if c_name:
		event_bus.send_mouse_over_object_changed.emit(
			c_name.name_,
			entity,
		)
	else:
		event_bus.send_mouse_over_object_changed.emit(
			entity.name,
			entity,
		)
	

func _handle_mouse_over_type_detected(
	new_mouse_over_type: MOUSE_OVER_TYPE,
	entity: Entity,
	node_not_entity: Node3D = null
):
	var path_ = ""
	if entity:
		path_ = entity.get_path()
	elif node_not_entity:
		path_ = node_not_entity.get_path()
	print("_handle_mouse_over_type_detected %s %s" % [
		path_,
		new_mouse_over_type,
	])
	if current_mouse_over_type != new_mouse_over_type:
		print("current_mouse_over_type != new_mouse_over_type")
		match current_mouse_over_type:
			MOUSE_OVER_TYPE.LOOT:
				if mouse_over_loot:
					mouse_over_loot.hide_mouse_over()
					mouse_over_loot = null
					event_bus.send_mouse_not_over_loot_updated.emit()
			MOUSE_OVER_TYPE.ANIMAL:
				if mouse_over_animal:
					mouse_over_animal.hide_aggro_area()
					mouse_over_animal = null
			MOUSE_OVER_TYPE.BUILDING:
				var farm_extensions = ECS.world.query\
					#.with_all([
					#C_CanExtendFarm,
					#C_RangeBox,
					#])\
					.with_relationship([
						Rels.create_is_extension_of(mouse_over_building)
					])\
					.execute()
				
				for building: Entity in farm_extensions:
					building.hide_ground_indicator()
				
				mouse_over_building = null
				
			MOUSE_OVER_TYPE.OCEAN:
				pass
			MOUSE_OVER_TYPE.ISLAND:
				current_island = null
			MOUSE_OVER_TYPE.TREE:
				pass
			MOUSE_OVER_TYPE.ENTITY_UNKNOWN:
				pass
			MOUSE_OVER_TYPE.NOTHING:
				pass
			_:
				printerr("MOUSE_OVER_TYPE %s not managed"% [
					current_mouse_over_type,
				])
		
		# Only when the mouse over changes
		match new_mouse_over_type:
			MOUSE_OVER_TYPE.LOOT:
				pass
			MOUSE_OVER_TYPE.ANIMAL:
				pass
			MOUSE_OVER_TYPE.BUILDING:
				pass
					
			MOUSE_OVER_TYPE.OCEAN:
				notify_summary_changed()
				event_bus.send_city_name_changed.emit(
					node_not_entity.ocean_name
				)
				event_bus.send_mouse_over_object_changed.emit(
					node_not_entity.ocean_name,
					# FIXME?: used to be the collider
					node_not_entity,
				)
			MOUSE_OVER_TYPE.ISLAND:
				pass
			MOUSE_OVER_TYPE.TREE:
				pass
			MOUSE_OVER_TYPE.ENTITY_UNKNOWN:
				pass
			MOUSE_OVER_TYPE.NOTHING:
				pass
			_:
				printerr("new MOUSE_OVER_TYPE %s not managed"% [
					current_mouse_over_type,
				])
	
	# refresh every time
	match new_mouse_over_type:
		MOUSE_OVER_TYPE.LOOT:
			mouse_over_loot = entity
			mouse_over_loot.show_mouse_over()
			event_bus.send_mouse_over_loot_updated.emit(
				entity
			)
		MOUSE_OVER_TYPE.ANIMAL:
			mouse_over_animal = entity
			entity.show_aggro_area()
		MOUSE_OVER_TYPE.BUILDING:
			print("MOUSE_OVER_TYPE.BUILDING")
			mouse_over_building = entity
			
			if entity.has_component(C_Farm):
				print("building has C_Farm")
				var farm_extensions = ECS.world.query\
					#.with_all([
					#C_CanExtendFarm,
					#C_RangeBox,
					#])\
					.with_relationship([
						Rels.create_is_extension_of(entity)
					])\
					.execute()
				
				print("found %s extensions" % [
					farm_extensions.size(),
				])
				
				for building: Entity in farm_extensions:
					building.show_ground_indicator()
				
		MOUSE_OVER_TYPE.OCEAN:
			pass
		MOUSE_OVER_TYPE.ISLAND:
			var c_island: C_Island = entity.get_component(C_Island)
			if c_island:
				if entity != current_island:
					current_island = entity
					notify_summary_changed()
			else:
				push_error(
					"island %s does not have C_Island %s" % [
						entity.name,
						entity.get_path(),
					]
				)
		MOUSE_OVER_TYPE.TREE:
			event_bus.send_mouse_over_object_changed.emit(
				"Tree",
				node_not_entity,
			)
		MOUSE_OVER_TYPE.ENTITY_UNKNOWN:
			pass
		MOUSE_OVER_TYPE.NOTHING:
			pass
		_:
			printerr("new MOUSE_OVER_TYPE %s not managed"% [
				current_mouse_over_type,
			])
	
	current_mouse_over_type = new_mouse_over_type
	

func _handle_mouse_not_over_loot():
	if !mouse_over_loot:
		# FIXME: this is terrible?
		if mouse_over_animal:
			mouse_over_animal.hide_aggro_area()
			mouse_over_animal = null
		return
	
	print("mouse over entity without loot")
	mouse_over_loot.hide_mouse_over()
	mouse_over_loot = null
	event_bus.send_mouse_not_over_loot_updated.emit()

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
	if selected_animal:
		event_bus.send_animal_3D_deselected.emit(selected_animal)
		selected_animal = null
	if selected_ground_bed:
		print("hide selected_ground_bed")
		event_bus.send_ground_bed_3D_deselected.emit(
			selected_ground_bed,
			selected_ground_bed_id,
			selected_ground_bed_parent,
		)
		selected_ground_bed = null
		selected_ground_bed_parent = null

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
	changes_per_faction: Dictionary[int, FactionProductionChangeDef]
) -> void:
	print("_on_ProductionSystem_produced_resources %s" % [
		changes_per_faction.size(),
	])
	var changes: FactionProductionChangeDef = changes_per_faction.get(
		local_player_faction_index,
	)
	if !changes:
		return
	
	for key in changes.changes_per_resource.keys():
		var quantity = local_player_storage.get_storage(key)
		#print("has %s of %s (produced %s)" % [
			#quantity.quantity,
			#key,
			#changes.get(key),
		#])
		event_bus.send_resource_updated.emit(
			key, quantity.quantity
		)
	
	var offset_limit: int = 3
	
	for change_per_building: ProductionChangeDef in changes.list:
		if change_per_building.gold_change != 0:
			_show_resource_change(
				Resources.Types.Gold,
				change_per_building.gold_change,
				change_per_building.production_building.global_position,
				offset_limit,
			)
		for key in change_per_building.resources_changes.keys():
			var value = change_per_building.resources_changes.get(
				key
			)
			_show_resource_change(
				key,
				value,
				change_per_building.production_building.global_position,
				offset_limit,
			)
	

func _on_EventBus_ask_demolish_current_building() -> void:
	# Info: destroy / demolish / remove / delete building
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
	
	# Call the observer
	ECS.world.emit_event(
		ECSEvents.BUILDING_IS_BEING_REMOVED,
		selected_building,
		{
			
		}
	)
	
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
	
	event_bus_emit_send_minimap_data_changed.call_deferred()
	

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
		if cost.resource == Resources.Types.Gold:
			if local_player_c_faction.gold_count >= cost.cost:
				continue
			has_resources = false
			break
		
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
	#audio_player.play_invalid_construction()

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
		_show_resource_change(
			Resources.Types.Gold,
			dock_changes.gold_change,
			dock.global_position,
			offset_limit,
		)
		
	if true:
		_show_resource_change(
			Resources.Types.Gold,
			ship_changes.gold_change,
			ship.global_position,
			offset_limit,
		)
	
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
		_show_resource_change(
			key,
			value,
			dock.global_position,
			offset_limit,
		)
	
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
		_show_resource_change(
			key,
			value,
			ship.global_position,
			offset_limit,
		)

func _on_LootSystem_loots_realized(loots: LootsPerFactionDef) -> void:
	print("_on_LootSystem_loots_realized")
	# TODO: could make it an option or a tech
	# to see other player's loots
	if !loots.changes.has(local_player_faction_index):
		return
	
	var offset_limit: int = 3
	
	var changes: Array[LootChangeDef] = loots.changes.get(
		local_player_faction_index
	)
	for change: LootChangeDef in changes:
		if change.change_def.gold_change > 0:
			# TODO: mutualize
			var value = change.change_def.gold_change
			_show_resource_change(
				Resources.Types.Gold,
				value,
				change.global_position,
				offset_limit,
			)
		
		for key in change.change_def.resources_changes.keys():
			# FIXME: if auto add to inventory is a thing
			#var quantity = local_player_storage.get_storage(key)
			#event_bus.send_resource_updated.emit(
				#key, quantity.quantity
			#)
			
			var value = change.change_def.resources_changes.get(
				key
			)
			_show_resource_change(
				key,
				value,
				change.global_position,
				offset_limit,
			)

func _show_resource_change(
	resource_id: int,
	value: int,
	position_: Vector3,
	offset_limit: int = 3,
):
	var instance: TradeExchangeSummaryFloatingUI3D = TRADE_EXCHANGE_SUMMARY_FLOATING_UI_3D.instantiate()
	var offset: Vector3 = Vector3(
		randi_range(-offset_limit, offset_limit),
		5,
		randi_range(-offset_limit, offset_limit),
	)
	instance.global_position = position_ + offset
	add_child(instance)
	var res_def: ResourceDefinition = resource_list_definition_dict.get(
		resource_id
	)
	# TODO: mutualize
	var value_as_str = ""
	if value > 0:
		value_as_str = "+" + str(value)
	elif value == 0:
		value_as_str = str(value)
	else:
		value_as_str = "-" + str(value)
	instance.set_content(
		res_def.normal_icon,
		value_as_str,
	)
	instance.start_tween()

func _on_event_bus_ask_change_ground_bed_resource_id(
	resource_id: int
):
	# FIXME: terrible
	var stages = production_system.resource_growth_stages_dict.get(
		resource_id
	)
	var c_slot_production: C_SlotProduction = selected_ground_bed_parent.get_component(
		C_SlotProduction
	)
	var slot = c_slot_production.slots.get(
		selected_ground_bed_id
	)
	slot.resource_id = resource_id
	slot.time = slot.production_time
	
	selected_ground_bed_parent.update_slot_progress(
		selected_ground_bed_id,
		0,
		stages,
	)
