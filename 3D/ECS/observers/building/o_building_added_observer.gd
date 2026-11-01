class_name O_BuildingAddedObserver
extends Observer

signal housing_capacity_increased(
	pop_type: int,
	amount: int,
	island: Entity,
)
signal workers_capacity_increased(
	pop_type: int,
	amount: int,
	island: Entity,
)
signal pop_unit_found_work(
	pop_type: int,
	island: Entity,
)

# FIXME: move all of this elsewhere
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
			q.with_all([C_Building]).on_event(
				ECSEvents.HOUSING_BUILDING_ADDED
			),
			_on_housing_building_added
		],
		[
			q.with_all([C_Building]).on_event(
				ECSEvents.PRODUCTION_BUILDING_ADDED
			),
			_on_production_building_added
		],
		[
			q.with_all([C_Building]).on_event(
				ECSEvents.GENERIC_BUILDING_ADDED
			),
			_on_generic_building_added
		],
	]

func _on_housing_building_added(
	_event: Variant,
	entity: Entity,
	data: Variant
) -> void:
	var island: Entity = data.island
	if !island:
		push_error("island is not present in data")
	
	var c_housing: C_HousingCapacity = entity.get_component(
		C_HousingCapacity
	)
	
	var c_pop_summary: C_PopulationSummary = island.get_component(
		C_PopulationSummary
	)
	if c_pop_summary:
		c_pop_summary.housing_capacity_increase(
			c_housing.pop_type,
			c_housing.maximum,
		)
	else:
		push_error("island does not have C_PopulationSummary")
	
	housing_capacity_increased.emit(
		c_housing.pop_type,
		c_housing.maximum,
		island,
	)
	
	# TODO : pop units without housing
	var pop_needing_housing = ECS.world.query.with_all(
		[C_LookingForHousing]
	).with_relationship(
		[
			Rels.create_is_on_island(data.island)
		]
	).execute()
	if pop_needing_housing.size() == 0:
		return
	
	for pop_unit: Entity in pop_needing_housing:
		var c_pop_unit: C_PopUnit = pop_unit.get_component(C_PopUnit)
		if !pop_unit:
			printerr("not a pop_unit")
			continue
		if c_pop_unit.pop_type != c_housing.pop_type:
			continue
		
		c_housing.current += 1
		
		pop_unit.add_relationship(Rels.create_lives_in(entity))
		cmd.remove_component(pop_unit, C_LookingForHousing)
		
		if c_housing.current >= c_housing.maximum:
			break

# FIXME: trash code
# named it like this for shortness
func find_building_needing_workers(b: ClassForLambdaFunction, c_housing: C_HousingCapacity):
	b.building_needing_workers_exist =  false
	while true:
		if !b.building:
			break
		b.workers = b.building.get_component(C_Workers)
		if !b.workers:
			b.building = b.buildings_needing_workers.pop_back()
			continue
		if !b.workers.workers.has(c_housing.pop_type):
			b.building = b.buildings_needing_workers.pop_back()
			continue
		b.worker_requirements = b.building.get_component(C_WorkerRequirement)
		if !b.worker_requirements:
			b.building = b.buildings_needing_workers.pop_back()
			continue
		for wr in b.worker_requirements.requirements.values():
			if wr.worker_type == c_housing.pop_type:
				b.worker_requirement = wr
		if !b.worker_requirement:
			b.building = b.buildings_needing_workers.pop_back()
			continue
			
		b.worker_quantity = b.workers.workers.get(c_housing.pop_type)
		if b.worker_quantity.worker_count >= b.worker_requirement.worker_count:
			b.building = b.buildings_needing_workers.pop_back()
			continue
			
		b.building_needing_workers_exist = true
		break

