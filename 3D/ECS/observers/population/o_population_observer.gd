extends Observer
class_name O_PopulationObserver

# FIXME: poorly designed script

# FIXME: should we keep this?
signal new_pop_unit_joined(pop_type: int, island: Entity)
signal pop_unit_found_work(pop_type: int, island: Entity)
signal pop_unit_left_work(pop_type: int, island: Entity)

# TODO: event for leave housing

class ClassForLambdaFunction:
	var buildings_needing_workers: Array
	var building: Entity
	var building_needing_workers_exist = false
	var worker_requirements: C_WorkerRequirement
	var worker_requirement: Worker_Requirement
	var workers: C_Workers
	var worker_quantity: WorkerQuantity

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_all([C_PopUnit]).on_event(
				ECSEvents.POP_UNIT_JOINED
			),
			_on_pop_unit_joined_island
		],
		[
			q.with_all([C_PopUnit]).on_event(
				ECSEvents.POP_UNIT_LEAVE_WORKPLACE_REQUESTED
			),
			_on_pop_unit_leave_workplace_requested
		],
		[
			q.with_all([C_PopUnit]).on_event(
				ECSEvents.POP_UNIT_LEAVE_HOUSING_REQUESTED
			),
			_on_pop_unit_leave_housing_requested
		],
		# FIXME: maybe move this elsewhere
		[
			q.with_all([C_Building]).on_event(
				ECSEvents.PRODUCTION_BUILDING_REASSIGN_POP_UNITS_REQUESTED
			),
			_on_production_building_reassign_pop_units_requested
		],
		[
			q.with_all([C_Building]).on_event(
				ECSEvents.HOUSING_BUILDING_REASSIGN_POP_UNITS_REQUESTED
			),
			_on_housing_building_reassign_pop_units_requested
		],
		# Info: not possible
		#[
			#q.with_all([
				#C_PopUnit,
				## Info: we are using cmd so it does have the component yet
				##C_LookingForMoveTarget,
			#]).on_event("looking_for_move_target"),
			#_on_pop_unit_looking_for_move_target
		#],
		#[
			#q.with_all([C_PopUnit]).on_event(ECSEvents.POP_UNIT_LEFT_HOUSING),
			#_on_pop_unit_left_housing
		#],
	]

# TODO : notion of island and/or city
# TODO: optimization
# could query building once if we are using a custom event
func _on_pop_unit_joined_island(
	event: Variant,
	entity: Entity,
	data: Variant
) -> void:
	print("O_PopulationObserver:_on_pop_unit_joined_island")
	var island: Entity = data.island
	if !island:
		push_error("island not present")
	
	cmd.add_relationship(
		entity,
		Rels.create_is_on_island(island)
	)
	
	_find_and_assign_production_buildings(event, entity, data, island)
	_find_assign_housing_building(event, entity, data)
	
	var c_pop_unit: C_PopUnit = entity.get_component(C_PopUnit)
	if !c_pop_unit:
		push_error("c_pop_unit is not present")
		return
	
	if island.has_component(C_PopulationSummary):
		var c_pop_summary: C_PopulationSummary = island.get_component(
			C_PopulationSummary
		)
		c_pop_summary.population_increase(c_pop_unit.pop_type, 1)
	else:
		push_error("island does not have C_PopulationSummary")
		
	spawn_pop_unit_visual(
		entity,
		data.dock,
	)
	
	new_pop_unit_joined.emit(
		c_pop_unit.pop_type,
		island,
	)

#func _on_pop_unit_left_housing(
	#event: Variant,
	#entity: Entity,
	#data: Variant
#) -> void:
	#_find_assign_housing_building(event, entity, data)

