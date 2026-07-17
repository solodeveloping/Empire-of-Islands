extends Observer
class_name O_FactionMiscObserver

var faction_entities: Array[Entity] = []

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_any(
				[C_Island,]
			).on_event(
				ECSEvents.ASSIGN_FACTION_TO_ENTITIES_REQUESTED
			),
			_on_assign_faction_to_entities_requested
		],
	]

func _on_assign_faction_to_entities_requested(
	_event: Variant,
	_entity: Entity,
	_data: Variant
) -> void:
	print("_on_assign_faction_to_entities_requested")
	var entities = ECS.world.query\
		.with_all([C_AssignToFaction])\
		.execute()
	for entity: Entity in entities:
		var c_assign: C_AssignToFaction = entity.get_component(C_AssignToFaction)
		var faction_entity = faction_entities.get(c_assign.faction_id)
		if !faction_entity:
			printerr("faction not found %s %s" % [
				c_assign.faction_id,
				faction_entities.size(),
			])
			continue
		cmd.add_relationship(
			entity,
			Rels.create_belongs_to_faction(
				faction_entity
			)
		)
