extends Observer
class_name O_MiscObserver

# Info: add generic commands here

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_all([C_Ship]).on_event(ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED),
			_on_add_component_to_entity_requested
		],
	]

func _on_add_component_to_entity_requested(_event: Variant, entity: Entity, data: Variant) -> void:
	cmd.add_component(entity, data.component)
