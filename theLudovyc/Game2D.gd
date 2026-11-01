@tool
extends Node2D
class_name Game2D

const BUOY_2D_1 = preload("uid://5h8h5povuddd")

const TRADE_EXCHANGE_SUMMARY_FLOATING_UI_2D = preload("uid://cnqqefs5a1tsi")

# TODO: could be a bitflag or multiple enums
enum PopUnitImmigrationSystem {
	# Double everytime, otherwise it won't work
	SPAWN_WITH_BUILDING = 1,
	SPAWN_WITH_MAIN_SQUARE = 2,
}

@export_tool_button("List disabled systems")
var list_disabled_systems_action = list_disabled_systems

func list_disabled_systems() -> void:
	for child in world:
		if child is System:
			if child.active == false:
				print("Disabled: %s %s" % [
					child.name,
					child.get_path(),
				])

@export_category("ECS")

@export
var USE_ECS: bool = false

# TODO: load the proper map
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

@export
var initial_factions_list: FactionListDefinition

@export
var local_player_faction_index: int = 0

@export
var faction_storage_prefab: PackedScene

@export
var default_builtin_resources_space_weight_ref_def: BuiltinResourcesSpaceWeightRefList

@export
var default_basic_trade_system_prices: BuiltinTradePriceList

@export_flags_2d_physics
var physics_building_layers: int = 0

@export_category("Systems")

@export
var pop_unit_work_system: O_PopulationMovementObserver.POP_UNIT_WORK_SYSTEM = O_PopulationMovementObserver.POP_UNIT_WORK_SYSTEM.TIMER_BASED_HIDE_POP

@export
var pop_unit_home_idling_system: O_PopulationMovementObserver.POP_UNIT_HOME_IDLING_SYSTEM = O_PopulationMovementObserver.POP_UNIT_HOME_IDLING_SYSTEM.HIDE

@export_flags("With housing", "With main square")
var pop_unit_spawn_types: int = 0

@export
var jobless_leave_island_time: float = 30.0

@export
var looking_for_housing_leave_island_time: float = 30.0

@export_category("Debug")

@export
var enable_debug_display: bool = false

@export
var debug_display_names: bool = false


@onready var rtl := $CanvasLayer/RichTextLabel

@onready var tm := %TileMap

@onready var cam := $Camera2D

@onready var node_buildings := %Buildings

@onready var event_bus := $EventBus

@onready var audio_player: AudioPlayer = $AudioPlayer
@onready var ship_bell_audio_stream_player_2d: AudioStreamPlayer2D = $ShipBellAudioStreamPlayer2D

@onready var the_storage: TheStorage = %TheStorage
@onready var the_bank: TheBank = %TheBank
@onready var the_factory: TheFactory = %TheFactory
@onready var the_market: Node = %TheMarket
@onready var the_builder: Node = %TheBuilder
@onready var the_population: ThePopulation = %ThePopulation
@onready var the_cursor: TheCursor = %TheCursor
@onready var the_nature: TheNature = %TheNature
@onready var the_ticker: Timer = %TheTicker

# ECS
@onready var world: World = $ECS/World
@onready var o_population_movement_observer: O_PopulationMovementObserver = $ECS/World/Systems/gameplay/O_PopulationMovementObserver
@onready var population_misc_system: PopulationMiscSystem = $ECS/World/Systems/gameplay/PopulationMiscSystem
@onready var the_storages: Node = $ECS/TheStorages
@onready var ge_map_ship_spawner_2d: GE_MapShipSpawner2D = $ECS/World/GE_MapShipSpawner2D
@onready var faction_misc_system: FactionMiscSystem = $ECS/World/Systems/gameplay/FactionMiscSystem
@onready var o_faction_misc_observer: O_FactionMiscObserver = $ECS/World/Systems/gameplay/O_FactionMiscObserver
@onready var o_spawn_observer: O_SpawnObserver = $ECS/World/Systems/gameplay/O_SpawnObserver
@onready var o_ship_trading_observer: O_ShipTradingObserver = $ECS/World/Systems/gameplay/O_ShipTradingObserver
@onready var production_system: ProductionSystem = $ECS/World/Systems/gameplay/ProductionSystem
@onready var the_buildings_cost: TheBuildingsCost = %TheBuildingsCost
@onready var ge_pop_unit_spawner: GE_PopUnitSpawner = %GE_PopUnitSpawner

@onready var pay_system: PaySystem = $ECS/World/Systems/gameplay/PaySystem
@onready var feed_system: FeedSystem = $ECS/World/Systems/gameplay/FeedSystem
@onready var o_population_observer: O_PopulationObserver = $ECS/World/Systems/gameplay/O_PopulationObserver
@onready var o_building_added_observer: O_BuildingAddedObserver = $ECS/World/Systems/gameplay/O_BuildingAddedObserver
@onready var o_building_removed_observer: O_BuildingRemovedObserver = $ECS/World/Systems/gameplay/O_BuildingRemovedObserver
@onready var o_ship_misc_observer: O_ShipMiscObserver = $ECS/World/Systems/gameplay/O_ShipMiscObserver
#@onready var o_ship_trading_observer: O_ShipTradingObserver = $ECS/World/Systems/gameplay/O_ShipTradingObserver
@onready var navigation_system: NavigationSystem = $ECS/World/Systems/physics/NavigationSystem
@onready var loot_system: LootSystem = $ECS/World/Systems/physics/LootSystem

@onready var ground_layer: TileMapLayer = $ZSorter/TileMap/GroundLayer

@onready var gui := $GUI
@onready var pause_menu := %PauseMenu

# TODO : move this elsewhere
# plus checks, got exits etc
@onready var exits: Node2D = $Exits

# TODO: another system
@onready var ship_2d: Ship2D_ECS = $ZSorter/Ship2d

const Trees_Destroy_Cost = 1

var current_selected_building: Building2D = null

