extends Observer
class_name O_PopulationObserver

# FIXME: poorly designed script

# FIXME: should we keep this?
signal new_pop_unit_joined(pop_type: int, island: Entity)
signal pop_unit_found_work(pop_type: int, island: Entity)

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
			q.with_all([C_PopUnit]).on_event(ECSEvents.POP_UNIT_JOINED),
			_on_pop_unit_joined_island
		],
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
	data: Variant,
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
			
		cmd.add_relationship(entity, Rels.create_lives_in(housing))
		
		# WARN: important to stop looping once we found a housing
		break
	
	#if !found_housing:
		#cmd.add_component(entity, C_LookingForHousing.new())

	return found_housing

func find_and_assign_housing_to_pop_units(
	entities: Array,
	existing_building: Entity = null
):
	var housing_buildings = ECS.world.query.with_all(
		[C_HousingCapacity, C_NotFullyOccupied]
	).enabled().execute()
	for entity: Entity in entities:
		if existing_building:
			cmd.remove_relationship(entity, Rels.create_lives_in(existing_building))
		
		if housing_buildings.is_empty():
			if !entity.has_component(C_LookingForHousing):
				cmd.add_component(entity, C_LookingForHousing.new())
			continue
		
		var found_housing = _find_and_assign_housing_to_pop_unit(
			entity,
			housing_buildings,
		)
		if !found_housing:
			if !entity.has_component(C_LookingForHousing):
				cmd.add_component(entity, C_LookingForHousing.new())

# Info: this is called when we need to reassign a batch of units
func find_and_assign_production_building_to_pop_units(
	entities: Array,
	existing_building: Entity = null
):
	var buildings = ECS.world.query.with_all(
		[C_MissingWorkers, C_WorkerRequirement, C_Workers]
	).enabled().execute().duplicate()
	
	for entity: Entity in entities:
		if existing_building:
			cmd.remove_relationship(entity, Rels.create_works_at(existing_building))
		
		var c_pop_unit: C_PopUnit = entity.get_component(C_PopUnit)
		
		var found_building: bool = false
		for building: Entity in buildings:
			var c_req: C_WorkerRequirement = building.get_component(C_WorkerRequirement)
			var c_workers: C_Workers = building.get_component(C_Workers)
			if c_workers.workers.has(c_pop_unit.pop_type):
				var worker: WorkerQuantity = c_workers.workers.get(c_pop_unit.pop_type)
				var req: Worker_Requirement = c_req.requirements.get(c_pop_unit.pop_type)
				if worker.worker_count >= req.worker_count:
					continue
				
				found_building = true
				worker.worker_count += 1
				cmd.add_relationship(entity, Rels.create_works_at(building))
				
				# Info: we are removing the building if we can assess it's full
				if c_workers.workers.size() == 1 and worker.worker_count >= req.worker_count:
					buildings.erase(building)
				
		if !found_building:
			c_pop_unit.is_working = false
			if !entity.has_component(C_JobLess):
				cmd.add_component(entity, C_JobLess.new())
