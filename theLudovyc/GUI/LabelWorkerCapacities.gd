extends Label

@export var population_type: Populations.Types:
	set(value):
		population_type = value

var default_color: Color

func _ready():
	var current_node = get_tree().current_scene

	if current_node.has_node("EventBus"):
		current_node.get_node("EventBus").connect(
			"worker_capacities_updated", _on_EventBus_worker_capacities_updated
		)
		
	default_color = get_theme_color("font_color")
	
	tooltip_text = "%s worker capacities" % [
		Populations.get_population_name(population_type)
	]

func _on_EventBus_worker_capacities_updated(worker_capacities):
	var pop = worker_capacities[population_type]
	text = str(pop)
	if pop < 0:
		add_theme_color_override("font_color", Color.RED)
	elif pop == 0:
		add_theme_color_override("font_color", default_color)
	else:
		add_theme_color_override("font_color", Color.DARK_GREEN)
		