# ECS
var faction_entities: Array[Entity] = []
var local_player_faction: Faction_ECS
var local_player_c_faction: C_Faction
var local_player_storage: GMSimpleStorage
var city: Entity
var current_building_def: BuildingDefinition = null
var current_building: Entity
var current_island_for_building: Entity

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		return
	
	# Initialize this for the other nodes
	event_bus.send_use_ecs_changed.emit(
		USE_ECS
	)
	# TODO: hide it another way
	# FIXME: I could not remember how it's hidden in the 3D scene
	# => it was not
	event_bus.send_ground_bed_3D_deselected.emit(
		null,
		0,
		null,
	)
	
	event_bus.send_hide_build_position_rotation_ui.emit()
	
	# tm.create_island("res://theLudovyc/singularity_40.json")
	tm.create_minimap_from_gaea_layers()
	tm.clear_overlay()
	
	# set camera limits
	var pos_limits = tm.get_pos_limits()

	cam.pos_limit_top_left = pos_limits[0]
	cam.pos_limit_bot_right = pos_limits[1]
	
	#var warehouse_pos = Vector2.ZERO
	if USE_ECS:
		initialize_ecs()
	else:
		initialize_not_ecs()

func initialize_not_ecs():
	
	if SaveHelper.save_file_name_to_load.is_empty():
		# the_builder.build_warehouse(Vector2(704, 320))

		# add some initial resources
		the_bank.money = 500

		the_storage.add_resource(Resources.Types.Wood, 20)
		the_storage.add_resource(Resources.Types.Textile, 20)
		the_storage.add_resource(Resources.Types.Plank, 20)
		the_storage.add_resource(Resources.Types.Potato, 800)
		the_storage.add_resource(Resources.Types.Meat, 400)
		the_storage.add_resource(Resources.Types.ClayBrick, 50)
		the_storage.add_resource(Resources.Types.StoneBrick, 50)
	
	elif SaveHelper.load_saved_file_name() == OK:
		if SaveHelper.last_loaded_data.is_empty():
			return
			
		var game_data:Dictionary = SaveHelper.last_loaded_data.get("Game", {})
		
		if game_data.is_empty():
			return
		
		the_population.load_population_save()
		the_storage.load_storage_save()
		the_bank.load_bank_save()
		the_factory.load_factory_save()
		the_market.load_market_save()
		the_builder.load_buildings_save()
	else:
		# save cannot be loaded
		# TODO show popup and return to main menu
		return
	
	# force camera initial pos on warehouse
	if the_builder.warehouse:
		cam.position = the_builder.warehouse.global_position
	else:
		var rect = ground_layer.get_used_rect()
		var center = ground_layer.to_global(ground_layer.map_to_local(rect.get_center()))
		cam.position = center
	cam.reset_smoothing()
	
	pause_menu.visibility_changed.connect(_on_PauseMenu_visibility_changed)

func initialize_ecs():
	# FIXME: this is common
	var rect = ground_layer.get_used_rect()
	var center = ground_layer.to_global(ground_layer.map_to_local(rect.get_center()))
	cam.position = center
	cam.reset_smoothing()
	
	pause_menu.visibility_changed.connect(_on_PauseMenu_visibility_changed)

	Global.physics_building_layers_2d = physics_building_layers
	
	# TODO: we could have ECS ticker too
	the_ticker.stop()
	
	ECS.world = world
	
	StaticFactions.local_player_faction_id = local_player_faction_index
	
	#if enable_debug_display:
		#var instance = Node.new()
		#instance.set_script(MiscDebugSystem)
		#if instance is MiscDebugSystem:
			#print("Adding MiscDebugSystem")
			#instance.information_debug_scene = information_debug_scene
			#instance.group = "debug"
			#debug.add_child(instance)
			#ECS.world.add_system(instance)
	
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
	
	#ge_map_ship_spawner.initial_factions = initial_factions_list.factions
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
	
	ge_map_ship_spawner_2d.set_faction_entities(faction_entities)
	ge_map_ship_spawner_2d.default_basic_trade_system_prices = default_basic_trade_system_prices
	
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
	ge_map_ship_spawner_2d.set_default_builtin_resources_space_weight_ref_def(
		default_builtin_resources_space_weight_ref_def
	)
	
	# TODO: what to do in 2D
	if resource_growth_stages_array:
		production_system.set_resource_growth_stages_array(
			resource_growth_stages_array
		)
	else:
		push_warning("resource_growth_stages_array is null")
	
	#event_bus.ask_change_ground_bed_resource_id.connect(
		#_on_event_bus_ask_change_ground_bed_resource_id
	#)
	
	# TODO: other global_trades for factions
	# use the ref
	
	# TODO?
	#map = default_map.map_scene.instantiate()
	#add_child(map)
	
	event_bus.send_local_player_faction_id_changed.emit(
		local_player_faction_index,
	)
	
	city = Entity.new()
	city.add_component(C_City.new(
		"First city",
	))
	ECS.world.add_entity(city)
	
	# TODO: handle more than one
	current_island_for_building = Entity.new()
	current_island_for_building.add_components([
		#C_Transform.new(),
		C_PopulationSummary.new(),
	])
	ECS.world.add_entity(current_island_for_building)
	
	ship_2d.add_relationship(
		Rels.create_belongs_to_faction(
			local_player_faction
		)
	)
	ECS.world.add_entity(
		ship_2d
	)
	
	# More events
	bind_ecs_events()
	
	# TODO : instantiate a camera?
	
	event_bus.send_hide_build_position_rotation_ui.emit()
	
	event_bus.send_city_name_changed.emit("My First City")
	
	# FIXME: this will need to be defined in the map
	for exit in exits.get_children():
		if exit is Entity:
			ECS.world.add_entity(exit)
		else:
			push_error("exit is not an Entity")
	
	# TODO: adapt to 2D
	if building_list_definition == null:
		push_warning("building_list_definition is null")
	the_buildings_cost.set_costs(
		building_list_definition,
	)
	
	
	audio_player.start_in_game_music()
	
	#initialize_storage()
	
	# FIXME: don't remember why we do this but was necessary?
	await get_tree().create_timer(0.5).timeout
	
	# TODO : this?
	
	#call_deferred("finalize_existing_buildings")
	call_deferred("call_after_init_is_done")

