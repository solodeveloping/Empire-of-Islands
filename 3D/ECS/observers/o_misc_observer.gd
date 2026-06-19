class_name O_MiscObserver
extends Observer

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_all([C_Ship]).on_event(&"add_component_to_entity_requested"),
			_on_add_component_to_entity_requested
		],
	]

func _on_add_component_to_entity_requested(_event: Variant, entity: Entity, data: Variant) -> void:
	cmd.add_component(entity, data.component)
