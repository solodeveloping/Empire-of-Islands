extends Node3D
class_name GE_MapShipSpawner

# Info: GE is for GodotEconomics

@export var simultaneous_ship_max_count: int = 5

@export var spawn_ship_timer: float = 10.0

@export var visited_docks_per_ship_min_count: int = 2

@export var visited_docks_per_ship_max_count: int = 5

@export var ship_container: Node3D

@export var entries_containers: Array[Node3D] = []

@export var ship_definitions: Array[GE_TravellingShipDefinition] = []

@export_category("Pop units")

@export var spawn_pop_unit_visuals: bool = true

@export var pop_unit_definitions: Array[GE_PopUnitDefinition] = []

# FIXME: move it elsewhere, maybe a Resource
var names: Array[String] = [
	"James",
	"Michael",
	"John",
	"Robert",
	"William",
	"Richard",
	"Thomas",
	"Christopher",
	"Charles",
	"Daniel",
	"Matthew",
	"Anthony",
	"Mark",
	"Steven",
	"Andrew",
	"Joshua",
	"Paul",
	"Kevin",
	"Kenneth",
	"Brian",
]

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
	try_spawn_ship()

func try_spawn_ship():
	if ship_container.get_child_count() >= simultaneous_ship_max_count:
		print("too many ships")
		return
	
	print("spawning ship")
	
	var def = ship_definitions.pick_random()
	
	var instance: Entity = def.scene.instantiate()
	instance.name = "ship_%s" % [
		ship_container.get_child_count(),
	]
	
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
		spawn_pop_unit(
			instance,
			0
		)
	
	for i in not_sailor_count:
		spawn_pop_unit(
			instance,
			randi_range(1, 3),
		)
	
	#ECS.world.emit_event(
		#ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED, 
		#sail_ship_1,
		#{
			#"component": target,
		#}
	#)

func spawn_pop_unit(
	ship: Entity,
	pop_unit_type: int,
):
	var pop_unit: Entity
	if spawn_pop_unit_visuals:
		print("GE_MapShipSpawner: spawning instance")
		var visual = pop_unit_definitions.pick_random()
		pop_unit = visual.scene.instantiate()
		# FIXME: does not guarantee unique names
		pop_unit.name = "instantiated_pop_unit_%s" % [
			randi(),
		]
		pop_unit.hide()
		# TODO: find a better system
		# that handles MMs
		pop_unit.set_deferred("disabled", true)
		pop_unit.add_component(C_PopUnitWithVisual.new())
		
		# WARN: can't use get_component before it's added to the world
		
	else:
		pop_unit = Entity.new()
		pop_unit.name = "entity_pop_unit_%s" % [
			randi(),
		]
		
	pop_unit.add_component(
		C_Name.new(
			names.pick_random()
		)
	)
	pop_unit.add_component(
		C_PopUnitLocation.new(C_PopUnitLocation.LOCATION.IN_SHIP)
	)
	
	var c_pop_unit: C_PopUnit = C_PopUnit.new(
		pop_unit_type,
		false
	)
	pop_unit.add_component(c_pop_unit)
	pop_unit.add_relationship(Rels.create_travels_in(
		ship,
	))
	
	ECS.world.add_entity(pop_unit)