func bind_ecs_events():
	production_system.produced_resources.connect(
		_on_ProductionSystem_produced_resources
	)
	
	pay_system.gold_count_changed.connect(
		_on_PaySystem_gold_count_changed
	)
	
	feed_system.consumed_resources.connect(
		_on_FeedSystem_consumed_resources
	)
	feed_system.island_population_changed.connect(
		_on_FeedSystem_island_population_changed
	)
	feed_system.pop_units_died.connect(
		_on_FeedSystem_pop_units_died
	)
	feed_system.workers_died.connect(
		_on_FeedSystem_workers_died
	)
	
	o_population_observer.new_pop_unit_joined.connect(
		_on_OPopulationObserver_new_pop_unit_joined
	)
	o_population_observer.pop_unit_found_work.connect(
		_on_OPopulationObserver_pop_unit_found_work
	)
	o_population_observer.pop_unit_left_work.connect(
		_on_OPopulationObserver_pop_unit_left_work
	)
	
	o_building_added_observer.housing_capacity_increased.connect(
		_on_OBuildingAddedObserver_housing_capacity_increased
	)
	o_building_added_observer.pop_unit_found_work.connect(
		_on_OBuildingAddedObserver_pop_unit_found_work
	)
	o_building_added_observer.workers_capacity_increased.connect(
		_on_OBuildingAddedObserver_workers_capacity_increased
	)
	
	o_building_removed_observer.housing_capacity_decreased.connect(
		_on_OBuildingRemovedObserver_housing_capacity_decreased
	)
	o_building_removed_observer.workers_capacity_decreased.connect(
		_on_OBuildingRemovedObserver_workers_capacity_decreased
	)
	
	o_ship_misc_observer.island_population_changed.connect(
		_on_OShipMiscObserver_island_population_changed
	)
	
	o_ship_trading_observer.exchange_realized.connect(
		_on_OShipTradingObserver_exchange_realized
	)
	
	navigation_system.ship_arrived_at_dock.connect(
		_on_NavigationSystem_ship_arrived_at_dock
	)
	
	loot_system.loots_realized.connect(
		_on_LootSystem_loots_realized
	)

func call_after_init_is_done():
	# TODO: only do this once ECS and everything has started
	
	# FIXME: should we have this?
	#TimeUtils.call_at_interval(
		#self,
		#0.1,
		#identify_node_below_mouse
	#)
	
	# Info: we have to do this after because UI is not init otherwise
	var local_c_faction: C_Faction = local_player_faction.get_component(
		C_Faction
	)
	
	event_bus.send_trades_updated.emit(
		local_c_faction.global_trades
	)
	
	#event_bus.send_local_player_faction_id_changed.emit(
		#local_player_faction_index,
	#)
	
	ECSEvents.emit_event(
		ECSEvents.SPAWN_ENTITIES_REQUESTED, null
	)
	
	var ships = ECS.world.query.with_all([
		C_Ship,
	]).execute()
	
	event_bus.send_all_ecs_ships_updated.emit(
		ships,
	)
	
	initialize_storage_ecs()

func initialize_storage_ecs():
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

# return [money_cost, [[Resources.Types, cost], ...]]
func get_building_total_cost(
	building_id: int,
	trees_to_destroy
) -> Array:
	var trees_to_destroy_final_cost := 0
	
	if trees_to_destroy > 0:
		trees_to_destroy_final_cost = trees_to_destroy * Trees_Destroy_Cost
	
	var building_cost = Buildings.get_building_cost(building_id).duplicate(true)
	
	if building_cost.is_empty():
		return [-trees_to_destroy_final_cost, []]
		
	for i in range(building_cost.size()):
		var cost = building_cost[i]
			
		cost[1] *= -1
			
		if trees_to_destroy > 0 and (cost[0] == Resources.Types.Wood):
			cost[1] += trees_to_destroy
	
	return [-trees_to_destroy_final_cost, building_cost]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return
	if pause_menu.visible == false and Input.is_action_just_pressed("ui_cancel"):
		pause_menu.show()
		pause_menu.set_process(true)
		get_tree().paused = true
	
	if USE_ECS:
		world.process(delta, 'gameplay')
		world.process(delta, 'debug')
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	var mouse_local_tilemap : Vector2 = tm.ground_layer.to_local(
		mouse_pos
	)
	var tile_pos : Vector2 = tm.ground_layer.local_to_map(
		mouse_local_tilemap
	)
	
	rtl.text = ""

	rtl.text += str(mouse_pos) + "\n"
	rtl.text += str(mouse_local_tilemap) + "\n"
	rtl.text += str(tile_pos) + "\n"
	rtl.text += str(cam.get_screen_center_position()) + "\n"
	
	var cell_type = tm.minimap_get_cell(tile_pos)
	var cell_name = MyMap.get_cell_type_name(cell_type)
	rtl.text += str(cell_type) + " " + cell_name + "\n"

	rtl.text += str(tm.is_constructible(tile_pos)) + "\n"

	var tile_data = tm.get_cell_tile_data(0, tile_pos)

	if tile_data != null:
		rtl.text += str(tile_data.terrain_set) + " / " + str(tile_data.terrain) + "\n"

		rtl.text += str(tm.get_cell_atlas_coords(0, tile_pos))
	
	#spawn entity
	if the_cursor.cursor_entity:
		the_cursor.cursor_entity.position = tm.ground_layer.map_to_local(
			tile_pos
		)
		
		var is_pos_visible: bool = true
		if USE_ECS:
			is_pos_visible = _physics_is_position_inside_discovered_area(
				mouse_pos
			)
			print("is_pos_visible: %s" % [
				is_pos_visible,
			])

		var building_id = the_cursor.cursor_entity.building_id
		var is_coastal = Buildings.get_is_coastal(building_id)
		var trees_to_destroy = 0
		if is_coastal:
			trees_to_destroy = handle_coastal_building(tile_pos)
		else:
			# FIXME : this probably uses a lot of performances
			# -1 can not build, 0 yes and 0 tree, 1+ yes and 1+ tree to destroy
			trees_to_destroy = tm.is_entityStatic_constructible(the_cursor.cursor_entity, tile_pos)
		
		# TODO: use ECS
		var max_range = Buildings.get_dependency_max_range(
			the_cursor.cursor_entity.building_id
		)
		if max_range != -1:
			tm.show_affected_area_of_building(
				the_cursor.cursor_entity,
				max_range
			)
		else:
			tm.show_area_of_building(the_cursor.cursor_entity)
		
		if trees_to_destroy < 0 or is_pos_visible == false:
			print("trees_to_destroy < 0 or is_pos_visible == false")
			the_cursor.cursor_entity.modulate = Color(Color.RED, 0.6)
			
			gui.set_rtl_visibility(false)
			
			if Input.is_action_just_pressed("left_click"):
				audio_player.play_invalid_construction()
		else:
			if !USE_ECS:
				handle_building_under_mouse_not_ecs(
					building_id,
					trees_to_destroy,
					tile_pos
				)
			else:
				handle_building_under_mouse_ecs(
					building_id,
					trees_to_destroy,
					tile_pos,
					is_pos_visible,
				)
			

		if the_cursor.cursor_entity_wait_release and Input.is_action_just_released("left_click"):
			the_cursor.cursor_entity_wait_release = false

		if the_cursor.cursor_entity and Input.is_action_just_pressed("right_click"):
			cancel_construction(building_id)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if USE_ECS:
		world.process(delta, 'physics')

