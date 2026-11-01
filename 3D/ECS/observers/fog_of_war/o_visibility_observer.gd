extends Observer
class_name O_VisibilityObserver

# match/unmatch: entity removed, does not do the thing
# added/removed: component removed

var event_bus: EventBus

func _ready() -> void:
	var current_scene = get_tree().current_scene
	event_bus = current_scene.get_node("%EventBus")

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_any([C_CircularVision,]).on_match(),
			_on_vision_match
		],
		[
			q.with_any([C_CircularVision,]).on_unmatch(),
			_on_vision_unmatch
		],
	]

func _on_vision_match(
	_event: Variant,
	entity: Entity,
	_data: Variant
) -> void:
	event_bus.send_visible_entity_added.emit(entity)

func _on_vision_unmatch(
	_event: Variant,
	entity: Entity,
	_data: Variant
) -> void:
	event_bus.send_visible_entity_removed.emit(entity)
