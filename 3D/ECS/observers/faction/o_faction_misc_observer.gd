extends Observer
class_name O_FactionMiscObserver

# FIXME: those are kinda static
# So we could have a predefined node/refcounted
# Indexed the right way
var faction_entities: Array[Entity] = []

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_any(
				[C_ForECSEvents,]
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
		var c_assign: C_AssignToFaction = entity.get_component(
			C_AssignToFaction
		)
		# FIXME: this is terrible
		var faction_entity = faction_entities.get(c_assign.faction_id)
		if !faction_entity:
			printerr("C_AssignToFaction faction not found %s %s" % [
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
		cmd.remove_component(
			entity,
			C_AssignToFaction
		)
		
		# Info: entity won't have been assigned at this point
		if entity.has_method("update_minimap_display"):
			entity.update_minimap_display.call_deferred()
		
	
	var entities_2 = ECS.world.query\
		.with_all([C_AssignToFactionByAlias])\
		.execute()
	for entity: Entity in entities_2:
		var c_assign: C_AssignToFactionByAlias = entity.get_component(
			C_AssignToFactionByAlias
		)
		var faction_entity = get_faction_entity_with_alias(
			c_assign.alias
		)
		if !faction_entity:
			printerr("C_AssignToFactionByAlias faction not found %s %s" % [
				c_assign.alias,
				faction_entities.size(),
			])
			continue
		cmd.add_relationship(
			entity,
			Rels.create_belongs_to_faction(
				faction_entity
			)
		)
		cmd.remove_component(
			entity,
			C_AssignToFactionByAlias
		)
		
		# Info: entity won't have been assigned at this point
		if entity.has_method("update_minimap_display"):
			entity.update_minimap_display.call_deferred()
		

func get_faction_entity_with_alias(alias: String):
	for entity in faction_entities:
		var c_faction: C_Faction = entity.get_component(
			C_Faction
		)
		if c_faction.def.faction_alias == alias:
			return entity
	return null