func _on_production_building_added(
	_event: Variant,
	entity: Entity,
	data: Variant,
) -> void:
	print("_on_production_building_added")
	var island: Entity = data.island
	if !island:
		push_error("island is not present in data")
	
	var c_worker_requirements: C_WorkerRequirement = entity.get_component(C_WorkerRequirement)
	var c_workers: C_Workers = entity.get_component(C_Workers)
	if !c_worker_requirements or !c_workers:
		printerr("missing worker components")
		# TODO : exit?
		return
	
	var c_pop_summary: C_PopulationSummary = island.get_component(
		C_PopulationSummary
	)
	for req in c_worker_requirements.requirements.values():
		if c_pop_summary:
			c_pop_summary.worker_capacities_increase(
				req.worker_type,
				req.worker_count,
			)
		else:
			push_error("island does not have C_PopulationSummary")
		
		workers_capacity_increased.emit(
			req.worker_type,
			req.worker_count,
			island,
		)
		
	# TODO: optimize by filtering by city?
	var available_workers = ECS.world.query.with_all(
		[C_JobLess]
	).with_relationship(
		[
			Rels.create_is_on_island(data.island)
		]
	).execute()
	if available_workers.size() > 0:
		#print("found %s available_workers" % [
			#available_workers.size(),
		#])
		for worker: Entity in available_workers:
			#print("iterating")
			var c_pop_unit: C_PopUnit = worker.get_component(C_PopUnit)
			if !c_pop_unit:
				printerr("not a pop_unit")
				continue
			if !c_worker_requirements.requirements.has(c_pop_unit.pop_type):
				print("not the right pop unit")
				continue
			var requirement: Worker_Requirement = c_worker_requirements.requirements.get(
				c_pop_unit.pop_type
			)
			var worker_quantity: WorkerQuantity = c_workers.workers.get(
				c_pop_unit.pop_type
			)
			if worker_quantity.worker_count >= requirement.worker_count:
				print("too many workers")
				continue
			
			cmd.add_relationship(
				worker,
				Relationship.new(
					R_WorksAt.new(), entity
				)
			)
			worker_quantity.worker_count += 1
			
			# Info: if there is no visual, just consider he is present
			if !worker.has_component(C_PopUnitWithVisual):
				var workers: WorkerQuantity = c_workers.present_workers.get(
					c_pop_unit.pop_type
				)
				workers.worker_count += 1
				var c_pop_unit_location: C_PopUnitLocation = worker.get_component(
					C_PopUnitLocation
				)
				if c_pop_unit_location:
					c_pop_unit_location.location = C_PopUnitLocation.LOCATION.WORKPLACE
			
			c_pop_summary.workers_increase(
				c_pop_unit.pop_type,
				1,
			)
			
			c_pop_unit.is_working = true
			cmd.remove_component(worker, C_JobLess)
			
			# TODO: logger for events
			#print("pop_unit found work")
			pop_unit_found_work.emit(
				c_pop_unit.pop_type,
				data.island,
			)
			
			# TODO: early return if done
	else:
		# This could happen
		# This is just for testing purposes
		push_warning("could not find a worker")
		pass
	
	# FIXME: mutualize?
	# Accessing if building is still missing workers
	var is_one_missing = false
	for req in c_worker_requirements.requirements.values():
		var current: WorkerQuantity = c_workers.workers.get(req.worker_type)
		if current.worker_count < req.worker_count:
			is_one_missing = true
	if is_one_missing == true:
		#print("not enough workers")
		#entity.add_component(C_MissingWorkers.new())
		cmd.add_component(entity, C_MissingWorkers.new())
		if entity.has_method("show_production_stoppped_indicator"):
			entity.show_production_stoppped_indicator()
		else:
			push_error("building needs method show_production_stoppped_indicator")

func _on_generic_building_added(
	_event: Variant,
	entity: Entity,
	data: Variant
) -> void:
	if !data.island:
		push_error("no island provided")
		return

	cmd.add_relationship(
		entity,
		Rels.create_built_on(data.island)
	)
	
	if data.faction:
		cmd.add_relationship(
			entity,
			Rels.create_belongs_to_faction(data.faction)
		)
	else:
		push_warning("no faction in data when calling _on_generic_building_added")
	
