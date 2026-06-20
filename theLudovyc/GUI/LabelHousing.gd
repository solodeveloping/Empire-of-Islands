extends Label

@export var population_type: Populations.Types:
	set(value):
		population_type = value

func _ready():
	var current_node = get_tree().current_scene

	if current_node.has_node("EventBus"):
		current_node.get_node("EventBus").connect(
			"housing_capacity_updated", _on_EventBus_housing_capacity_updated
		)
		
	tooltip_text = "Current %s housing capacity" % [
		Populations.get_population_name(population_type)
	]

func _on_EventBus_housing_capacity_updated(housing_capacity):
	text = str(housing_capacity[population_type])
