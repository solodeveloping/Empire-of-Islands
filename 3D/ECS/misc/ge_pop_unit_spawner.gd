extends Node
class_name GE_PopUnitSpawner

@export
var spawn_pop_unit_visuals: bool = true

@export
var pop_unit_definitions: Array[GE_PopUnitDefinition] = []

var disabled_physics_space_rid: RID

func _ready() -> void:
	# TODO: 2D/3D
	# Info: I think it does something but not sure
	disabled_physics_space_rid = PhysicsServer3D.space_create()
	PhysicsServer3D.space_set_active(
		disabled_physics_space_rid,
		false,
	)

func spawn_pop_unit_with_ship_3D(
	ship: Entity,
	pop_unit_type: int,
	faction: Entity,
	_c_faction: C_Faction,
	# TODO: could have different nationalities
	ship_nationality: Nationality,
):
	var pop_unit: Entity = create_pop_unit_with_ship(
		ship,
		pop_unit_type,
		faction,
		_c_faction,
		ship_nationality,
	)
	
	ECS.world.add_entity(pop_unit)
	
	# does not change perf that much
	#pop_unit.global_position = ship.global_position
	# Makes it worst
	#var min_float = -1.79769e308
	#var max_float = 1.79769e308
	# Info: does not do anything
	#var min_float = -100_000
	#var max_float = 100_00
	#pop_unit.global_position = Vector3(
		#randf_range(min_float, max_float),
		#randf_range(min_float, max_float),
		#randf_range(min_float, max_float),
	#)
	
	if pop_unit.has_method("disable_physics"):
		pop_unit.disable_physics()
	
	# Not sure if does something
	# I think it does
	var _pop_unit: CharacterBody3D = pop_unit as Variant as CharacterBody3D
	if _pop_unit:
		PhysicsServer3D.body_set_space(
			_pop_unit.get_rid(),
			disabled_physics_space_rid,
		)

# TODO: mutualize what can be
func spawn_pop_unit_with_ship_2D(
	ship: Entity,
	pop_unit_type: int,
	faction: Entity,
	_c_faction: C_Faction,
	# TODO: could have different nationalities
	ship_nationality: Nationality,
):
	var pop_unit: Entity = create_pop_unit_with_ship(
		ship,
		pop_unit_type,
		faction,
		_c_faction,
		ship_nationality,
	)
	
	ECS.world.add_entity(pop_unit)
	
	if pop_unit.has_method("disable_physics"):
		pop_unit.disable_physics()
		
	var _pop_unit: CharacterBody2D = pop_unit as Variant as CharacterBody2D
	if _pop_unit:
		PhysicsServer2D.body_set_space(
			_pop_unit.get_rid(),
			disabled_physics_space_rid,
		)

func create_pop_unit_with_ship(
	ship: Entity,
	pop_unit_type: int,
	faction: Entity,
	_c_faction: C_Faction,
	# TODO: could have different nationalities
	ship_nationality: Nationality,
) -> Entity:
	var pop_unit: Entity
	if spawn_pop_unit_visuals:
		#print("GE_MapShipSpawner: spawning instance")
		var visual = pop_unit_definitions.pick_random()
		pop_unit = visual.scene.instantiate()
		# FIXME: does not guarantee unique names
		pop_unit.name = "instantiated_pop_unit_%s" % [
			randi(),
		]
		pop_unit.hide()
		# TODO: find a better system
		# that handles MMs
		#pop_unit.disable_physics()
		pop_unit.add_component(C_PopUnitWithVisual.new())
		
		# WARN: can't use get_component before it's added to the world
		
	else:
		pop_unit = Entity.new()
		pop_unit.name = "entity_pop_unit_%s" % [
			randi(),
		]
	
	var first_name: String = ""
	var gender = randi_range(0, 1)
	if gender == 0:
		first_name = ship_nationality.male_first_names.pick_random()
	else:
		first_name = ship_nationality.female_first_names.pick_random()
	
	var last_name = ship_nationality.last_names.pick_random()
	
	pop_unit.add_components([
		C_PersonName.new(
			first_name,
			last_name,
		),
		C_Name.new(
			"%s %s" % [
				first_name,
				last_name,
			]
		),
		C_PopUnitLocation.new(C_PopUnitLocation.LOCATION.IN_SHIP),
		C_ConsumeResources.new(),
		C_Nationality.new(ship_nationality),
		# TODO: could have a more complicated system
		C_Storage.new(
			randi_range(10, 30)
		),
		C_PopUnit.new(
			pop_unit_type,
			false
		),
		# FIXME: for now they're not moving, even though in ship
		# When we need them to be moving in ship
		# Just modify this
		# Could be an option too
		C_IsMoving.new(false)
	])
	
	pop_unit.add_relationship(Rels.create_travels_in(
		ship,
	))
	pop_unit.add_relationship(
		Rels.create_belongs_to_faction(
			faction
		)
	)
	return pop_unit

# This is unused
func spawn_pop_unit_2D(
	pop_unit_type: int,
	faction: Entity,
	_c_faction: C_Faction,
	# TODO: could have different nationalities
	nationality: Nationality,
	housing_building: Entity = null
) -> Entity:
	var pop_unit: Entity
	if spawn_pop_unit_visuals:
		#print("GE_MapShipSpawner: spawning instance")
		var visual = pop_unit_definitions.pick_random()
		pop_unit = visual.scene.instantiate()
		# FIXME: does not guarantee unique names
		pop_unit.name = "instantiated_pop_unit_%s" % [
			randi(),
		]
		pop_unit.hide()
		# TODO: find a better system
		# that handles MMs
		#pop_unit.disable_physics()
		pop_unit.add_component(C_PopUnitWithVisual.new())
		
		# WARN: can't use get_component before it's added to the world
		
	else:
		pop_unit = Entity.new()
		pop_unit.name = "entity_pop_unit_%s" % [
			randi(),
		]
		#pop_unit.add_component(C_PopUnit.new())
	
	var first_name: String = ""
	var gender = randi_range(0, 1)
	if gender == 0:
		first_name = nationality.male_first_names.pick_random()
	else:
		first_name = nationality.female_first_names.pick_random()
	
	var last_name = nationality.last_names.pick_random()
	
	pop_unit.add_components([
		C_PersonName.new(
			first_name,
			last_name,
		),
		C_Name.new(
			"%s %s" % [
				first_name,
				last_name,
			]
		),
		C_PopUnitLocation.new(C_PopUnitLocation.LOCATION.IN_SHIP),
		C_ConsumeResources.new(),
		C_Nationality.new(nationality),
		# TODO: could have a more complicated system
		C_Storage.new(
			randi_range(10, 30)
		),
		C_PopUnit.new(
			pop_unit_type,
			false
		),
		C_JobLess.new(),
	])
	
	#pop_unit.add_relationship(Rels.create_travels_in(
		#ship,
	#))
	pop_unit.add_relationship(
		Rels.create_belongs_to_faction(
			faction
		)
	)
	
	if housing_building:
		pop_unit.add_relationship(
			Rels.create_lives_in(housing_building)
		)
	
	ECS.world.add_entity(pop_unit)
	
	# Not sure if does something
	# I think it does
	#var _pop_unit: CharacterBody3D = pop_unit as Variant as CharacterBody3D
	#PhysicsServer3D.body_set_space(
		#_pop_unit.get_rid(),
		#disabled_physics_space_rid,
	#)
	
	return pop_unit
	
