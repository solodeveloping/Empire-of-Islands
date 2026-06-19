extends MarginContainer
class_name Tier1BuildingButtonsContainer

# FIXME: can probably find a way to mutualize all tiers

signal mouse_entered_building(building_id: Buildings.Ids)
signal mouse_exited_building()
signal clicked_on_building(building_id: Buildings.Ids)

var event_bus: EventBus

@onready var infrastructure_grid_container: GridContainer = $VBoxContainer/InfrastructureGridContainer
@onready var services_grid_container: GridContainer = $VBoxContainer/ServicesGridContainer
@onready var companies_grid_container: GridContainer = $VBoxContainer/CompaniesGridContainer
@onready var military_grid_container: GridContainer = $VBoxContainer/MilitaryGridContainer

# FIXME : this should be automated
@onready
var building_buttons = {
	Buildings.Ids.Warehouse: $VBoxContainer/InfrastructureGridContainer/BuildWarehouse,
	Buildings.Ids.MainSquare: $VBoxContainer/InfrastructureGridContainer/BuildMainSquare,
	Buildings.Ids.Tent: $VBoxContainer/InfrastructureGridContainer/BuildResidential,
	Buildings.Ids.Lumberjack: $VBoxContainer/CompaniesGridContainer/BuildLumberjack,
	Buildings.Ids.HunterTent: $VBoxContainer/CompaniesGridContainer/BuildHunterTent,
	Buildings.Ids.Fishery: $VBoxContainer/CompaniesGridContainer/BuildFishery,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	var root_node = get_tree().current_scene

	if root_node.has_node("EventBus"):
		event_bus = root_node.get_node("EventBus")

		event_bus.send_building_limit_updated.connect(_on_send_building_limit_updated)

		bind_buttons(infrastructure_grid_container)
		bind_buttons(services_grid_container)
		bind_buttons(companies_grid_container)
		bind_buttons(military_grid_container)

func bind_buttons(container: GridContainer):
	for child in container.get_children():
		child.pressed.connect(_on_building_button_pressed.bind(child.building_id))
		child.mouse_entered.connect(_on_building_button_mouse_entered.bind(child.building_id))
		child.mouse_exited.connect(_on_building_button_mouse_exited)

func _on_building_button_pressed(building_id: Buildings.Ids):
	clicked_on_building.emit(building_id)

func _on_building_button_mouse_entered(building_id: Buildings.Ids):
	mouse_entered_building.emit(building_id)

func _on_building_button_mouse_exited():
	mouse_exited_building.emit()
	
func _on_send_building_limit_updated(building_id: Buildings.Ids, limit_reached: bool):
	# FIXME : it's not perfect but we don't have a texture for disabled buildings
	if !building_buttons.has(building_id):
		return
	var button: TextureButton = building_buttons[building_id]
	if limit_reached:
		button.disabled = true
	else:
		button.disabled = false
