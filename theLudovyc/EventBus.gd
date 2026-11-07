extends Node
class_name EventBus

# ask UI -> MODEL
# notify UI -> MODEL
# send MODEL -> UI

## SETTINGS
@warning_ignore_start("unused_signal")
signal send_use_ecs_changed(use_ecs: bool)

## BUILDING
signal ask_create_building(building_id)
signal send_building_created(building_id)

signal send_building_creation_aborted(building_id)
signal send_building_limit_updated(building_id, limit_reached)
signal send_show_buildings_button_ui()

# TODO: rename properly (2d/3d)
signal send_building_selected(building_node)
signal send_building_deselected(building_node)

signal send_building_3D_selected(building_entity: Entity)
signal send_building_3D_deselected(building_entity: Entity)

signal send_ground_bed_3D_selected(
	ground_bed: GroundDirtBed_1,
	selected_ground_bed_id: int,
	building_entity: Entity,
)
signal send_ground_bed_3D_deselected(
	ground_bed: GroundDirtBed_1,
	selected_ground_bed_id: int,
	building_entity: Entity,
)
signal ask_change_ground_bed_resource_id(
	resource_id: int
)

signal ask_deselect_building
signal ask_select_warehouse

signal ask_demolish_current_building
signal send_current_building_demolished

signal send_show_build_position_rotation_ui()
signal send_hide_build_position_rotation_ui()

signal ask_rotate_building_left(new_value: float, change: float)
signal ask_rotate_building_right(new_value: float, change: float)
signal ask_rotate_building(new_value: float)
signal ask_enable_snap_to_objects()
signal ask_disable_snap_to_objects()

## NATURAL RESOURCE
signal send_natural_resource_selected(natural_resource)
signal send_natural_resource_deselected(natural_resource)

## POPULATION / WORKER
signal population_updated(population_count)
signal housing_capacity_updated(housing_capacity)
# FIXME: we are using it as "people_with_a_job" currently, in 3D
signal available_workers_updated(available_workers_amount)
signal worker_capacities_updated(available_worker_capacities_amount)

signal send_unit_3D_selected(unit: Entity)
signal send_unit_3D_deselected(unit: Entity)

# FIXME: should it be the same as unit?
signal send_ship_3D_selected(unit: Entity)
signal send_ship_3D_deselected(unit: Entity)

signal send_animal_3D_selected(unit: Entity)
signal send_animal_3D_deselected(unit: Entity)

## RESOURCES
signal send_resource_updated(resource_type, resource_amount)
signal send_resource_prodution_rate_updated(resource_type, production_rate)

## MONEY
# FIXME: should be send_*
signal money_updated(money_amount)
signal money_production_rate_updated(money_production_rate)

## ORDER
signal ask_create_new_order(resource_type)
signal send_create_new_order(resource_type)
signal send_create_new_order_with_values(resource_type, buy_amount, sell_amount)

signal ask_remove_order(resource_type)
signal send_remove_order(resource_type)

signal ask_update_order_buy(resource_type, buy_amount)
signal send_update_order_buy(resource_type, buy_amount)

signal ask_update_order_sell(resource_type, sell_amount)
signal send_update_order_sell(resource_type, sell_amount)

signal send_trades_updated(trades: Array[TradeResourceDefinition])
signal notify_market_menu_opened()
signal notify_market_menu_closed()

## CITY
signal send_city_name_changed(new_city_name)

# FACTION
signal send_local_player_faction_id_changed(
	local_player_faction_id: int,
)
signal send_local_player_faction_storage_changed(
	storage: GMSimpleStorage
)
signal send_local_player_faction_changed(
	faction: Faction_ECS,
	c_faction: C_Faction
)

## SHIPS
signal send_all_ecs_ships_updated(
	ships: Array[Entity],
)
signal send_ecs_ship_spawned(
	ship: Entity,
)
signal send_ecs_ship_destroyed(
	ship: Entity,
)
signal send_ecs_ship_selected(
	ship: Entity,
)
signal send_ecs_ship_deselected(
	ship: Entity,
)
# For the appearance/disappearance
signal send_ecs_ship_appeared(
	ship: Entity,
)
signal send_ecs_ship_disappeared(
	ship: Entity,
)

## LOOT
# FIXME: what's the right event word for it? instead of "updated"
# FIXME: not sure if we should have this one + the other one?
signal send_mouse_over_loot_updated(
	object_: Entity,
)
signal send_mouse_not_over_loot_updated(
	object_: Entity,
)

## MINIMAP
signal send_minimap_data_changed()
signal ask_minimap_zoom_in()
signal ask_minimap_zoom_out()
signal send_minimap_enable_zoom_in()
signal send_minimap_disable_zoom_in()
signal send_minimap_enable_zoom_out()
signal send_minimap_disable_zoom_out()

## FOG OF WAR
signal send_visible_entity_added(entity: Entity)
signal send_visible_entity_removed(entity: Entity)

## SELECTION
signal send_selection_changed(node)

## MISC
signal send_mouse_over_object_changed(
	object_name: String,
	object_: Node,
)

## DEBUG
signal ask_change_ocean_visual(selected_ocean_visual_id: int)
signal ask_debug_spawn_ship()
