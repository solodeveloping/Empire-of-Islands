extends Observer
class_name O_ShipMiscObserver

signal island_population_changed(island: Entity)

# Info: add generic ship commands here

var event_bus: EventBus

func _ready() -> void:
	var current_scene = get_tree().current_scene
	event_bus = current_scene.get_node("%EventBus")

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_all([C_Ship]).on_event(
				ECSEvents.SHIP_UNLOAD_REQUESTED
			),
			_on_ship_unload_requested
		],
		[
			q.with_all([C_Ship]).on_event(
				ECSEvents.SHIP_UNLOAD_AT_SEA_REQUESTED
			),
			_on_ship_unload_at_sea_requested
		],
		[
			q.with_any([C_Ship,]).on_match(),
			_on_ship_match
		],
		[
			q.with_any([C_Ship,]).on_unmatch(),
			_on_ship_unmatch
		],
	]

func _on_ship_unload_requested(
	_event: Variant,
	ship: Entity,
	data: Variant,
	#"buoy": buoy,
	#"dock": dock,
	#"island": island,
) -> void:
	unload_passengers(
		_event,
		ship,
		data,
	)
	
	# FIXME: semantic is not nice
	# it's inside unload
	# but the event is called from navigation
	# maybe we need intermediary
	load_ship(
		ship,
		data,
	)
	
	ECS.world.emit_event(
		ECSEvents.SHIP_TRADING_REQUESTED,
		ship,
		data,
	)
	
func unload_passengers(
	_event: Variant,
	entity: Entity,
	data: Variant,
):
	if !entity.has_component(C_ShipPopulation):
		push_error("_on_ship_waiting_for_unloading: entity does not has C_ShipPopulation")
		return
	
	var c_ship_population: C_ShipPopulation = entity.get_component(C_ShipPopulation)
	if !c_ship_population:
		printerr("C_ShipPopulation not found")
		return
		
	if c_ship_population.current <= 0:
		printerr("c_ship_population.current <= 0")
		return
	
	# FIXME: better system
	# Info: we have to duplicate because we receive a copy
	var pop_units: Array = ECS.world.query.with_relationship([
		Relationship.new(R_TravelsIn.new(), entity),
	]).execute().duplicate()
	
	print("found %s - %s pop_units travelling in ship" % [
		pop_units.size(),
		c_ship_population.current,
	])
	
	if pop_units.is_empty():
		printerr("no pop units travelling in ship found")
		#continue
	
	if pop_units.size() != c_ship_population.current:
		push_error("c_pop_units.size() %s != c_ship_population.current %s" % [
			pop_units.size(),
			c_ship_population.current,
		])
	
	var c_docks: C_DocksVisited = entity.get_component(C_DocksVisited)
	if !c_docks:
		push_error("C_DocksVisited is not present")
	
	var quantity_unload: int = 0
	if c_docks.visited_dock_buoy_ids.size() == 0:
		# FIXME: too hardcoded
		quantity_unload = randi_range(
			0,
			pop_units.size() - 2,
		)
	
	# Info: first could be last
	if c_docks.max_docks_to_visit == c_docks.visited_dock_buoy_ids.size():
		quantity_unload = pop_units.size()
	# Info: to make sure it's not the first
	elif c_docks.visited_dock_buoy_ids.size() > 0:
		var docks = ECS.world.query.with_all([
			C_DockBuoy
		]).execute()
		if docks.size() <= c_docks.visited_dock_buoy_ids.size():
			quantity_unload = pop_units.size()
		else:
			quantity_unload = randi_range(
				0,
				pop_units.size(),
			)
	
	# Info: this can break before the loop is done
	# If it's not a duplicated array
	#for pop_unit in pop_units:
	for i in pop_units.size():
		#print("emitting POP_UNIT_JOINED %s" % [
			#i,
		#])
		
		if i >= quantity_unload:
			break
		
		c_ship_population.current -= 1
		
		# Info: this is synchronous, the event will be processed before moving on
		# to the next loop
		ECS.world.emit_event(
			ECSEvents.POP_UNIT_JOINED, 
			#pop_unit,
			pop_units[i],
			{
				"island": data.island,
				"dock": data.dock,
				"buoy": data.buoy,
			}
		)
		
		#print("remove_relationship")
		cmd.remove_relationship(pop_units[i], Rels.travels_in)