# FIXME: don't really need building_id as a parameter?
func cancel_construction(
	building_id: int,
):
	gui.set_rtl_visibility(false)

	# deselect
	event_bus.send_building_creation_aborted.emit(building_id)

	the_cursor.cursor_entity.call_deferred("queue_free")
	the_cursor.cursor_entity = null
	
	tm.clear_overlay()

func handle_building_under_mouse_not_ecs(
	building_id: int,
	trees_to_destroy: int,
	tile_pos: Vector2
):
	var building_total_cost = get_building_total_cost(building_id, trees_to_destroy)

	# TODO: is it red if we don't have the resources?
	if (
		(building_total_cost[0] >= 0 or
		(building_total_cost[0] < 0 and abs(building_total_cost[0]) < the_bank.money))
		and the_storage.has_resources_to_construct_building(building_total_cost[1])
	):
		gui.set_rtl_info_buiding_info(building_total_cost)
		gui.set_rtl_visibility(true)
		
		if trees_to_destroy > 0:
			the_cursor.cursor_entity.modulate = Color(Color.ORANGE, 0.6)
		else:
			the_cursor.cursor_entity.modulate = Color(Color.GREEN, 0.6)

		if (
			not the_cursor.cursor_entity_wait_release
			# This is left click
			and Input.is_action_just_pressed("left_click")
		):
			build_building_not_ecs(
				building_id,
				building_total_cost,
				tile_pos,
			)

func build_building_not_ecs(
	building_id: int,
	building_total_cost: Array,
	tile_pos: Vector2
):
	match Buildings.get_building_type(building_id):
		Buildings.Types.Residential:
			var amount := Buildings.get_max_workers(building_id)
			var population_type := Buildings.get_population_type((building_id))
			
			the_population.population_increase(population_type, amount)

			the_factory.population_increase(population_type, amount)

		Buildings.Types.Producing:
			the_factory.add_workers(
				Buildings.get_population_type(building_id),
				Buildings.get_produce_resource(building_id),
				Buildings.get_max_workers(building_id)
			)
	
	the_bank.money += building_total_cost[0]

	the_storage.conclude_building_construction(building_total_cost[1])
	the_builder.conclude_building_construction(the_cursor.cursor_entity)
	the_nature.conclude_building_construction(
		the_cursor.cursor_entity,
		tile_pos
	)

	event_bus.send_building_created.emit(building_id)

	tm.build_entityStatic(the_cursor.cursor_entity, tile_pos)

	gui.set_rtl_visibility(false)

	the_cursor.cursor_entity.modulate = Color.WHITE
	the_cursor.cursor_entity.build()
	the_cursor.cursor_entity = null
	
	tm.clear_overlay()

func handle_building_under_mouse_ecs(
	building_id: int,
	trees_to_destroy: int,
	tile_pos: Vector2,
	is_pos_visible: bool,
):
	#gui.set_rtl_info_buiding_info(building_total_cost)
	gui.set_rtl_visibility(true)
	
	if trees_to_destroy > 0:
		the_cursor.cursor_entity.modulate = Color(Color.ORANGE, 0.6)
	else:
		the_cursor.cursor_entity.modulate = Color(Color.GREEN, 0.6)
	
	if (
			not the_cursor.cursor_entity_wait_release
			# This is left click
			and Input.is_action_just_pressed("left_click")
		):
			try_build_building_ecs(
				building_id,
				tile_pos,
			)

