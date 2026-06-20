extends Node3D
class_name GE_MapShipSpawner

@export var simultaneous_ship_max_count: int = 5

@export var spawn_ship_timer: float = 10.0

@export var visited_docks_per_ship_min_count: int = 2

@export var visited_docks_per_ship_max_count: int = 5

@export var ship_container: Node3D

@export var entries_containers: Array[Node3D] = []

@export var ship_definitions: Array[GE_TravellingShipDefinition] = []

var entries: Array[Node3D] = []

var timer: Timer

func _ready() -> void:
	for container in entries_containers:
		for entry in container.get_children():
			entries.push_back(entry)
			
	if !timer:
		timer = Timer.new()
		timer.wait_time = spawn_ship_timer
		timer.name = "timer"
		timer.timeout.connect(_on_timer_timeout)
		add_child(timer)
	timer.start()

func _on_timer_timeout():
	print("GE_MapShipSpawner:_on_timer_timeout")
	if ship_container.get_child_count() >= simultaneous_ship_max_count:
		print("too many ships")
		return
	
	print("spawning ship")
	
	var def = ship_definitions.pick_random()
	
	var instance: Entity = def.scene.instantiate()
	
	var population = randi_range(
		def.population_min_capacity,
		def.population_max_capacity,
	)
	
	var docks_to_visit: int = randi_range(
		visited_docks_per_ship_min_count,
		visited_docks_per_ship_max_count,
	)
	
	instance.add_components(
		[
			C_ShipPopulation.new(population, def.population_max_capacity),
			C_DocksVisited.new(docks_to_visit),
			C_ShipLookingForDock.new(),
		]
	)
	
	ship_container.add_child(instance)
	
	ECS.world.add_entity(instance)
	
	var entry = entries.pick_random()
	
	instance.global_position = entry.global_position
	
	var sailor_count = max(0, def.population_min_capacity - 1)
	var not_sailor_count = population - sailor_count
	
	print("populating ship with %s sailors %s not sailors out of %s" % [
		sailor_count,
		not_sailor_count,
		population,
	])
	
	# TODO: curves or shares instead?
	for i in sailor_count:
		var pop_unit = Entity.new()
		var c_pop_unit: C_PopUnit = C_PopUnit.new(
			0,
			false
		)
		pop_unit.add_component(c_pop_unit)
		pop_unit.add_relationship(Rels.create_travels_in(
			instance,
		))
		ECS.world.add_entity(pop_unit)
	
	for i in not_sailor_count:
		var pop_unit = Entity.new()
		var c_pop_unit: C_PopUnit = C_PopUnit.new(
			randi_range(1, 3),
			false
		)
		pop_unit.add_component(c_pop_unit)
		pop_unit.add_relationship(Rels.create_travels_in(
			instance,
		))
		ECS.world.add_entity(pop_unit)
		
		print("added pop %s to ship" % [
			c_pop_unit.pop_type,
		])
	
	#ECS.world.emit_event(
		#&"add_component_to_entity_requested", 
		#sail_ship_1,
		#{
			#"component": target,
		#}
	#)
	
