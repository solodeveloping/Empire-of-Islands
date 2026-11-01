extends Node
class_name TheSelection

@onready var event_bus: EventBus = %EventBus

# FIXME: should we just have one?
# Maybe UI is using specific events

var selection: Node

func _ready() -> void:
	event_bus.send_building_selected.connect(
		_on_event_bus_send_building_selected
	)
	event_bus.send_building_deselected.connect(
		_on_event_bus_send_building_deselected
	)
	event_bus.send_natural_resource_selected.connect(
		_on_event_bus_send_natural_resource_selected
	)
	event_bus.send_natural_resource_deselected.connect(
		_on_event_bus_send_natural_resource_deselected
	)
	event_bus.send_ecs_ship_selected.connect(
		_on_event_bus_send_ecs_ship_selected
	)
	event_bus.send_ecs_ship_deselected.connect(
		_on_event_bus_send_ecs_ship_deselected
	)

func emit_selecton_changed():
	event_bus.send_selection_changed.emit(selection)

func _on_event_bus_send_building_selected(node):
	if node == selection:
		return
	selection = node
	emit_selecton_changed()

func _on_event_bus_send_building_deselected(_node):
	selection = null
	emit_selecton_changed()

func _on_event_bus_send_natural_resource_selected(node):
	if node == selection:
		return
	selection = node
	emit_selecton_changed()

func _on_event_bus_send_natural_resource_deselected(_node):
	selection = null
	emit_selecton_changed()

func _on_event_bus_send_ecs_ship_selected(node):
	print("_on_event_bus_send_ecs_ship_selected")
	if node == selection:
		return
	selection = node
	emit_selecton_changed()

func _on_event_bus_send_ecs_ship_deselected(
	_node
):
	selection = null
	emit_selecton_changed()
