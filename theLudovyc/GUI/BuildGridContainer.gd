extends GridContainer

var event_bus: EventBus

@onready var widget := %Widget

@onready var bottom_container := %BottomContainer

@onready var tooltip := %WidgetTooltip

# Maps Buildings.Ids
var building_buttons: Dictionary[int, Node] = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var root_node = get_tree().current_scene

	if root_node.has_node("EventBus"):
		event_bus = root_node.get_node("EventBus")

		event_bus.send_building_created.connect(_on_building_event.unbind(1))
		event_bus.send_building_creation_aborted.connect(_on_building_event.unbind(1))
		event_bus.send_building_limit_updated.connect(_on_send_building_limit_updated)

		for child in get_children():
			child.pressed.connect(_on_building_button_pressed.bind(child.building_id))
			child.mouse_entered.connect(_on_building_button_mouse_entered.bind(child.building_id))
			child.mouse_exited.connect(_on_building_button_mouse_exited)
			
			#if child is Button:
				#child.mouse_filter = Control.MOUSE_FILTER_PASS
	
	for child in get_children():
		if child is ButtonBuild:
			building_buttons.set(
				child.building_id,
				child
			)

func _on_building_button_pressed(building_id: Buildings.Ids):
	print("_on_building_button_pressed %s" % [
		building_id
	])
	if event_bus:
		event_bus.ask_create_building.emit(building_id)

	widget.disable_buttons(true)

	bottom_container.set_menu_visibility(false)


func _on_building_event():
	widget.disable_buttons(false)

	bottom_container.set_menu_visibility(true)


func _on_building_button_mouse_entered(building_id: Buildings.Ids):
	print("_on_building_button_mouse_entered %s" % [
		building_id
	])
	tooltip.set_building_info(building_id)
	tooltip.visible = true


func _on_building_button_mouse_exited():
	tooltip.visible = false
	tooltip.building_id = -1
	
func _on_send_building_limit_updated(
	building_id: Buildings.Ids,
	limit_reached: bool
):
	# FIXME : it's not perfect but we don't have a texture for disabled buildings
	print("_on_send_building_limit_updated %s" % [
		get_path(),
	])
	var button: TextureButton = building_buttons[building_id]
	if limit_reached:
		button.disabled = true
	else:
		button.disabled = false