func try_build_building_ecs(
	building_id: int,
	tile_pos: Vector2
):
	var has_resources = has_resources_to_construct_building(
		current_building_def
	)
	
	if !has_resources:
		print("audio_player.play_invalid_construction()")
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
	
	#the_bank.money += building_total_cost[0]
	#the_storage.conclude_building_construction(building_total_cost[1])
	
	the_builder.conclude_building_construction(the_cursor.cursor_entity)
	the_nature.conclude_building_construction(
		the_cursor.cursor_entity,
		tile_pos
	)

	event_bus.send_building_created.emit(building_id)

	tm.build_entityStatic(the_cursor.cursor_entity, tile_pos)

	gui.set_rtl_visibility(false)
	
	if current_building.has_method("set_visual_node"):
		current_building.set_visual_node(the_cursor.cursor_entity)
	else:
		push_error("building needs method set_visual_node")
	the_cursor.cursor_entity.set_entity_node(
		current_building
	)

	the_cursor.cursor_entity.modulate = Color.WHITE
	the_cursor.cursor_entity.build()
	#the_cursor.cursor_entity = null
	
	tm.clear_overlay()
	
	print("adding building to ECS world")
	#var current_building: Entity = Entity.new()
	
	var buildings = ECS.world.query.with_all(
		[C_Transform])\
		.with_relationship([Rels.create_belongs_to(city)])\
		.execute()
	match building_id:
		Buildings.Ids.Tent, \
		Buildings.Ids.Hut, \
		Buildings.Ids.House, \
		Buildings.Ids.StoneHouse:
			# TODO: implement this
			var found_a_main_square = false
			for building: Entity in buildings:
				if building.has_component(C_MainSquare):
					if building.has_component(C_Range):
						var trans: C_Transform2D = building.get_component(C_Transform2D)
						var range_: C_Range = building.get_component(C_Range)
						var dist = current_building.global_position.distance_to(
							trans.transform.origin
						)
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
		Buildings.Ids.HunterTent, \
		Buildings.Ids.MainSquare, \
		Buildings.Ids.ClayPit, \
		Buildings.Ids.Brickyard, \
		Buildings.Ids.StonePit, \
		Buildings.Ids.Weaver, \
		Buildings.Ids.Stonemason, \
		Buildings.Ids.Windmill, \
		Buildings.Ids.Bakery:
			pass
		
		Buildings.Ids.Farm:
			pass
		
		Buildings.Ids.Pasture:
			# Info: we need to be an extension for the ECS production to work
			# TODO: do we use this?
			var farm_like_buildings = ECS.world.query.with_all([
				C_CanExtendFarm,
				C_RangeBox,
				])\
				.with_relationship([
					Rels.create_belongs_to_faction(local_player_faction)
				])\
				.execute()
			
			var building_: Node2D = current_building as Variant as Node2D
			for building: Entity in farm_like_buildings:
				var farm_like_: Node2D = building as Variant as Node2D
				
				var c_range_box: C_RangeBox = building.get_component(
					C_RangeBox
				)
				
				var oriented_rect: OrientedRect2 = OrientedRect2.new(
					Vector2(farm_like_.global_position.x, farm_like_.global_position.y),
					Vector2(c_range_box.size.x, c_range_box.size.z),
					#45,
					farm_like_.rotation_degrees,
				)
				
				oriented_rect._debug_points(
					1,
					30
				)
				
				var is_in = oriented_rect.is_point_inside(
					Vector2(
						building_.global_position.x,
						building_.global_position.y
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
				building_id
			)
			printerr("building of id not handled: %s %s" % [
				building_id,
				name_,
			])
	
	current_building.add_relationship(
		Rels.create_belongs_to_faction(
			local_player_faction
		)
	)
	
	current_building.global_position = the_cursor.cursor_entity.global_position
	
	ECS.world.add_entity(current_building, null, true)
	#ECS.world.add_entity(current_building, null, false)
	
	# add sub entities
	
	# Info: we don't have components before it's added to the world
	match building_id:
		Buildings.Ids.Tent,\
		Buildings.Ids.House,\
		Buildings.Ids.StoneHouse:
			# Info: we have to do this before adding the building to the world
			# otherwise we modify the archetype
			#print("building is tent or house or stonehouse")
			if pop_unit_spawn_types & PopUnitImmigrationSystem.SPAWN_WITH_BUILDING:
				print("spawning population")
				ECS.world.emit_event(
					ECSEvents.SPAWN_POP_UNITS_REQIESTED, 
					current_building,
					{
						"island": current_island_for_building,
						# TODO: should be predictive if possible
						"nationality": local_player_c_faction.def.nationalities.pick_random(),
						"faction": local_player_faction,
					}
				)
				
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
			var buoy: Entity = BUOY_2D_1.instantiate()
			buoy.add_relationship(
				Rels.create_belongs_to(current_building)
			)
			buoy.add_relationship(
				Rels.create_belongs_to_faction(
					local_player_faction
				)
			)
			# Info: need negative numbers because Godot has reversed order
			# Compared to mathematics
			# It's anticlockwise, 0 is RIGHT
			# We need additional offset because the buildings are not centered
			# Maybe it should be fixed somewhat
			# FIXME: could cache this
			var offset: float = 0
			var angle: float = 0
			var additional_offset: Vector2 = Vector2.ZERO
			match the_cursor.cursor_entity.face_direction:
				Building2D.FaceDirection.NorthEast:
					angle = deg_to_rad(-45.0)
					offset = 110
				Building2D.FaceDirection.NorthWest:
					angle = deg_to_rad(-135.0)
					offset = 110
				Building2D.FaceDirection.SouthWest:
					angle = deg_to_rad(-225.0)
					offset = 75
					additional_offset = Vector2.from_angle(-135.0).normalized() * 50
				Building2D.FaceDirection.SouthEast:
					angle = deg_to_rad(-315.0)
					offset = 110
					additional_offset = Vector2.from_angle(-45.0).normalized() * 50
				_:
					push_error("unknown face_direction")
			
			var direction = Vector2.from_angle(angle).normalized()
			
			var position = the_cursor.cursor_entity.position + direction * offset + additional_offset
			
			buoy.global_position = position
			
			ECS.world.add_entity(buoy)
			
		Buildings.Ids.MainSquare:
			pass
		Buildings.Ids.Farm:
			pass
			# TODO?
			#current_building.hide_indicators()
		Buildings.Ids.Pasture:
			pass
			# TODO?
			#current_building.hide_indicators()
		_:
			print("current_building_id:", building_id)
	
	ECS.world.emit_event(
		ECSEvents.GENERIC_BUILDING_ADDED, 
		current_building,
		{
			"island": current_island_for_building,
			"faction": local_player_faction,
		}
	)
	
	the_cursor.cursor_entity = null
	
	# Info: this allows to be able to click on the building creation button again
	# FIXME: maybe do not disable the button, not sure why this is done
	event_bus.send_building_created.emit(building_id)
	
	#if current_building.has_method("finalize_construction"):
		#current_building.finalize_construction()
	#else:
		#printerr("building does not have method finalize_construction")
	
	#if current_building.has_method("add_children_entities"):
		#current_building.add_children_entities()
	
	#if current_building.has_method("update_minimap_display"):
		#current_building.update_minimap_display.call_deferred()
	
	# FIXME: is this buggy?
	#current_building_def = null
	#current_island_for_building = null
	
	#rtsCamera.changing_distance_enabled = true
	
	audio_player.play_valid_construction()
	
	event_bus_emit_send_minimap_data_changed.call_deferred()
	
	event_bus.send_hide_build_position_rotation_ui.emit()

func _physics_is_position_inside_discovered_area(
	world_position: Vector2
):
	var circle := CircleShape2D.new()
	circle.radius = 25.0

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, world_position)
	query.collision_mask = physics_building_layers
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query)

	if hits.is_empty():
		return false
	else:
		return true

