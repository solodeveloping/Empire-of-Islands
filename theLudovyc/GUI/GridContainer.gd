extends GridContainer

var event_bus: EventBus

@export
var button_disabled_color: Color

@onready var widget := %Widget

@onready var bottom_container := %BottomContainer

@onready var tooltip := %WidgetTooltip

# FIXME : this should be automated
@onready
var building_buttons = {
	Buildings.Ids.Tent: $BuildResidential,
	Buildings.Ids.Lumberjack: $BuildLumberjack,
	Buildings.Ids.HunterTent: $BuildHunterTent,
	Buildings.Ids.Hut: $BuildHut,
	Buildings.Ids.Sawmill: $BuildSawmill,
	Buildings.Ids.Farm: $BuildFarm,
	Buildings.Ids.PotatoField: $BuildPotatoField,
	Buildings.Ids.Pigsty: $BuildPigsty,
	Buildings.Ids.Butchery: $BuildButchery,
}

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


func _on_building_button_pressed(building_id: Buildings.Ids):
	if event_bus:
		event_bus.ask_create_building.emit(building_id)

	widget.disable_buttons(true)

	bottom_container.set_menu_visibility(false)


func _on_building_event():
	widget.disable_buttons(false)

	bottom_container.set_menu_visibility(true)


func _on_building_button_mouse_entered(building_id: Buildings.Ids):
	tooltip.set_building_info(building_id)
	tooltip.visible = true


func _on_building_button_mouse_exited():
	tooltip.visible = false
	tooltip.building_id = -1
	
func _on_send_building_limit_updated(building_id: Buildings.Ids, limit_reached: bool):
	# FIXME : it's not perfect but we don't have a texture for disabled buildings
	var button: TextureButton = building_buttons[building_id]
	if limit_reached:
		button.disabled = true
	else:
		button.disabled = false
