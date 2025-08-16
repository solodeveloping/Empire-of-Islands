extends Label

@export var population_type: Populations.Types:
	set(value):
		population_type = value

# Called when the node enters the scene tree for the first time.
func _ready():
	var current_node = get_tree().current_scene

	if current_node.has_node("EventBus"):
		current_node.get_node("EventBus").connect(
			"population_updated", _on_EventBus_popupation_updated
		)

	pass  # Replace with function body.


func _on_EventBus_popupation_updated(population_count):
	text = str(population_count[population_type])
