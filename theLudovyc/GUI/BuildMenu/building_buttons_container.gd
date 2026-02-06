extends TabContainer
class_name BuildingButtonsContainer

signal mouse_entered_building(building_id: Buildings.Ids)
signal mouse_exited_building()
signal clicked_on_building(building_id: Buildings.Ids)

@onready var tier_1_building_buttons_container: Tier1BuildingButtonsContainer = $Tier1BuildingButtonsContainer
@onready var tier_2_building_buttons_container: Tier2BuildingButtonsContainer = $Tier2BuildingButtonsContainer
@onready var tier_3_building_buttons_container: Tier3BuildingButtonsContainer = $Tier3BuildingButtonsContainer

func _ready() -> void:
	tier_1_building_buttons_container.mouse_entered_building.connect(_on_mouse_entered_building)
	tier_1_building_buttons_container.mouse_exited_building.connect(_on_mouse_exited_building)
	tier_1_building_buttons_container.clicked_on_building.connect(_on_clicked_on_building)
	
	tier_2_building_buttons_container.mouse_entered_building.connect(_on_mouse_entered_building)
	tier_2_building_buttons_container.mouse_exited_building.connect(_on_mouse_exited_building)
	tier_2_building_buttons_container.clicked_on_building.connect(_on_clicked_on_building)
	
	tier_3_building_buttons_container.mouse_entered_building.connect(_on_mouse_entered_building)
	tier_3_building_buttons_container.mouse_exited_building.connect(_on_mouse_exited_building)
	tier_3_building_buttons_container.clicked_on_building.connect(_on_clicked_on_building)

func show_tier(tier: int):
	current_tab = tier

func _on_mouse_entered_building(building_id: Buildings.Ids):
	mouse_entered_building.emit(building_id)
	
func _on_mouse_exited_building():
	mouse_exited_building.emit()
	
func _on_clicked_on_building(building_id: Buildings.Ids):
	clicked_on_building.emit(building_id)
