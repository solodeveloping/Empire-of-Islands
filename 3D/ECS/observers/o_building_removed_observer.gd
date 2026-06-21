extends Observer
class_name O_BuildingRemovedObserver

# FIXME: we are not using this
# Problem with observer event system
# Is that we are querying the data once for each units
# But we can do it once

func sub_observers() -> Array[Array]:
	return [
		# TODO: add building component
		[
			q.with_all([C_Building]).on_event(ECSEvents.BUILDING_IS_BEING_REMOVED),
			_on_housing_building_is_being_removed
		],
	]

func _on_housing_building_is_being_removed(
	_event: Variant, entity: Entity, _data: Variant
) -> void:
	var c_housing: C_HousingCapacity = entity.get_component(C_HousingCapacity)
	if c_housing:
		_handle_housing_building_being_removed(
			entity,
			c_housing,
		)
		
	var c_production: C_Production = entity.get_component(C_Production)
	if c_production:
		pass

func _handle_housing_building_being_removed(
	entity: Entity,
	_c_housing: C_HousingCapacity
):
	# FIXME: is it faster with with_all
	var pop_units = ECS.world.query\
		#.with_all([C_PopUnit])\
		.with_relationship([Rels.create_lives_in(entity)])\
		.execute()
	if pop_units.is_empty():
		return
	
	# FIXME: we need to emit events for a batch
	# Like, the perfs must not be very good here
	for pop_unit in pop_units:
		cmd.remove_relationship(pop_unit, Rels.create_lives_in(entity))
		ECS.world.emit_event(
			ECSEvents.POP_UNIT_LEFT_HOUSING, 
			pop_unit,
			{}
		)
	
func _handle_production_building_being_removed(
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
		cmd.remove_relationship(pop_unit, Rels.create_works_at(entity))
		ECS.world.emit_event(
			ECSEvents.POP_UNIT_LEFT_HOUSING, 
			pop_unit,
			{}
		)
