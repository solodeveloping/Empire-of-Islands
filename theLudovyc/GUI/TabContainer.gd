extends TabContainer
## This is the class that controls which UI is displayed
## On the right, below the minimap

# FIXME: too many things are in this

enum WidgetMenus { 
	Market,
	Build,
	Building,
	NaturalResource,
	Buildings,
	Building3D,
	Unit3D,
	Ship3D,
	Animal3D,
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

@onready var animal_container_ui_3d: AnimalContainerUI3D = $AnimalContainer_UI_3D

@onready var build_position_rotation_ui: BuildPositionRotationUI = $"../../../../BuildPositionRotationUi"

@onready var plant_bed_ui: PlantBedUI = $"../../../../PlantBedUi"

@onready var market_ui: MarketUI = %MarketUI

@onready var zoom_in_menu_button: TextureButton = $"../../../ZoomInMenuButton"
@onready var zoom_out_menu_button: TextureButton = $"../../../ZoomOutMenuButton"

var event_bus: EventBus

# FIXME: should it be here?
# Maybe we should unify any interface the UI could need into one node
# Or maybe not
var the_buildings_cost: TheBuildingsCost
var the_storage: GMSimpleStorage
# FIXME: it's not very good?
var faction: Faction_ECS
var c_faction: C_Faction

var USE_ECS: bool = true

var local_player_faction_id: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	var current_scene: Node = get_tree().current_scene
	event_bus = current_scene.get_node_or_null("EventBus")
	the_buildings_cost = current_scene.get_node_or_null("%TheBuildingsCost")
	
	# FIXME: this does way too much?

	if event_bus != null:
		event_bus.send_use_ecs_changed.connect(
			_on_send_use_ecs_changed
		)
		
		event_bus.send_building_selected.connect(
			_on_receive_building_selected_2d
		)
		event_bus.send_building_deselected.connect(
			_on_receive_building_deselected_2d
		)
		event_bus.send_current_building_demolished.connect(
			_on_receive_current_building_demolished
		)
		
		event_bus.send_building_3D_selected.connect(
			_on_receive_building_selected_3D
		)
		event_bus.send_building_3D_deselected.connect(
			_on_receive_building_selected_3D
		)
		
		event_bus.send_unit_3D_selected.connect(
			_on_receive_unit_3D_selected
		)
		event_bus.send_unit_3D_deselected.connect(
			_on_receive_unit_3D_deselected
		)
		
		# TODO: replace properly?
		event_bus.send_ship_3D_selected.connect(
			_on_receive_ship_3D_selected
		)
		event_bus.send_ship_3D_deselected.connect(
			_on_receive_ship_3D_deselected
		)
		event_bus.send_ecs_ship_selected.connect(
			_on_receive_ship_3D_selected
		)
		event_bus.send_ecs_ship_deselected.connect(
			_on_receive_ship_3D_deselected
		)
		
		event_bus.send_animal_3D_selected.connect(
			_on_receive_animal_3D_selected
		)
		event_bus.send_animal_3D_deselected.connect(
			_on_receive_animal_3D_deselected
		)
		
		event_bus.send_natural_resource_selected.connect(
			_on_receive_send_natural_resource_selected
		)
		event_bus.send_natural_resource_deselected.connect(
			_on_receive_send_natural_resource_deselected
		)

		event_bus.send_building_created.connect(
			_on_building_event.unbind(1)
		)
		event_bus.send_building_creation_aborted.connect(
			_on_building_event.unbind(1)
		)
		
		event_bus.send_ground_bed_3D_selected.connect(
			_on_event_bus_send_ground_bed_3D_selected
		)
		event_bus.send_ground_bed_3D_deselected.connect(
			_on_event_bus_send_ground_bed_3D_deselected
		)
		
		# Info: this allow to request to show the buildings button list programmatically
		event_bus.send_show_buildings_button_ui.connect(
			_on_event_bus_send_show_buildings_button_ui
		)
	
		event_bus.send_trades_updated.connect(
			_on_event_bus_send_trades_updated
		)
		
		event_bus.send_local_player_faction_id_changed.connect(
			_on_event_bus_send_local_player_faction_id_changed
		)
		event_bus.send_local_player_faction_storage_changed.connect(
			_on_event_bus_send_local_player_faction_storage_changed
		)
		event_bus.send_local_player_faction_changed.connect(
			_on_event_bus_send_local_player_faction_changed
		)
		
		event_bus.send_minimap_enable_zoom_in.connect(
			_on_event_bus_send_minimap_enable_zoom_in
		)
		event_bus.send_minimap_disable_zoom_in.connect(
			_on_event_bus_send_minimap_disable_zoom_in
		)
		event_bus.send_minimap_enable_zoom_out.connect(
			_on_event_bus_send_minimap_enable_zoom_out
		)
		event_bus.send_minimap_disable_zoom_out.connect(
			_on_event_bus_send_minimap_disable_zoom_out
		)
		
	
	building_buttons_container.mouse_entered_building.connect(
		_on_mouse_entered_building
	)
	building_buttons_container.mouse_exited_building.connect(
		_on_mouse_exited_building
	)
	building_buttons_container.clicked_on_building.connect(
		_on_clicked_on_building
	)

	plant_bed_ui.selected_resource_id.connect(
		_on_plant_bed_ui_selected_resource_id
	)

