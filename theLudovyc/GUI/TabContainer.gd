extends TabContainer

enum WidgetMenus { 
	Market,
	Build,
	Building,
	NaturalResource,
	Buildings,
	Building3D,
}

@onready var widget := %Widget

# Info: this is higher in the hierarchy
@onready var bottom_container = %BottomContainer

@onready var tooltip := %WidgetTooltip

@onready var building_container := $BuildingContainer
@onready var building_container_ui_3d: VBoxContainer = $BuildingContainer_UI_3D

@onready var natural_resource_container = $NaturalResourceContainer

@onready var building_tier_button_container: MarginContainer = $"../../../BuildingTierButtonContainer"

@onready var building_buttons_container: BuildingButtonsContainer = $BuildingButtonsContainer

var event_bus: EventBus


# Called when the node enters the scene tree for the first time.
func _ready():
	event_bus = get_tree().current_scene.get_node_or_null("EventBus")

	if event_bus != null:
		event_bus.send_building_selected.connect(_on_receive_building_selected)
		event_bus.send_building_deselected.connect(_on_receive_building_deselected)
		event_bus.send_current_building_demolished.connect(_on_receive_current_building_demolished)
		
		event_bus.send_building_3D_selected.connect(_on_receive_building_3D_selected)
		event_bus.send_building_3D_deselected.connect(_on_receive_building_3D_deselected)
		
		event_bus.send_natural_resource_selected.connect(_on_receive_send_natural_resource_selected)
		event_bus.send_natural_resource_deselected.connect(_on_receive_send_natural_resource_deselected)

		event_bus.send_building_created.connect(_on_building_event.unbind(1))
		event_bus.send_building_creation_aborted.connect(_on_building_event.unbind(1))
	
	building_buttons_container.mouse_entered_building.connect(_on_mouse_entered_building)
	building_buttons_container.mouse_exited_building.connect(_on_mouse_exited_building)
	building_buttons_container.clicked_on_building.connect(_on_clicked_on_building)


func on_MenuButton_pressed(menu: WidgetMenus):
	if current_tab != menu:
		if current_tab == WidgetMenus.Building \
			or current_tab == WidgetMenus.Market \
			or current_tab == WidgetMenus.Buildings:
			event_bus.ask_deselect_building.emit()

		current_tab = menu

		bottom_container.set_menu_visibility(true)
		if current_tab == WidgetMenus.Buildings:
			building_tier_button_container.show()
		else:
			building_tier_button_container.hide()
		return

	bottom_container.invert_menu_visibility()
	# Info: if we are hiding the container, we hide the tiers too
	if !bottom_container.visible:
		building_tier_button_container.visible = false
	else:
		if current_tab == WidgetMenus.Buildings:
			building_tier_button_container.show()
		else:
			building_tier_button_container.hide()


func _on_BuildMenuButton_pressed():
	# TODO: remove it once we are sure it's not needed anymore
	# on_MenuButton_pressed(WidgetMenus.Build)
	on_MenuButton_pressed(WidgetMenus.Buildings)

	if tooltip.visible:
		tooltip.visible = false


func _on_MarketMenuButton_pressed():
	on_MenuButton_pressed(WidgetMenus.Market)

	if bottom_container.visible:
		if event_bus != null:
			event_bus.ask_select_warehouse.emit()

		tooltip.visible = true

		tooltip.set_money_production_rate_info()
	else:
		if event_bus != null:
			event_bus.ask_deselect_building.emit()

		tooltip.visible = false


func _on_receive_building_selected(building: Building2D):
	bottom_container.set_menu_visibility(true)

	if Buildings.get_building_type(building.building_id) == Buildings.Types.Warehouse:
		if current_tab != WidgetMenus.Market:
			current_tab = WidgetMenus.Market

		if tooltip.visible == false:
			tooltip.visible = true
			tooltip.set_money_production_rate_info()
			
		if building_tier_button_container.visible:
			building_tier_button_container.hide()

		return

	if current_tab != WidgetMenus.Building:
		current_tab = WidgetMenus.Building

	if tooltip.visible:
		tooltip.visible = false
	
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

	building_container.update_infos(building)

func _on_receive_building_deselected(building: Building2D):
	bottom_container.set_menu_visibility(false)
	
	if tooltip.visible:
		tooltip.visible = false
		
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

func _on_receive_current_building_demolished():
	if current_tab == WidgetMenus.Building or current_tab == WidgetMenus.Building3D:
		bottom_container.set_menu_visibility(false)

func _on_receive_building_3D_selected(building: Entity):
	print("_on_receive_building_3D_selected")
	bottom_container.set_menu_visibility(true)
	
	var c_building: C_Building = building.get_component(C_Building)

	if Buildings.get_building_type(c_building.building_type) == Buildings.Types.Warehouse:
		if current_tab != WidgetMenus.Market:
			current_tab = WidgetMenus.Market

		# TODO : fix this
		if tooltip.visible == false:
			tooltip.visible = true
			tooltip.set_money_production_rate_info()
			
		if building_tier_button_container.visible:
			building_tier_button_container.hide()

		return

	if current_tab != WidgetMenus.Building3D:
		current_tab = WidgetMenus.Building3D

	if tooltip.visible:
		tooltip.visible = false
	
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

	building_container_ui_3d.update_infos(building)

func _on_receive_building_3D_deselected(building: Entity):
	bottom_container.set_menu_visibility(false)
	
	if tooltip.visible:
		tooltip.visible = false
		
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

func _on_receive_current_building_3D_demolished():
	if current_tab == WidgetMenus.Building3D:
		bottom_container.set_menu_visibility(false)

func _on_receive_send_natural_resource_selected(natural_resource: NaturalResource):
	bottom_container.set_menu_visibility(true)

	if current_tab != WidgetMenus.NaturalResource:
		current_tab = WidgetMenus.NaturalResource

	if tooltip.visible:
		tooltip.visible = false
		
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

	natural_resource_container.update_infos(natural_resource)

func _on_receive_send_natural_resource_deselected(natural_resource: NaturalResource):
	bottom_container.set_menu_visibility(false)
	
	if tooltip.visible:
		tooltip.visible = false
		
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

func _on_mouse_entered_building(building_id: Buildings.Ids):
	tooltip.set_building_info(building_id)
	tooltip.visible = true

func _on_mouse_exited_building():
	tooltip.visible = false
	tooltip.building_id = -1
	
func _on_clicked_on_building(building_id: Buildings.Ids):
	if event_bus:
		event_bus.ask_create_building.emit(building_id)
	
	# TODO : make it an option
	widget.disable_buttons(true)

	bottom_container.set_menu_visibility(false)
	
	building_tier_button_container.hide()

func _on_building_event():
	# TODO : make it an option
	widget.disable_buttons(false)

	bottom_container.set_menu_visibility(true)
	
	building_tier_button_container.show()

func _on_Tier1MenuButton_pressed() -> void:
	building_buttons_container.show_tier(0)

func _on_Tier2MenuButton2_pressed() -> void:
	building_buttons_container.show_tier(1)

func _on_Tier3MenuButton3_pressed() -> void:
	building_buttons_container.show_tier(2)

func _on_Tier4MenuButton_pressed() -> void:
	building_buttons_container.show_tier(3)
