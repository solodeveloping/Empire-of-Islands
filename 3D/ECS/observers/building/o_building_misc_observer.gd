extends Observer
class_name O_BuildingMiscObserver

# Info: add generic building commands here

func sub_observers() -> Array[Array]:
	return [
		[
			# FIXME: find a way to wildcard this?
			q.with_all([C_Building]).on_event(
				ECSEvents.ASSIGN_BUILDING_TO_ISLAND_REQUESTED
			),
			_on_assign_building_to_island_requested
		],
	]

func _on_assign_building_to_island_requested(_event: Variant, entity: Entity, data: Variant) -> void:
	if !data.island:
		push_error("island is not present")
		
	print("adding built_on relationship to %s %s %s %s" % [
		entity.name,
		entity.get_path(),
		data.island.name,
		data.island.get_path(),
	])
	cmd.add_relationship(
		entity,
		Rels.create_built_on(data.island)
	)
