extends TabContainer

enum WidgetMenus { 
	Market,
	Build,
	Building,
	NaturalResource,
	Buildings,
	Building3D,
	Unit3D,
	Ship3D,
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

@onready var unit_container_ui_3d: UnitContainerUI3D = $UnitContainer_UI_3D

@onready var ship_container_ui_3d: ShipContainerUI3D = $ShipContainer_UI_3D

@onready var market_ui: MarketUI = %MarketUI

var event_bus: EventBus

# FIXME: should it be here?
# Maybe we should unify any interface the UI could need into one node
# Or maybe not
var the_buildings_cost: TheBuildingsCost
var the_storage: GMSimpleStorage

var USE_ECS: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	var current_scene: Node = get_tree().current_scene
	event_bus = current_scene.get_node_or_null("EventBus")
	the_buildings_cost = current_scene.get_node_or_null("TheBuildingsCost")
	the_storage = current_scene.get_node_or_null("GMSimpleStorage")

	if event_bus != null:
		event_bus.send_building_selected.connect(_on_receive_building_selected)
		event_bus.send_building_deselected.connect(_on_receive_building_deselected)
		event_bus.send_current_building_demolished.connect(_on_receive_current_building_demolished)
		
		event_bus.send_building_3D_selected.connect(_on_receive_building_3D_selected)
		event_bus.send_building_3D_deselected.connect(_on_receive_building_3D_deselected)
		
		event_bus.send_unit_3D_selected.connect(_on_receive_unit_3D_selected)
		event_bus.send_unit_3D_deselected.connect(_on_receive_unit_3D_deselected)
		
		event_bus.send_ship_3D_selected.connect(_on_receive_ship_3D_selected)
		event_bus.send_ship_3D_deselected.connect(_on_receive_ship_3D_deselected)
		
		event_bus.send_natural_resource_selected.connect(_on_receive_send_natural_resource_selected)
		event_bus.send_natural_resource_deselected.connect(_on_receive_send_natural_resource_deselected)

		event_bus.send_building_created.connect(_on_building_event.unbind(1))
		event_bus.send_building_creation_aborted.connect(_on_building_event.unbind(1))
		
		# Info: this allow to request to show the buildings button list programmatically
		event_bus.send_show_buildings_button_ui.connect(_on_event_bus_send_show_buildings_button_ui)
	
		event_bus.send_trades_updated.connect(
			_on_event_bus_send_trades_updated
		)
	
	building_buttons_container.mouse_entered_building.connect(_on_mouse_entered_building)
	building_buttons_container.mouse_exited_building.connect(_on_mouse_exited_building)
	building_buttons_container.clicked_on_building.connect(_on_clicked_on_building)

	

	market_ui.hide()

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

# Info: this is called when we click on the button to build any building
func _on_BuildMenuButton_pressed():
	print("_on_BuildMenuButton_pressed")
	# TODO: remove it once we are sure it's not needed anymore
	# on_MenuButton_pressed(WidgetMenus.Build)
	on_MenuButton_pressed(WidgetMenus.Buildings)

	if tooltip.visible:
		tooltip.visible = false

func _on_MarketMenuButton_pressed():
	if !USE_ECS:
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
	else:
		handle_display_market_ecs_ui()

func handle_display_market_ecs_ui():
	tooltip.visible = false
	market_ui.visible = !market_ui.visible
	
	if market_ui.visible:
		event_bus.notify_market_menu_opened.emit()
	else:
		event_bus.notify_market_menu_closed.emit()
		

func _on_event_bus_send_show_buildings_button_ui():
	print("_on_event_bus_send_show_buildings_button_ui")
	_on_BuildMenuButton_pressed()

# Info: this is called when the user select a building on the map
func _on_receive_building_selected(building: Building2D):
	print("_on_receive_building_selected")
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

# Info: this is called when the user select a building on the map
func _on_receive_building_3D_selected(building: Entity):
	print("_on_receive_building_3D_selected")
	bottom_container.set_menu_visibility(true)
	
	var c_building: C_Building = building.get_component(C_Building)

	if Buildings.get_building_type(c_building.building_type) == Buildings.Types.Warehouse:
		# FIXME: this is kinda bad
		if USE_ECS:
			handle_display_market_ecs_ui()
			return
		
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
	print("_on_receive_building_3D_deselected")
	
	bottom_container.set_menu_visibility(false)
	
	if tooltip.visible:
		tooltip.visible = false
		
	if building_tier_button_container.visible:
		building_tier_button_container.hide()
	
	# FIXME: this is kinda bad
	var c_building: C_Building = building.get_component(C_Building)
	if Buildings.get_building_type(c_building.building_type) == Buildings.Types.Warehouse:
		# FIXME: this is kinda bad
		if USE_ECS:
			handle_display_market_ecs_ui()
			return

# Info: this is called when the user select an unit on the map
func _on_receive_unit_3D_selected(unit: Entity):
	print("_on_receive_building_3D_selected")
	bottom_container.set_menu_visibility(true)

	if current_tab != WidgetMenus.Unit3D:
		current_tab = WidgetMenus.Unit3D

	if tooltip.visible:
		tooltip.visible = false
	
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

	unit_container_ui_3d.update_infos(unit)

func _on_receive_unit_3D_deselected(unit: Entity):
	bottom_container.set_menu_visibility(false)
	
	if tooltip.visible:
		tooltip.visible = false
		
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

# Info: this is called when the user select an ship on the map
func _on_receive_ship_3D_selected(unit: Entity):
	print("_on_receive_building_3D_selected")
	bottom_container.set_menu_visibility(true)

	if current_tab != WidgetMenus.Ship3D:
		current_tab = WidgetMenus.Ship3D

	if tooltip.visible:
		tooltip.visible = false
	
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

	ship_container_ui_3d.update_infos(unit)

func _on_receive_ship_3D_deselected(unit: Entity):
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

# Info: this is called when the mouse is over a button of a building
func _on_mouse_entered_building(building_id: Buildings.Ids):
	print("_on_mouse_entered_building %s" % [
		building_id,
	])
	if USE_ECS:
		# FIX%E: we are modifying the array
		# It's duplicated in the method
		# what would be the best?
		var costs = the_buildings_cost.get_building_costs(building_id)
		for cost: Array in costs:
			var has_resouce = the_storage.has_at_least(
				cost[0],
				cost[1]
			)
			cost.push_back(
				has_resouce
			)
		# TODO: hard coding is not good
		var building_name = Buildings.get_building_name(building_id)
		tooltip._set_building_info(
			building_id,
			building_name,
			costs,
		)
	else:
		tooltip.set_building_info(building_id)
	tooltip.visible = true

func _on_mouse_exited_building():
	tooltip.visible = false
	tooltip.building_id = -1
	
func _on_clicked_on_building(building_id: Buildings.Ids):
	print("TabContainer:_on_clicked_on_building")
	if event_bus:
		event_bus.ask_create_building.emit(building_id)
		
	# FIXME: I can't make a version of the code where we hide
	# the ui once we click to work
	
	# TODO : make it an option
	#widget.disable_buttons(true)

	#bottom_container.set_menu_visibility(false)
	
	#building_tier_button_container.hide()

func _on_building_event():
	print("_on_building_event")
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

func _on_event_bus_send_trades_updated(
	trades: Array[TradeResourceDefinition]
):
	market_ui.update_trades(
		trades
	)
