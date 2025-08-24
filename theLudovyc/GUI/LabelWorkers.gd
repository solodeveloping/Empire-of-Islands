extends Label

@export var population_type: Populations.Types:
	set(value):
		population_type = value

var default_color: Color

# Called when the node enters the scene tree for the first time.
func _ready():
	var current_node = get_tree().current_scene

	if current_node.has_node("EventBus"):
		current_node.get_node("EventBus").connect(
			"available_workers_updated", _on_EventBus_available_workers_updated_updated
		)
		
	default_color = get_theme_color("font_color")

	pass  # Replace with function body.


func _on_EventBus_available_workers_updated_updated(available_workers_amount):
	var pop = available_workers_amount[population_type]
	text = "(" + Helper.get_string_from_signed_int(pop) + ")"
	if pop < 0:
		add_theme_color_override("font_color", Color.RED)
	elif pop == 0:
		add_theme_color_override("font_color", default_color)
	else:
		add_theme_color_override("font_color", Color.DARK_GREEN)
		
