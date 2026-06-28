extends Observer
class_name O_ShipMiscObserver

# Info: add generic ship commands here

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_all([C_Ship]).on_event(
				ECSEvents.SHIP_UNLOAD_REQUESTED
			),
			_on_ship_unload_requested
		],
	]

func _on_ship_unload_requested(
	_event: Variant,
	entity: Entity,
	data: Variant,
) -> void:
	if !entity.has_component(C_ShipPopulation):
		push_error("_on_ship_waiting_for_unloading: entity does not has C_ShipPopulation")
		return
	
	var c_ship_population: C_ShipPopulation = entity.get_component(C_ShipPopulation)
	if !c_ship_population:
		return
		
	if c_ship_population.current <= 0:
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
		print("emitting POP_UNIT_JOINED %s" % [
			i,
		])
		
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
			}
		)
		
		cmd.remove_relationship(pop_units[i], Rels.travels_in)
	
