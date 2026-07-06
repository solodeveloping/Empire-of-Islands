extends VBoxContainer

@onready var mouse_over_object_label: Label = $MouseOverObjectLabel
@onready var mouse_over_object_path_label: Label = $MouseOverObjectPathLabel

var event_bus: EventBus

func _ready():
	var current_node = get_tree().current_scene

	if current_node.has_node("EventBus"):
		event_bus = current_node.get_node("EventBus")
		event_bus.send_mouse_over_object_changed.connect(
			_on_event_bus_send_mouse_over_object_changed
		)

func _on_event_bus_send_mouse_over_object_changed(
	name_: String,
	object_: Node,
):
	#print("_on_event_bus_send_mouse_over_object_changed")
	mouse_over_object_label.text = name_
	mouse_over_object_path_label.text = object_.get_path()

func _on_OptionButton_item_selected(index: int) -> void:
	event_bus.ask_change_ocean_visual.emit(index)

func _on_Button_button_up() -> void:
	event_bus.ask_debug_spawn_ship.emit()