func event_bus_emit_send_minimap_data_changed():
	event_bus.send_minimap_data_changed.emit()


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

func handle_coastal_building(tile_pos: Vector2i) -> int:
	# x is up right / north east
	# y is down right / south east
	var top_left_tile = tm.entityStatic_get_top_left_tile(the_cursor.cursor_entity, tile_pos)
	var cell_type = MyMap.Minimap_Cell_Type.Shallow
	#tm.color_red_at_pos(top_left_tile)
	if tm.minimap_get_cell(top_left_tile) == cell_type:
		# visually top
		var top_offset = Vector2i(the_cursor.cursor_entity.width - 1, 0)
		# visually bottom
		var bottom_offset = Vector2i(0, the_cursor.cursor_entity.height - 1)
		if tm.minimap_get_cell(top_left_tile + top_offset) == cell_type:
			# north west
			the_cursor.cursor_entity.switch_to_north_west_texture()
		elif tm.minimap_get_cell(top_left_tile + bottom_offset) == cell_type:
			# south west
			the_cursor.cursor_entity.switch_to_south_west_texture()
		else:
			return -1
	else:
		var offset = Vector2i(
			the_cursor.cursor_entity.width - 1,
			the_cursor.cursor_entity.height - 1
		)
		# visually right
		var right_tile = top_left_tile + offset
		if tm.minimap_get_cell(right_tile) == cell_type:
			# visually top
			var top_offset = Vector2i(the_cursor.cursor_entity.width - 1, 0)
			# visually bottom
			var bottom_offset = Vector2i(0, the_cursor.cursor_entity.height - 1)
			if tm.minimap_get_cell(top_left_tile + top_offset) == cell_type:
				# north east
				the_cursor.cursor_entity.switch_to_north_east_texture()
			elif tm.minimap_get_cell(top_left_tile + bottom_offset) == cell_type:
				# south east
				the_cursor.cursor_entity.switch_to_south_east_texture()
			else:
				return -1
		else:
			return -1
	
	var trees_to_destroy = tm.is_coastal_entity_constructible(
		the_cursor.cursor_entity,
		top_left_tile
	)
		
	return trees_to_destroy

func _on_EventBus_ask_create_building(building_id: Buildings.Ids):
	if USE_ECS:
		_handle_create_building_ecs(building_id)
	else:
		_handle_create_building_not_ecs(building_id)
	
func _handle_create_building_not_ecs(building_id: Buildings.Ids):
	the_cursor.cursor_entity = the_builder.instantiate_building(building_id)
	the_cursor.cursor_entity_wait_release = true
	the_cursor.cursor_entity.modulate = Color(Color.RED, 0.6)
	
	tm.show_constructible_area_on_overlay(building_id)
	
func _handle_create_building_ecs(building_id: Buildings.Ids):
	#if current_building:
		#cancel_build_current_building()
	
	if !building_list_definition.builtin_buildings.has(building_id):
		if !building_list_definition.extra_buildings.has(building_id):
			var building_name = Buildings.get_building_name(
				building_id
			)
			printerr("game_2d: building is not present %s %s" % [
				building_id,
				building_name,
			])
			audio_player.play_invalid_construction()
			#event_bus.send_building_creation_aborted.emit(building_id)
			#event_bus.send_show_buildings_button_ui.emit()
			return
		current_building_def = building_list_definition.extra_buildings.get(building_id)
	else:
		current_building_def = building_list_definition.builtin_buildings.get(building_id)
	
	if current_building_def == null:
		push_error("current_building_def is null")
		audio_player.play_invalid_construction()
		return
	
	# TODO: should not be allowed but don't need it here
	#if current_building_def.scene == null:
		#push_error("scene of building definition is null for %s" % [
			#building_id
		#])
		#audio_player.play_invalid_construction()
		##event_bus.send_building_creation_aborted.emit(building_id)
		##event_bus.send_show_buildings_button_ui.emit()
		#return
	
	if current_building_def.scene_2d == null:
		var building_name = Buildings.get_building_name(
			building_id
		)
		printerr("current_building_def.scene_2d is null %s %s" % [
			building_id,
			building_name,
		])
		return
	
	if !has_resources_to_construct_building(current_building_def):
		audio_player.play_invalid_construction()
		# FIXME: without this it won't allow us to click back on button
		#event_bus.send_building_creation_aborted.emit(building_id)
		#event_bus.send_show_buildings_button_ui.emit()
		return
	
	#freeze_building_location = false
	
	current_building = current_building_def.scene_2d.instantiate()
	
	if current_building == null:
		push_error("current_building is null")
		audio_player.play_invalid_construction()
		return
	
	the_cursor.cursor_entity = the_builder.instantiate_building(building_id)
	the_cursor.cursor_entity_wait_release = true
	the_cursor.cursor_entity.modulate = Color(Color.RED, 0.6)
	
	tm.show_constructible_area_on_overlay(building_id)
	

