extends Observer
class_name O_MiscObserver

# Info: add generic commands here

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_any([C_Ship, C_PopUnit]).on_event(ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED),
			_on_add_component_to_entity_requested
		],
		[
			# FIXME: find a generic with_*
			q.with_any([C_Ship, C_PopUnit]).on_event(ECSEvents.ADD_COMPONENTS_TO_ENTITY_REQUESTED),
			_on_add_components_to_entity_requested
		],
	]

func _on_add_component_to_entity_requested(_event: Variant, entity: Entity, data: Variant) -> void:
	cmd.add_component(entity, data.component)

func _on_add_components_to_entity_requested(_event: Variant, entity: Entity, data: Variant) -> void:
	print("_on_add_components_to_entity_requested %s" % [
		entity.name,
	])
	cmd.add_components(entity, data.components)
