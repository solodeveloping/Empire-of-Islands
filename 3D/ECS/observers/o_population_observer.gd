extends Observer
class_name O_PopulationObserver

signal new_pop_unit_joined(pop_type: int)

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
			q.with_all([C_PopUnit]).on_event(&"pop_unit_joined"),
			_on_pop_unit_joined_island
		],
	]
	
# TOOD : find housing

# TODO : notion of island and/or city
# TODO: optimization
# could query building once if we are using a custom event
func _on_pop_unit_joined_island(event: Variant, entity: Entity, data: Variant) -> void:
	_find_and_assign_production_buildings(event, entity, data)
	_find_assign_housing_building(event, entity, data)

func _find_and_assign_production_buildings(_event: Variant, entity: Entity, _data: Variant):
	var c_pop_unit: C_PopUnit = entity.get_component(C_PopUnit)
	
	var _b: ClassForLambdaFunction = ClassForLambdaFunction.new()
	
	# TODO: optimize by filtering by city?
	# TODO : we are duplicating because the array is Archetype.entities
	# maybe we need to find a better way
	_b.buildings_needing_workers = ECS.world.query.with_all(
		[C_MissingWorkers]
	).execute().duplicate()
	
	_b.building = _b.buildings_needing_workers.pop_back()
	
	find_building_needing_workers(_b, c_pop_unit)
	
	if _b.building_needing_workers_exist:
		#e_pop_unit.add_relationship(
			#Relationship.new(R_WorksAt.new(), _b.building)
		#)
		_b.worker_quantity.worker_count += 1
		
		c_pop_unit.is_working = true
		cmd.add_relationship(
			entity, Rels.create_works_at(_b.building)
		)
		
		new_pop_unit_joined.emit(c_pop_unit.pop_type)
		
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
			
			# this was for the loop
			#_b.building = _b.buildings_needing_workers.pop_back()
			#find_building_needing_workers(_b, c_pop_unit)
	else:
		pass

func find_building_needing_workers(b: ClassForLambdaFunction, c_pop_unit: C_PopUnit):
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

func _find_assign_housing_building(_event: Variant, entity: Entity, _data: Variant):
	var housing_buildings = ECS.world.query.with_all(
		[C_HousingCapacity, C_NotFullyOccupied]
	).execute()
	
	var c_pop_unit: C_PopUnit = entity.get_component(C_PopUnit)
	if !c_pop_unit:
		push_error("c_pop_unit is not present")
		return
	
	var found_housing: bool = false
	for housing: Entity in housing_buildings:
		var c_housing_capacity: C_HousingCapacity = housing.get_component(C_HousingCapacity)
		if !c_housing_capacity:
			push_error("c_housing_capacity is not present")
			continue
		if c_housing_capacity.current >= c_housing_capacity.maximum:
			push_error("c_housing_capacity.current %s >= c_housing_capacity.maximum %s" % [
				c_housing_capacity.current,
				c_housing_capacity.maximum,
			])
			continue
			
		if c_housing_capacity.pop_type != c_pop_unit.pop_type:
			continue
			
		found_housing = true
		c_housing_capacity.current += 1
		if c_housing_capacity.current >= c_housing_capacity.maximum:
			cmd.remove_component(housing, C_NotFullyOccupied)
			
		cmd.add_relationship(entity, Rels.create_lives_in(housing))
	
	if !found_housing:
		cmd.add_component(entity, C_LookingForHousing.new())