# This is assigning a production building to the pop unit
func _find_and_assign_production_buildings(
	_event: Variant,
	entity: Entity,
	_data: Variant,
	island: Entity,
):
	var c_pop_unit: C_PopUnit = entity.get_component(C_PopUnit)
	
	var _b: ClassForLambdaFunction = ClassForLambdaFunction.new()
	
	# TODO: optimize by filtering by city?
	# TODO : we are duplicating because the array is Archetype.entities
	# maybe we need to find a better way
	_b.buildings_needing_workers = ECS.world.query.with_all(
		[C_MissingWorkers]
	).with_relationship(
		[
			Rels.create_built_on(island)
		]
	).enabled().execute().duplicate()
	
	_b.building = _b.buildings_needing_workers.pop_back()
	
	_find_building_needing_workers(_b, c_pop_unit)
	
	if _b.building_needing_workers_exist:
		#e_pop_unit.add_relationship(
			#Relationship.new(R_WorksAt.new(), _b.building)
		#)
		_b.worker_quantity.worker_count += 1
		
		c_pop_unit.is_working = true
		cmd.add_relationship(
			entity, Rels.create_works_at(_b.building)
		)
		
		if island.has_component(C_PopulationSummary):
			var c_pop_summary: C_PopulationSummary = island.get_component(
				C_PopulationSummary
			)
			c_pop_summary.workers_increase(
				c_pop_unit.pop_type,
				1,
			)
		pop_unit_found_work.emit(
			c_pop_unit.pop_type,
			island,
		)
		
		if _b.worker_quantity.worker_count >= _b.worker_requirement.worker_count:
			
			# FIXME: mutualize?
			# Accessing if building is still missing workers
			var is_one_missing = false
			for req in _b.worker_requirements.requirements:
				var current: WorkerQuantity = _b.workers.workers.get(req.worker_type)
				if current.worker_count < req.worker_count:
					is_one_missing = true
			if is_one_missing == false:
				print("building has enough workers %s %s" % [
					_b.building.name,
					_b.building.get_path(),
				])
				
				#_b.building.remove_component(C_MissingWorkers)
				cmd.remove_component(_b.building, C_MissingWorkers)
			
			# this was for the loop
			#_b.building = _b.buildings_needing_workers.pop_back()
			#find_building_needing_workers(_b, c_pop_unit)
	else:
		# there are no buildings needing workers
		pass
		
	#new_pop_unit_joined.emit(c_pop_unit.pop_type)

func _find_building_needing_workers(b: ClassForLambdaFunction, c_pop_unit: C_PopUnit):
	b.building_needing_workers_exist =  false
	while true:
		if !b.building:
			break
		b.workers = b.building.get_component(C_Workers)
		if !b.workers:
			b.building = b.buildings_needing_workers.pop_back()
			continue
		if !b.workers.workers.has(c_pop_unit.pop_type):
			b.building = b.buildings_needing_workers.pop_back()
			continue
		b.worker_requirements = b.building.get_component(C_WorkerRequirement)
		if !b.worker_requirements:
			b.building = b.buildings_needing_workers.pop_back()
			continue
		for wr in b.worker_requirements.requirements:
			if wr.worker_type == c_pop_unit.pop_type:
				b.worker_requirement = wr
		if !b.worker_requirement:
			b.building = b.buildings_needing_workers.pop_back()
			continue
			
		b.worker_quantity = b.workers.workers.get(c_pop_unit.pop_type)
		if b.worker_quantity.worker_count >= b.worker_requirement.worker_count:
			b.building = b.buildings_needing_workers.pop_back()
			continue
			
		b.building_needing_workers_exist = true
		break

# This is assigning a housing building to the pop unit
func _find_assign_housing_building(_event: Variant, entity: Entity, data: Variant):
	print("_find_assign_housing_building")
	var housing_buildings = ECS.world.query.with_all(
		[C_HousingCapacity, C_NotFullyOccupied]
	).with_relationship(
		[
			Rels.create_built_on(data.island)
		]
	).enabled().execute()
	
	var found_housing = _find_and_assign_housing_to_pop_unit(
		entity,
		housing_buildings,
	)
	if !found_housing:
		cmd.add_component(entity, C_LookingForHousing.new())

func _find_and_assign_housing_to_pop_unit(
	entity: Entity,
	housing_buildings: Array,
) -> bool:
	var c_pop_unit: C_PopUnit = entity.get_component(C_PopUnit)
	if !c_pop_unit:
		push_error("c_pop_unit is not present")
		return false
	
	var found_housing: bool = false
	for housing: Entity in housing_buildings:
		var c_housing_capacity: C_HousingCapacity = housing.get_component(C_HousingCapacity)
		if !c_housing_capacity:
			push_error("c_housing_capacity is not present")
			continue
		if c_housing_capacity.current >= c_housing_capacity.maximum:
			#push_error("c_housing_capacity.current %s >= c_housing_capacity.maximum %s" % [
				#c_housing_capacity.current,
				#c_housing_capacity.maximum,
			#])
			housing_buildings.erase(housing)
			continue
			
		if c_housing_capacity.pop_type != c_pop_unit.pop_type:
			print("wrong pop_type %s %s" % [
				c_housing_capacity.pop_type,
				c_pop_unit.pop_type,
			])
			continue
			
		found_housing = true
		print("increasing capacity of %s"% [
			housing.get_path(),
		])
		c_housing_capacity.current += 1
		if c_housing_capacity.current >= c_housing_capacity.maximum:
			cmd.remove_component(housing, C_NotFullyOccupied)
			housing_buildings.erase(housing)
		
		print("adding lives_in relationship %s" % [
			entity.name,
		])
		cmd.add_relationship(entity, Rels.create_lives_in(housing))
		
		# WARN: important to stop looping once we found a housing
		break
	
	#if !found_housing:
		#cmd.add_component(entity, C_LookingForHousing.new())

	return found_housing

