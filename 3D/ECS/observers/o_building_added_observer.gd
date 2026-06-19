class_name O_BuildingAddedObserver
extends Observer

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
		[q.with_all([C_Building]).on_event(&"housing_building_added"), _on_housing_building_added],
		[q.with_all([C_Building]).on_event(&"production_building_added"), _on_production_building_added],
	]

func _on_housing_building_added(_event: Variant, entity: Entity, _data: Variant) -> void:
	#entity.get_component(C_Health).hp -= data.amount
	var c_housing: C_HousingCapacity = entity.get_component(C_HousingCapacity)
	#the_population.population_increase(
	#population_increase(
		#c_housing.pop_type, c_housing.current
	#)
	
	var _b: ClassForLambdaFunction = ClassForLambdaFunction.new()
	
	# TODO: optimize by filtering by city?
	# TODO : we are duplicating because the array is Archetype.entities
	# maybe we need to find a better way
	_b.buildings_needing_workers = ECS.world.query.with_all(
		[C_MissingWorkers]
	).execute().duplicate()
	
	_b.building = _b.buildings_needing_workers.pop_back()
	
	find_building_needing_workers(_b, c_housing)
	#find_building_needing_workers.call(_b)
	
	for i in range(c_housing.current):
		# TODO: add city relationship?
		#var e_pop_unit = Entity.new()
		#ECS.world.add_entity(e_pop_unit)
		#var c_pop_unit = C_PopUnit.new(c_housing.pop_type)
		#e_pop_unit.add_component(c_pop_unit)
		
		if _b.building_needing_workers_exist:
			#e_pop_unit.add_relationship(
				#Relationship.new(R_WorksAt.new(), _b.building)
			#)
			_b.worker_quantity.worker_count += 1
			
			if i < (c_housing.current - 1):
				if _b.worker_quantity.worker_count >= _b.worker_requirement.worker_count:
					
					# FIXME: mutualize?
					# Accessing if building is still missing workers
					var is_one_missing = false
					for req in _b.worker_requirements.requirements:
						var current: WorkerQuantity = _b.workers.workers.get(req.worker_type)
						if current.worker_count < req.worker_count:
							is_one_missing = true
					if is_one_missing == false:
						#_b.building.remove_component(C_MissingWorkers)
						cmd.remove_component(_b.building, C_MissingWorkers)
					
					_b.building = _b.buildings_needing_workers.pop_back()
					find_building_needing_workers(_b, c_housing)
		else:
			pass
			#e_pop_unit.add_component(C_JobLess.new())

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

func _on_production_building_added(_event: Variant, entity: Entity, _data: Variant) -> void:
	var c_worker_requirements: C_WorkerRequirement = entity.get_component(C_WorkerRequirement)
	var c_workers: C_Workers = entity.get_component(C_Workers)
	if !c_worker_requirements or !c_workers:
		printerr("missing worker components")
		# TODO : exit?
		return
	# TODO: optimize by filtering by city?
	var available_workers = ECS.world.query.with_all(
		[C_JobLess]
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