func load_ship(
	ship: Entity,
	data: Variant,
):
	var c_ship_population: C_ShipPopulation = ship.get_component(
		C_ShipPopulation
	)
	if !c_ship_population:
		printerr("C_ShipPopulation not found")
		return
	
	var pop_units: Array = ECS.world.query.with_all([
		C_PopUnit,
		C_LookingToLeaveIsland,
	]).with_relationship([
		Relationship.new(R_IsOnIsland.new(), data.island),
	]).execute().duplicate()
	
	if pop_units.is_empty():
		print("did not find pop units looking to leave the island")
		return
		
	for pop_unit: Entity in pop_units:
		# FIXME : maybe a method for this "is_full"
		if c_ship_population.is_full():
			break
		
		# hiding the unit and disabling physics
		if pop_unit.has_method("hide"):
			pop_unit.hide()
		if pop_unit.has_method("disable_physics"):
			pop_unit.disable_physics()
		
		# removing the component
		cmd.remove_component(
			pop_unit,
			C_LookingToLeaveIsland,
		)
		
		# adding the unit to the ship
		c_ship_population.current += 1
		cmd.add_relationship(
			pop_unit,
			Rels.create_travels_in(
				ship
			)
		)
		
		# making the unit leave the workplace
		var r_work_at: Relationship = pop_unit.get_relationship(
			Rels.works_at
		)
		if r_work_at:
			if r_work_at.target:
				ECS.world.emit_event(
					ECSEvents.POP_UNIT_LEAVE_WORKPLACE_REQUESTED, 
					pop_unit,
					{
						"building": r_work_at.target,
					}
				)
			else:
				printerr("!r_work_at.target")
		
		# making the unit leave the housing
		var r_lives_in: Relationship = pop_unit.get_relationship(
			Rels.lives_in
		)
		if r_lives_in:
			if r_lives_in.target:
				ECS.world.emit_event(
					ECSEvents.POP_UNIT_LEAVE_HOUSING_REQUESTED, 
					pop_unit,
					{
						"building": r_lives_in.target,
					}
				)
			else:
				printerr("!r_lives_in.target")
		
		# TODO: maybe should be done elsewhere
		# leave island
		var r_is_on: Relationship = pop_unit.get_relationship(
			Rels.is_on_island
		)
		if r_is_on:
			if r_is_on.target:
				var c_pop_summary: C_PopulationSummary = r_is_on.target.get_component(C_PopulationSummary)
				var c_pop_unit: C_PopUnit = pop_unit.get_component(
					C_PopUnit
				)
				c_pop_summary.population_decrease(
					c_pop_unit.pop_type,
					1,
				)
				print("remove_relationship")
				cmd.remove_relationship(
					pop_unit,
					Rels.is_on_island,
				)
			else:
				printerr("!r_is_on.target")
		else:
			printerr("!r_is_on")
		
		# add relationship with ship
		cmd.add_relationship(
			pop_unit,
			Rels.create_travels_in(ship)
		)
		
	island_population_changed.emit(data.island)

func _on_ship_unload_at_sea_requested(
	_event: Variant,
	ship: Entity,
	_data: Variant,
	#"buoy": buoy,
	#"dock": dock,
	#"island": island,
) -> void:
	if !ship.has_component(C_ShipPopulation):
		push_error("_on_ship_waiting_for_unloading: entity does not has C_ShipPopulation")
		return
	
	var c_ship_population: C_ShipPopulation = ship.get_component(C_ShipPopulation)
	if !c_ship_population:
		printerr("C_ShipPopulation not found")
		return
		
	if c_ship_population.current <= 0:
		printerr("c_ship_population.current <= 0")
		return
	
	var pop_units: Array = ECS.world.query.with_relationship([
		Rels.create_travels_in(ship),
	]).execute().duplicate()
	
	print("found %s - %s pop_units travelling in ship" % [
		pop_units.size(),
		c_ship_population.current,
	])
	
	if pop_units.is_empty():
		printerr("no pop units travelling in ship found")
		#continue
	
	if pop_units.size() != c_ship_population.current:
		push_error("c_pop_units.size() %s != c_ship_population.current %s" % [
			pop_units.size(),
			c_ship_population.current,
		])
	
	for pop_unit: Entity in pop_units:
		c_ship_population.current -= 1
		var offset: Vector3 = Vector3(
			randf_range(-5, 5),
			# FIXME: kinda terrible to hard code the water level
			-0.8,
			randf_range(-5, 5)
		)
		pop_unit.global_position = ship.global_position + offset
		
		# TODO: check for Godot and compile warning
		cmd.add_component(
			pop_unit,
			C_HasWaterEndurance.new(15),
		)
		cmd.remove_relationship(
			pop_unit,
			Rels.travels_in
		)
	
		# Info: one check to differentiate "just entities" and entities
		# with graphics
		if pop_unit.has_method("show"):
			pop_unit.show()
			pop_unit.is_in_water = true
			pop_unit.play_swim_idle()
			pop_unit.enable_physics()
	
func _on_ship_match(
	_event: Variant,
	entity: Entity,
	_data: Variant,
):
	event_bus.send_ecs_ship_appeared.emit(
		entity
	)

func _on_ship_unmatch(
	_event: Variant,
	entity: Entity,
	_data: Variant,
):
	event_bus.send_ecs_ship_disappeared.emit(
		entity
	)
