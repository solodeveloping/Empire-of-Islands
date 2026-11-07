extends Observer
class_name O_BuildingRemovedObserver

signal housing_capacity_decreased(
	pop_type: int,
	amount: int,
	island: Entity,
)
signal workers_capacity_decreased(
	pop_type: int,
	amount: int,
	island: Entity,
)

# FIXME: we are not using this
# Problem with observer event system
# Is that we are querying the data once for each units
# But we can do it once

func sub_observers() -> Array[Array]:
	return [
		# TODO: add building component
		[
			q.with_all([C_Building])
			.on_event(
				ECSEvents.BUILDING_IS_BEING_REMOVED
			),
			_on_building_is_being_removed
		],
	]

func _on_building_is_being_removed(
	_event: Variant,
	entity: Entity,
	_data: Variant
) -> void:
	print("_on_housing_building_is_being_removed")
	var island_rel = entity.get_relationship(
		Rels.built_on
	)
	if !island_rel or !island_rel.target:
		push_error("_on_housing_building_is_being_removed: !island")
	
	var island: Entity = island_rel.target
	
	var c_housing: C_HousingCapacity = entity.get_component(
		C_HousingCapacity
	)
	if c_housing:
		_handle_housing_building_being_removed(
			entity,
			island,
			c_housing,
		)
	
	var c_production: C_Production = entity.get_component(C_Production)
	if c_production:
		_handle_production_building_being_removed(
			entity,
			island,
			c_production,
		)

func _handle_housing_building_being_removed(
	_building: Entity,
	island: Entity,
	c_housing: C_HousingCapacity
):
	print("_handle_housing_building_being_removed")
	var c_pop_summary: C_PopulationSummary = island.get_component(
		C_PopulationSummary
	)
	if c_pop_summary:
		c_pop_summary.housing_capacity_decrease(
			c_housing.pop_type,
			c_housing.maximum,
		)
	else:
		push_error("island does not have C_PopulationSummary")
	
	housing_capacity_decreased.emit(
		c_housing.pop_type,
		c_housing.maximum,
		island,
	)
	
func _former_version_of_housing_being_removed(
	building: Entity,
	_island: Entity,
):
	# FIXME: is it faster with with_all
	var pop_units = ECS.world.query\
		#.with_all([C_PopUnit])\
		.with_relationship([Rels.create_lives_in(building)])\
		.execute()
	if pop_units.is_empty():
		return
	
	# FIXME: we need to emit events for a batch
	# Like, the perfs must not be very good here
	for pop_unit in pop_units:
		#print("remove_relationship")
		cmd.remove_relationship(pop_unit, Rels.create_lives_in(building))
		ECS.world.emit_event(
			ECSEvents.POP_UNIT_LEFT_HOUSING, 
			pop_unit,
			{}
		)

func _handle_production_building_being_removed(
	building: Entity,
	island: Entity,
	_c_production: C_Production
):
	var c_worker_requirements: C_WorkerRequirement = building.get_component(
		C_WorkerRequirement
	)
	var c_pop_summary: C_PopulationSummary = island.get_component(
		C_PopulationSummary
	)
	for req in c_worker_requirements.requirements.values():
		if c_pop_summary:
			c_pop_summary.worker_capacities_decrease(
				req.worker_type,
				req.worker_count,
			)
		else:
			push_error("island does not have C_PopulationSummary")
		
		workers_capacity_decreased.emit(
			req.worker_type,
			req.worker_count,
			island,
		)
	
func _former_version_of_production_building_being_removed(
	entity: Entity,
	_c_production: C_Production
):
	var pop_units = ECS.world.query\
		#.with_all([C_PopUnit])\
		.with_relationship([Rels.create_works_at(entity)])\
		.execute()
	if pop_units.is_empty():
		return
	
	for pop_unit in pop_units:
		#print("remove_relationship")
		cmd.remove_relationship(
			pop_unit,
			Rels.create_works_at(entity)
		)
		cmd.remove_component(
			pop_unit,
			C_Working,
		)
		ECS.world.emit_event(
			ECSEvents.POP_UNIT_LEFT_PRODUCTION_BUILDING, 
			pop_unit,
			{}
		)