	market_ui.hide()

func _on_send_use_ecs_changed(use_ecs_: bool):
	USE_ECS = use_ecs_

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
func _on_receive_building_selected_2d(building: Building2D):
	print("_on_receive_building_selected_2d")
	bottom_container.set_menu_visibility(true)
	
	if USE_ECS:
		#var entity: Entity = building.entity_node
		if Buildings.get_building_type(building.building_id) == Buildings.Types.Warehouse:
			handle_display_market_ecs_ui()
			return
		
		if current_tab != WidgetMenus.Building3D:
			current_tab = WidgetMenus.Building3D

		if tooltip.visible:
			tooltip.visible = false
		
		if building_tier_button_container.visible:
			building_tier_button_container.hide()

		building_container_ui_3d.update_infos(building.entity_node)
		
	else:
		if Buildings.get_building_type(building.building_id) == Buildings.Types.Warehouse:
			if current_tab != WidgetMenus.Market:
				current_tab = WidgetMenus.Market

			if tooltip.visible == false:
				tooltip.visible = true
				tooltip.set_money_production_rate_info()
				
			if building_tier_button_container.visible:
				building_tier_button_container.hide()

			return
	
	# TODO: make sure buildings get hidden when clicking
	# on market and stuff
	if current_tab != WidgetMenus.Building:
		current_tab = WidgetMenus.Building

	if tooltip.visible:
		tooltip.visible = false
	
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

	building_container.update_infos(building)

func _on_receive_building_deselected_2d(_building: Building2D):
	bottom_container.set_menu_visibility(false)
	
	if tooltip.visible:
		tooltip.visible = false
		
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

func _on_receive_current_building_demolished():
	if current_tab == WidgetMenus.Building or current_tab == WidgetMenus.Building3D:
		bottom_container.set_menu_visibility(false)

# Info: this is called when the user select a building on the map
func _on_receive_building_selected_3D(building: Entity):
	print("_on_receive_building_selected_3D")
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

func _on_receive_unit_3D_deselected(_unit: Entity):
	print("_on_receive_unit_3D_deselected")
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

func _on_receive_ship_3D_deselected(
	_unit: Entity
):
	print("_on_receive_ship_3D_deselected")
	bottom_container.set_menu_visibility(false)
	
	if tooltip.visible:
		tooltip.visible = false
		
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

func _on_receive_animal_3D_selected(unit: Entity):
	print("_on_receive_animal_3D_selected")
	bottom_container.set_menu_visibility(true)

	if current_tab != WidgetMenus.Animal3D:
		current_tab = WidgetMenus.Animal3D

	if tooltip.visible:
		tooltip.visible = false
	
	if building_tier_button_container.visible:
		building_tier_button_container.hide()

	animal_container_ui_3d.update_infos(unit, local_player_faction_id)

func _on_receive_animal_3D_deselected(_unit: Entity):
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

func _on_receive_send_natural_resource_deselected(
	_natural_resource: NaturalResource
):
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
			var has_resource: bool = false
			if cost[0] == Resources.Types.Gold:
				has_resource = cost[1] <= c_faction.gold_count
			else:
				has_resource = the_storage.has_at_least(
					cost[0],
					cost[1]
				)
			cost.push_back(
				has_resource
			)
		
		# TODO: hard coding the names and all that is not good
		var building_name = Buildings.get_building_name(building_id)
		
		if costs.is_empty():
			printerr("costs are empty for %s %s" % [
				building_id,
				building_name,
			])
		
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

func _on_event_bus_send_local_player_faction_id_changed(
	local_player_faction_id_: int,
):
	local_player_faction_id = local_player_faction_id_
	
func _on_event_bus_send_local_player_faction_storage_changed(
	storage: GMSimpleStorage
):
	the_storage = storage

func _on_event_bus_send_local_player_faction_changed(
	faction_: Faction_ECS,
	c_faction_: C_Faction,
):
	faction = faction_
	c_faction = c_faction_

func _on_ZoomInMenuButton_pressed() -> void:
	event_bus.ask_minimap_zoom_in.emit()

func _on_ZoomOutMenuButton_pressed() -> void:
	event_bus.ask_minimap_zoom_out.emit()

func _on_event_bus_send_minimap_enable_zoom_in():
	zoom_in_menu_button.disabled = false

func _on_event_bus_send_minimap_disable_zoom_in():
	zoom_in_menu_button.disabled = true
	
func _on_event_bus_send_minimap_enable_zoom_out():
	zoom_out_menu_button.disabled = false

func _on_event_bus_send_minimap_disable_zoom_out():
	zoom_out_menu_button.disabled = true

func _on_event_bus_send_ground_bed_3D_deselected(
	_ground_bed: GroundDirtBed_1,
	_selected_ground_bed_id: int,
	_building_entity: Entity,
):
	print("_on_event_bus_send_ground_bed_3D_deselected hide")
	plant_bed_ui.hide()

func _on_event_bus_send_ground_bed_3D_selected(
	ground_bed: GroundDirtBed_1,
	_selected_ground_bed_id: int,
	_building_entity: Entity,
):
	plant_bed_ui.update_display(
		ground_bed.current_resource_id
	)
	
	plant_bed_ui.show()

func _on_plant_bed_ui_selected_resource_id(
	resource_id: int
):
	event_bus.ask_change_ground_bed_resource_id.emit(
		resource_id
	)