func _on_EventBus_send_building_selected(building_node):
	current_selected_building = building_node


func _on_EventBus_ask_deselect_building():
	if current_selected_building != null:
		current_selected_building.deselect()
		current_selected_building = null

func _on_EventBus_ask_select_warehouse():
	if the_builder.warehouse:
		current_selected_building = the_builder.warehouse
		
		the_builder.warehouse.select()

# Remove, delete, destroy
func _on_EventBus_ask_demolish_current_building():
	print("_on_EventBus_ask_demolish_current_building")
	if USE_ECS:
		demolish_current_building_ecs()
	else:
		demolish_current_building_not_ecs()

func demolish_current_building_not_ecs():
	tm.demolish_building(current_selected_building)

	var building_id = current_selected_building.building_id
	var tile_pos = tm.ground_layer.local_to_map(
		tm.ground_layer.to_local(current_selected_building.global_position)
	)

	the_storage.recover_building_construction(building_id)
	
	the_builder.conclude_building_destruction(building_id)
	
	the_nature.conclude_building_destruction(
		current_selected_building, tile_pos
	)
	
	var dependencies: Array[Building2D] = []
	var max_range = Buildings.get_dependency_max_range(building_id)

	match Buildings.get_building_type(building_id):
		Buildings.Types.Residential:
			var amount := Buildings.get_max_workers(building_id)
			var population_type := Buildings.get_population_type(building_id)

			the_population.population_decrease(population_type,amount)

			the_factory.population_decrease(population_type,amount)

		Buildings.Types.Producing:
			the_factory.rem_workers(
				Buildings.get_population_type(building_id),
				Buildings.get_produce_resource(building_id),
				Buildings.get_max_workers(building_id)
			)
			
			if max_range != -1:
				var deps = Buildings.get_building_dependencies(building_id)
				dependencies = the_builder.get_building_dependencies(
					current_selected_building,
					max_range,
					deps
				)
		_:
			pass

	node_buildings.remove_child(current_selected_building)
	current_selected_building.queue_free()
	current_selected_building = null
	
	# FIXME : maybe this should be done elsewhere
	# But, the building needs to have been removed first
	if dependencies.size() > 0:
		var existing_buildings = the_builder.get_buildings_of_id(building_id)
		if existing_buildings.size() == 0:
			for dep in dependencies:
				the_factory.rem_workers(
					Buildings.get_population_type(dep.building_id),
					Buildings.get_produce_resource(dep.building_id),
					Buildings.get_max_workers(dep.building_id)
				)
				dep.show_production_stoppped_indicator()
		else:
			var polygons: Array[Array] = []
			for _building in existing_buildings:
				var polygon = tm.get_polygon_range_of_building(_building, max_range)
				polygons.push_back(polygon)
			for dep in dependencies:
				var tile_center = tm.ground_layer.local_to_map(tm.ground_layer.to_local(dep.global_position))
				var top_left_tile = tm.entityStatic_get_top_left_tile(dep, tile_center)
				var is_in_range = tm.is_in_range_of_allowed_polygons(
					dep, polygons, top_left_tile
				)
				if !is_in_range:
					the_factory.rem_workers(
						Buildings.get_population_type(dep.building_id),
						Buildings.get_produce_resource(dep.building_id),
						Buildings.get_max_workers(dep.building_id)
					)
					dep.show_production_stoppped_indicator()

	event_bus.send_current_building_demolished.emit()

func demolish_current_building_ecs():
	print("demolish_current_building_ecs")
	# This put back the right ground tile
	tm.demolish_building(current_selected_building)
	
	var entity: Entity = current_selected_building.get_entity_node()
	if entity == null:
		push_error("entity from get_entity_node() is null")
	
	entity.set_visual_node(null)
	
	# This erase the node
	node_buildings.remove_child(current_selected_building)
	current_selected_building.queue_free()
	current_selected_building = null
	
	# FIXME: this is mostly duplicated from Game3D
	# But not quite
	# I'm not sure of what to do with this
	
	entity.enabled = false
	
	# FIXME: if there is a disconnect, this could break
	var c_housing: C_HousingCapacity = entity.get_component(C_HousingCapacity)
	if c_housing and c_housing.current > 0:
		var pop_units = ECS.world.query\
			#.with_all([C_PopUnit])\
			.with_relationship([Rels.create_lives_in(entity)])\
			.execute()\
			.duplicate()
		if !pop_units.is_empty():
			#o_population_observer.find_and_assign_housing_to_pop_units(
				#pop_units,
				#selected_building,
			#)
			ECS.world.emit_event(
				ECSEvents.HOUSING_BUILDING_REASSIGN_POP_UNITS_REQUESTED,
				entity,
				{
					"pop_units": pop_units,
				}
			)
		else:
			printerr("could not find pop_units")
			pass
	
	var c_production: C_Production = entity.get_component(C_Production)
	if c_production:
		var pop_units = ECS.world.query\
			#.with_all([C_PopUnit])\
			.with_relationship([Rels.create_works_at(entity)])\
			.execute()\
			.duplicate()
		if !pop_units.is_empty():
			#o_population_observer.find_and_assign_production_building_to_pop_units(
				#pop_units,
				#selected_building,
			#)
			ECS.world.emit_event(
				ECSEvents.PRODUCTION_BUILDING_REASSIGN_POP_UNITS_REQUESTED,
				entity,
				{
					"pop_units": pop_units,
				}
			)
		else:
			print("building %s does not have workers" % [
				entity.name,
			])
	
	# Call the observer
	ECS.world.emit_event(
		ECSEvents.BUILDING_IS_BEING_REMOVED,
		entity,
		{
			
		}
	)
	
	ECS.world.remove_entity(entity)
	entity = null
	
	event_bus.send_current_building_demolished.emit()
	
	event_bus_emit_send_minimap_data_changed.call_deferred()

func identify_node_below_mouse():
	push_error("not implemented")

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
	print("Game2D:_on_OPopulationObserver_new_pop_unit_joined")
	if island == current_island_for_building:
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
	if island == current_island_for_building:
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

