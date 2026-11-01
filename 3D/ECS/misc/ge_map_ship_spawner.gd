extends Node3D
class_name GE_MapShipSpawner

# Info: GE is for GodotEconomics

@export
var is_timer_enabled: bool = true

@export var simultaneous_ship_max_count: int = 5

@export var spawn_ship_timer: float = 10.0

@export var visited_docks_per_ship_min_count: int = 2

@export var visited_docks_per_ship_max_count: int = 5

@export var ship_container: Node3D

@export var entries_containers: Array[Node3D] = []

@export var ship_definitions: Array[GE_TravellingShipDefinition] = []

# FIXME: is not used
# Instead we are using faction_entities
@export
var initial_factions: Array[FactionDef] = []

@export
var default_ship_resources_spawn: Array[TravellingShipResourceSpawnDefinition] = []

@export
var default_basic_trade_system_prices: BuiltinTradePriceList

@export_category("Pop units")

@export
var pop_unit_spawner: GE_PopUnitSpawner

var entries: Array[Node3D] = []

var faction_entities: Array[Entity] = []

var neutral_faction_entities: Array[Entity] = []

var timer: Timer

var default_ship_resources_spawn_weights: Array[float] = []

var default_builtin_resources_space_weight_ref_def: BuiltinResourcesSpaceWeightRefList

var space_weight_red_def_dict: Dictionary[int, BuiltinResourceSpaceWeightRefDef] = {}

var disabled_physics_space_rid: RID

var event_bus: EventBus

func _ready() -> void:
	if get_tree().current_scene.has_node("EventBus"):
		event_bus = get_tree().current_scene.get_node("EventBus")
	
	for container in entries_containers:
		for entry in container.get_children():
			entries.push_back(entry)
			
	for resource_spawn in default_ship_resources_spawn:
		default_ship_resources_spawn_weights.push_back(
			resource_spawn.weight,
		)
	
	if !timer:
		timer = Timer.new()
		timer.wait_time = spawn_ship_timer
		timer.name = "timer"
		timer.timeout.connect(_on_timer_timeout)
		add_child(timer)
	if is_timer_enabled:
		timer.start()
	
	# Info: I think it does something but not sure
	disabled_physics_space_rid = PhysicsServer3D.space_create()
	PhysicsServer3D.space_set_active(
		disabled_physics_space_rid,
		false,
	)

func _on_timer_timeout():
	print("GE_MapShipSpawner:_on_timer_timeout")
	if is_timer_enabled == false:
		return
	try_spawn_ship()

