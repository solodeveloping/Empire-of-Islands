extends VBoxContainer

@onready var mouse_over_object_label: Label = $MouseOverObjectLabel
@onready var mouse_over_object_path_label: Label = $MouseOverObjectPathLabel

func _ready():
	var current_node = get_tree().current_scene

	if current_node.has_node("EventBus"):
		current_node.get_node("EventBus").connect(
			"send_mouse_over_object_changed",
			_on_event_bus_send_mouse_over_object_changed
		)

func _on_event_bus_send_mouse_over_object_changed(
	name_: String,
	object_: Node,
):
	#print("_on_event_bus_send_mouse_over_object_changed")
	mouse_over_object_label.text = name_
	mouse_over_object_path_label.text = object_.get_path()