func _on_OBuildingAddedObserver_pop_unit_found_work(
	pop_type: int,
	island: Entity
) -> void:
	_handle_pop_unit_found_work(
		pop_type,
		island,
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
	if island == current_island_for_building:
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
	if island == current_island_for_building:
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
	if island == current_island_for_building:
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

func _on_OBuildingRemovedObserver_housing_capacity_decreased(
	pop_type: int,
	amount: int,
	island: Entity
) -> void:
	if island == current_island_for_building:
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
	if island == current_island_for_building:
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

func notify_summary_changed():
	if current_island_for_building:
		var summary: C_PopulationSummary = current_island_for_building.get_component(
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
		var c_island: C_Island = current_island_for_building.get_component(C_Island)
		if c_island:
			event_bus.send_city_name_changed.emit(
				c_island.island_name,
			)
			event_bus.send_mouse_over_object_changed.emit(
				c_island.island_name,
				current_island_for_building,
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

#region "ECS events"

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
	
	#print("showing production")
	
	var offset_limit_minus_x: int = 40
	var offset_limit_plus_x: int = 30
	
	for change_per_building: ProductionChangeDef in changes.list:
		if change_per_building.gold_change != 0:
			_show_resource_change(
				Resources.Types.Gold,
				change_per_building.gold_change,
				change_per_building.production_building.global_position,
				offset_limit_minus_x,
				offset_limit_plus_x,
			)
		for key in change_per_building.resources_changes.keys():
			var value = change_per_building.resources_changes.get(
				key
			)
			_show_resource_change(
				key,
				value,
				change_per_building.production_building.global_position,
				offset_limit_minus_x,
				offset_limit_plus_x,
			)
	

func _on_NavigationSystem_ship_arrived_at_dock(
	_ship: Entity,
	dock: Entity
) -> void:
	# TODO: find another sound
	ship_bell_audio_stream_player_2d.global_position = dock.global_position
	ship_bell_audio_stream_player_2d.play()
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
		if island == current_island_for_building:
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
	if island == current_island_for_building:
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
	
	var offset_limit_minus_x: int = 20
	var offset_limit_plus_x: int = 30
	
	# TODO: mutualize
	if true:
		_show_resource_change(
			Resources.Types.Gold,
			dock_changes.gold_change,
			dock.global_position,
			offset_limit_minus_x,
			offset_limit_plus_x,
		)
		
	if true:
		_show_resource_change(
			Resources.Types.Gold,
			ship_changes.gold_change,
			ship.global_position,
			offset_limit_minus_x,
			offset_limit_plus_x,
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
			offset_limit_minus_x,
			offset_limit_plus_x,
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
			offset_limit_minus_x,
			offset_limit_plus_x,
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
			push_error("not implemented")
			# TODO: 2D version
			# TODO: mutualize
			#var value = change.change_def.gold_change
			#var instance: TradeExchangeSummaryFloatingUI2D = TRADE_EXCHANGE_SUMMARY_FLOATING_UI_2D.instantiate()
			#var offset: Vector2 = Vector2(
				#randi_range(-offset_limit, offset_limit),
				#5,
			#)
			#instance.global_position = change.global_position + offset
			#add_child(instance)
			#var res_def: ResourceDefinition = resource_list_definition_dict.get(
				#Resources.Types.Gold,
			#)
			#instance.set_content(
				#res_def.normal_icon,
				#"+" + str(value),
			#)
			#instance.start_tween()
		
		for key in change.change_def.resources_changes.keys():
			push_error("not implemented")
			# FIXME: if auto add to inventory is a thing
			#var quantity = local_player_storage.get_storage(key)
			#event_bus.send_resource_updated.emit(
				#key, quantity.quantity
			#)
			
			#var value = change.change_def.resources_changes.get(
				#key
			#)
			# TODO
			#var instance: TradeExchangeSummaryFloatingUI2D = TRADE_EXCHANGE_SUMMARY_FLOATING_UI_2D.instantiate()
			#var offset: Vector2 = Vector2(
				#randi_range(-offset_limit, offset_limit),
				#5,
			#)
			#instance.global_position = change.global_position + offset
			#add_child(instance)
			#var res_def: ResourceDefinition = resource_list_definition_dict.get(
				#key
			#)
			#instance.set_content(
				#res_def.normal_icon,
				#"+" + str(value),
			#)
			#instance.start_tween()

func _show_resource_change(
	resource_id: int,
	value: int,
	position_: Vector2,
	offset_limit_minus_x: int = 40,
	offset_limit_plus_x: int = 30,
	offset_y: float = -20
):
	#print("_show_resource_change %s %s %s %s %s %s" % [
		#resource_id,
		#value,
		#position_,
		#offset_limit_minus_x,
		#offset_limit_plus_x,
		#offset_y,
	#])
	var instance: TradeExchangeSummaryFloatingUI2D = TRADE_EXCHANGE_SUMMARY_FLOATING_UI_2D.instantiate()
	var offset: Vector2 = Vector2(
		randi_range(-offset_limit_minus_x, offset_limit_plus_x),
		offset_y,
	)
	instance.global_position = position_ + offset
	add_child(instance)
	var res_def: ResourceDefinition = resource_list_definition_dict.get(
		resource_id
	)
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

#endregion

#region "Pause"

func _on_PauseMenu_ask_to_save() -> void:
	var dicoToSave := {
		"Game": {}
	}
	
	dicoToSave.merge(the_population.get_population_save())
	dicoToSave.merge(the_storage.get_storage_save())
	dicoToSave.merge(the_bank.get_bank_save())
	dicoToSave.merge(the_factory.get_factory_save())
	dicoToSave.merge(the_market.get_market_save())
	dicoToSave.merge(the_builder.get_buildings_save())
	
	pause_menu.save_this_please(dicoToSave)

func _on_PauseMenu_visibility_changed():
	if pause_menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED

#endregion