func try_spawn_ship():
	if ship_container.get_child_count() >= simultaneous_ship_max_count:
		print("too many ships")
		return
	
	var docks = ECS.world.query.with_all([
		C_DockBuoy
	]).execute()
	
	if docks.is_empty():
		print("no docks found")
		return
	
	print("spawning ship")
	
	var def = ship_definitions.pick_random()
	
	# TODO: make it an option
	var faction: Entity = neutral_faction_entities.pick_random()
	var c_faction: C_Faction = faction.get_component(
		C_Faction
	)
	
	var ship: Entity = def.scene.instantiate()
	ship.name = "ship_%s" % [
		ship_container.get_child_count(),
	]
	
	var nationality: Nationality
	if c_faction.def.nationalities.size() > 1:
		nationality = c_faction.def.nationalities.pick_random()
	else:
		nationality = c_faction.def.nationalities[0]
	
	var population: int = 0
	if def.forced_population_count >= 0:
		population = def.forced_population_count
	else:
		population = randi_range(
			def.population_min_capacity,
			def.population_max_capacity,
		)
	
	var docks_to_visit: int = randi_range(
		visited_docks_per_ship_min_count,
		visited_docks_per_ship_max_count,
	)
	
	# TODO: implement max storage
	var c_storage: C_CargoStorage = C_CargoStorage.new(
		randi_range(50, 100),
		50,
		50,
	)
	if c_storage.max_space <= 0 or c_storage.max_weight <= 0:
		print("c_storage weight or space is <= 0")
	var resources_count: int = randi_range(
		3, 10
	)
	# FIXME: fix the rng
	# Everything should depend on one seed
	# Be reproducible
	var rng = RandomNumberGenerator.new()
	for i in resources_count:
		var res = default_ship_resources_spawn[
			rng.rand_weighted(default_ship_resources_spawn_weights)
		]
		var count = randi_range(
			res.random_quantity_min,
			res.random_quantity_max,
		)
		
		var weight_space_ref: BuiltinResourceSpaceWeightRefDef = space_weight_red_def_dict.get(
			res.builtin_resource,
		)
		if c_storage.space + weight_space_ref.space_per_quantity \
			> c_storage.max_space:
				continue
		
		if c_storage.weight + weight_space_ref.weight_per_quantity \
			> c_storage.max_weight:
				continue
		
		for j in count:
			if c_storage.space + weight_space_ref.space_per_quantity \
				> c_storage.max_space:
					continue
			
			if c_storage.weight + weight_space_ref.weight_per_quantity \
				> c_storage.max_weight:
					continue
			
			# FIXME : find a way to optimize it
			if c_storage.storage.has(res.builtin_resource):
				# TODO: a method inside C_Storage?
				var res_def: CargoResourceStorageDef = c_storage.storage.get(
					res.builtin_resource
				)
				res_def.quantity += 1
				res_def.weight += weight_space_ref.weight_per_quantity
				res_def.space += weight_space_ref.space_per_quantity
			else:
				var res_def: CargoResourceStorageDef = CargoResourceStorageDef.new()
				res_def.item_id = res.builtin_resource
				res_def.quantity = 1
				res_def.weight = weight_space_ref.weight_per_quantity
				res_def.space = weight_space_ref.space_per_quantity
				
				res_def.weight_per_quantity = weight_space_ref.weight_per_quantity
				res_def.space_per_quantity = weight_space_ref.space_per_quantity
				
				c_storage.storage.set(
					res_def.item_id,
					res_def
				)
			
			c_storage.space += weight_space_ref.space_per_quantity
			c_storage.weight += weight_space_ref.weight_per_quantity
	
	if c_faction.def.is_neutral_faction:
		# TODO: should probably be using the one with textures
		var trades: Array[BuiltinDefaultResourceTradePrice] = []
		for trade in default_basic_trade_system_prices.list:
			var new_trade: BuiltinDefaultResourceTradePrice = BuiltinDefaultResourceTradePrice.new()
			new_trade.builtin_resource_id = trade.builtin_resource_id
			var sell_variation = randi_range(
				-trade.max_sell_price_variation,
				trade.max_sell_price_variation,
			)
			var buy_variation = randi_range(
				-trade.max_buy_price_variation,
				trade.max_buy_price_variation,
			)
			new_trade.initial_buy_price = trade.initial_buy_price + buy_variation
			new_trade.initial_sell_price = trade.initial_sell_price + sell_variation
		
			trades.push_back(
				new_trade
			)
		var c_custom_trade: C_CustomTrade = C_CustomTrade.new()
		c_custom_trade.set_global_trades(
			trades,
		)
		ship.add_component(
			c_custom_trade,
		)
	else:
		# TODO: what to do
		pass
	
	ship.add_components(
		[
			C_ShipPopulation.new(population, def.population_max_capacity),
			C_DocksVisited.new(docks_to_visit),
			C_ShipLookingForDock.new(),
			C_Nationality.new(nationality),
			c_storage
		]
	)
	
	ship.add_relationship(
		Rels.create_belongs_to_faction(
			faction
		)
	)
	
	ship_container.add_child(ship)
	
	ECS.world.add_entity(ship)
	
	var c_name: C_Name = ship.get_component(C_Name)
	c_name.name_ = "The %s" % [
		nationality.female_first_names.pick_random(),
	]
	
	var entry = entries.pick_random()
	
	ship.global_position = entry.global_position
	var y_offset: float = 0
	if ship.has_node("NavigationAgent3D"):
		print("has NavigationAgent3D")
		var nav_agent: NavigationAgent3D = ship.get_node("NavigationAgent3D")
		y_offset = -nav_agent.path_height_offset
	
	ship.global_position.y += y_offset
	
	var sailor_count = max(0, def.population_min_capacity - 1)
	var not_sailor_count = population - sailor_count
	
	print("populating ship with %s sailors %s not sailors out of %s" % [
		sailor_count,
		not_sailor_count,
		population,
	])
	
	# TODO: curves or shares instead?
	for i in sailor_count:
		pop_unit_spawner.spawn_pop_unit_with_ship_3D(
			ship,
			0,
			faction,
			c_faction,
			nationality,
		)
	
	for i in not_sailor_count:
		pop_unit_spawner.spawn_pop_unit_with_ship_3D(
			ship,
			randi_range(1, 3),
			faction,
			c_faction,
			nationality,
		)
	
	event_bus.send_ecs_ship_spawned.emit(
		ship
	)
	
	# FIXME: remove this?
	#ECS.world.emit_event(
		#ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED, 
		#sail_ship_1,
		#{
			#"component": target,
		#}
	#)

func set_initial_factions(initial_factions_: Array[FactionDef]):
	initial_factions = initial_factions_
	
func set_faction_entities(faction_entities_: Array[Entity]):
	faction_entities = faction_entities_
	
	neutral_faction_entities.clear()
	for faction_entity in faction_entities:
		var c_faction: C_Faction = faction_entity.get_component(C_Faction)
		if !c_faction.def.is_neutral_faction:
			continue
		if !c_faction.def.can_spawn_ships:
			continue
		
		neutral_faction_entities.push_back(
			faction_entity
		)

# FIXME: duplicated with trade observer
func set_default_builtin_resources_space_weight_ref_def(
	default_builtin_resources_space_weight_ref_def_: BuiltinResourcesSpaceWeightRefList
):
	default_builtin_resources_space_weight_ref_def = default_builtin_resources_space_weight_ref_def_
	space_weight_red_def_dict.clear()
	for space_weight_ref in default_builtin_resources_space_weight_ref_def.list:
		space_weight_red_def_dict.set(
			space_weight_ref.res_id,
			space_weight_ref
		)
