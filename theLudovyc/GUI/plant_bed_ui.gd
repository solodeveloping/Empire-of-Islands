extends MarginContainer
class_name PlantBedUI

# TODO: hide this when appropriate

signal selected_resource_id(
	new_resource_id: int,
)

@onready var h_box_container: HBoxContainer = $VBoxContainer/HBoxContainer

var event_bus: EventBus

func _ready() -> void:
	if get_tree().current_scene.has_node("EventBus"):
		event_bus = get_tree().current_scene.get_node("EventBus")
	
	for child: PlantBedRoundButtonUI in h_box_container.get_children():
		child.clicked_on.connect(
			_on_button_clicked_on
		)

func update_display(
	selected_resource_id: int,
):
	for child: PlantBedRoundButtonUI in h_box_container.get_children():
		if child.builtin_resource_id == selected_resource_id:
			child.update_selected(
				true
			)
		else:
			child.update_selected(
				false
			)

func _on_button_clicked_on(
	ui: PlantBedRoundButtonUI,
	_is_selected: bool
):
	for child: PlantBedRoundButtonUI in h_box_container.get_children():
		if ui == child:
			continue
		child.update_selected(
			false
		)
	
	selected_resource_id.emit(
		ui.builtin_resource_id,
	)
	