func _on_housing_building_reassign_pop_units_requested(
	_event: Variant,
	building: Entity,
	data: Variant,
):
	_find_and_assign_housing_to_pop_units(
		data.pop_units,
		building,
	)

# Info: this is called when deleting an existing housing building
# FIXME: maybe semantic should be different
func _find_and_assign_housing_to_pop_units(
	pop_units: Array,
	existing_building: Entity = null
):
	var housing_buildings = ECS.world.query.with_all(
		[C_HousingCapacity, C_NotFullyOccupied]
	).enabled().execute()
	for pop_unit: Entity in pop_units:
		if existing_building:
			cmd.remove_relationship(
				pop_unit,
				Rels.create_lives_in(existing_building)
			)
		
		if housing_buildings.is_empty():
			if !pop_unit.has_component(C_LookingForHousing):
				cmd.add_component(pop_unit, C_LookingForHousing.new())
			continue
		
		var c_loc: C_PopUnitLocation = pop_unit.get_component(
			C_PopUnitLocation
		)
		if c_loc.location == C_PopUnitLocation.LOCATION.HOUSING:
			c_loc.location = C_PopUnitLocation.LOCATION.IDLE_ON_LAND
		
		var found_housing = _find_and_assign_housing_to_pop_unit(
			pop_unit,
			housing_buildings,
		)
		if !found_housing:
			if !pop_unit.has_component(C_LookingForHousing):
				cmd.add_component(
					pop_unit,
					C_LookingForHousing.new()
				)
			if !pop_unit.visible:
				pop_unit.show()
				pop_unit.set_deferred("disabled", false)
		else:
			# FIXME: prolly should not be here
			# the notion to know where to go
			
			# if not at work, find a new loc to go to
			if c_loc.location != C_PopUnitLocation.LOCATION.WORKPLACE:
				if !pop_unit.visible:
					print("showing pop_unit")
					pop_unit.show()
					pop_unit.set_deferred("disabled", false)
				
				print("adding C_LookingForMoveTarget %s" % [
					pop_unit.name,
				])
				cmd.add_component(
					pop_unit,
					C_LookingForMoveTarget.new(),
				)

func _on_production_building_reassign_pop_units_requested(
	_event: Variant,
	building: Entity,
	data: Variant,
):
	_find_and_assign_production_building_to_pop_units(
		data.pop_units,
		building,
	)

# Info: this is called when we need to reassign a batch of units
func _find_and_assign_production_building_to_pop_units(
	entities: Array,
	existing_building: Entity = null
):
	Loggie.msg("find_and_assign_production_building_to_pop_units %s %s" % [
		existing_building.name,
		entities.size(),
	]).color(Color.CYAN).info()
	var buildings = ECS.world.query.with_all(
		[C_MissingWorkers, C_WorkerRequirement, C_Workers]
	).enabled().execute().duplicate()
	
	for pop_unit: Entity in entities:
		LogMonitor.add(pop_unit.name)
		
		if existing_building:
			cmd.remove_relationship(
				pop_unit,
				Rels.create_works_at(existing_building)
			)
		
		var c_pop_unit: C_PopUnit = pop_unit.get_component(C_PopUnit)
		
		var found_building: bool = false
		for building: Entity in buildings:
			var c_req: C_WorkerRequirement = building.get_component(C_WorkerRequirement)
			var c_workers: C_Workers = building.get_component(C_Workers)
			if c_workers.workers.has(c_pop_unit.pop_type):
				var worker: WorkerQuantity = c_workers.workers.get(c_pop_unit.pop_type)
				var req: Worker_Requirement = c_req.requirements.get(c_pop_unit.pop_type)
				if worker.worker_count >= req.worker_count:
					continue
				
				print("found workplace for %s %s"% [
					pop_unit.name,
					building.name,
				])
				found_building = true
				worker.worker_count += 1
				cmd.add_relationship(
					pop_unit,
					Rels.create_works_at(building)
				)
				
				# Info: we are removing the building if we can assess it's full
				if c_workers.workers.size() == 1 and worker.worker_count >= req.worker_count:
					buildings.erase(building)
				
		if !found_building:
			print("did not find workplace for %s" % [
				pop_unit.name,
			])
			c_pop_unit.is_working = false
			if !pop_unit.has_component(C_JobLess):
				cmd.add_component(pop_unit, C_JobLess.new())
		
		# FIXME: maybe C_LookingForMoveTarget could do that
		var c_loc: C_PopUnitLocation = pop_unit.get_component(
			C_PopUnitLocation
		)
		if c_loc.location == C_PopUnitLocation.LOCATION.WORKPLACE:
			c_loc.location = C_PopUnitLocation.LOCATION.IDLE_ON_LAND
		
		if !pop_unit.visible:
			print("showing pop_unit")
			pop_unit.show()
			pop_unit.set_deferred("disabled", false)
		
		print("adding C_LookingForMoveTarget %s %s" % [
			pop_unit.name,
			existing_building.name,
		])
		cmd.add_component(
			pop_unit,
			C_LookingForMoveTarget.new(),
		)
		

