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
		# TODO: add building component
		[
			q.with_all([C_Building]).on_event(ECSEvents.HOUSING_BUILDING_ADDED),
			_on_housing_building_added
		],
		[
			q.with_all([C_Building]).on_event(ECSEvents.PRODUCTION_BUILDING_ADDED),
			_on_production_building_added
		],
		[
			q.with_all([C_Building]).on_event(ECSEvents.GENERIC_BUILDING_ADDED),
			_on_generic_building_added
		],
	]

func _on_housing_building_added(_event: Variant, entity: Entity, data: Variant) -> void:
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
		for wr in b.worker_requirements.requirements:
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
	for req in c_worker_requirements.requirements:
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
		for worker: Entity in available_workers:
			var pop_unit: C_PopUnit = worker.get_component(C_PopUnit)
			if !pop_unit:
				printerr("not a pop_unit")
				continue
			if !c_worker_requirements.requirements.has(pop_unit.pop_type):
				continue
			var requirement: Worker_Requirement = c_worker_requirements.requirements.get(pop_unit.pop_type)
			var worker_quantity: WorkerQuantity = c_workers.workers.get(pop_unit.pop_type)
			if worker_quantity.worker_count >= requirement.worker_count:
				continue
			
			worker.add_relationship(Relationship.new(
				R_WorksAt.new(), entity
			))
			worker_quantity.worker_count += 1
			
			pop_unit.is_working = true
			cmd.remove_component(worker, C_JobLess)
			pop_unit_found_work.emit(
				pop_unit.pop_type,
				data.island,
			)
			
			# TODO: early return if done
		
		
	# FIXME: mutualize?
	# Accessing if building is still missing workers
	var is_one_missing = false
	for req in c_worker_requirements.requirements:
		var current: WorkerQuantity = c_workers.workers.get(req.worker_type)
		if current.worker_count < req.worker_count:
			is_one_missing = true
	if is_one_missing == true:
		#entity.add_component(C_MissingWorkers.new())
		cmd.add_component(entity, C_MissingWorkers.new())

func _on_generic_building_added(_event: Variant, entity: Entity, data: Variant) -> void:
	if !data.island:
		push_error("no island provided")
		return

	cmd.add_relationship(entity, Rels.create_built_on(data.island))