func spawn_pop_unit_visual(
	pop_unit: Entity,
	dock: Entity,
):
	if !pop_unit.has_component(C_PopUnitWithVisual):
		return
	
	var spawn_point = dock.get_spawn_point()
	
	pop_unit.set_deferred("disabled", false)
	pop_unit.show()
	
	var offset = Vector3(
		randf_range(0, 3),
		0,
		randf_range(0, 3)
	)
	
	pop_unit.global_position = spawn_point.global_position + offset
	
	var c_loc: C_PopUnitLocation = pop_unit.get_component(C_PopUnitLocation)
	if c_loc:
		c_loc.location = C_PopUnitLocation.LOCATION.IDLE_ON_LAND
	else:
		printerr("could not find C_PopUnitLocation")
		
	cmd.add_component(pop_unit, C_LookingForMoveTarget.new())
	
	# Info: we are adding those with cmd so they're not present yet
	#var has_housing = pop_unit.has_relationship(Rels.lives_in)
	#print("has_housing: %s" % [
		#has_housing,
	#])
	
	# Info: we do not have the components because the events are sync
	#ECS.world.emit_event(
		#"looking_for_move_target", 
		#pop_unit,
		#{
		#}
	#)

#func _on_pop_unit_looking_for_move_target(
	#event: Variant,
	#entity: Entity,
	#data: Variant
#):
	#var has_housing = entity.has_relationship(Rels.lives_in)
	#print("has_housing: %s" % [
		#has_housing,
	#])



func _on_pop_unit_leave_workplace_requested(
	_event: Variant,
	pop_unit: Entity,
	data: Variant,
):
	print("_on_pop_unit_leave_workplace_requested")
	var building: Entity = data.building
	var c_workers: C_Workers = building.get_component(C_Workers)
	var c_pop_unit: C_PopUnit = pop_unit.get_component(C_PopUnit)
	
	if c_workers and c_pop_unit:
		var workers: WorkerQuantity = c_workers.workers.get(c_pop_unit.pop_type)
		if workers:
			workers.worker_count -= 1
		else:
			printerr("could not find workers for pop_type %s" % [
				c_pop_unit.pop_type,
			])
	else:
		printerr("C_Workers %s or C_PopUnit %s missing" % [
			c_workers,
			c_pop_unit,
		])
	
	cmd.remove_relationship(
		pop_unit,
		Rels.works_at
	)
	
	var r_built_on: Relationship = building.get_relationship(Rels.built_on)
	if !r_built_on:
		printerr("r_built_on not found")
		return
	
	if !r_built_on.target:
		printerr("!r_built_on.target")
		return
	
	# FIXME: could be moved elsewhere?
	var summary: C_PopulationSummary = r_built_on.target.get_component(
		C_PopulationSummary
	)
	if summary:
		summary.workers_decrease(
			c_pop_unit.pop_type,
			1
		)
	else:
		printerr("C_PopulationSummary not found")
	
	pop_unit_left_work.emit(
		c_pop_unit.pop_type,
		r_built_on.target
	)

func _on_pop_unit_leave_housing_requested(
	_event: Variant,
	pop_unit: Entity,
	data: Variant,
):
	print("_on_pop_unit_leave_housing_requested")
	var building: Entity = data.building
	var c_housing: C_HousingCapacity = building.get_component(
		C_HousingCapacity
	)
	if c_housing:
		c_housing.current -= 1
	else:
		printerr("C_HousingCapacity not found")
	
	cmd.remove_relationship(
		pop_unit,
		Rels.lives_in,
	)
