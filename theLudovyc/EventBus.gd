extends Node
class_name EventBus

# ask UI -> MODEL
# send MODEL -> UI

## BUILDING
signal ask_create_building(building_id)
signal send_building_created(building_id)
signal send_building_creation_aborted(building_id)
signal send_building_limit_updated(building_id, limit_reached)

signal send_building_selected(building_node)
signal send_building_deselected(building_node)

signal ask_deselect_building
signal ask_select_warehouse

signal ask_demolish_current_building
signal send_current_building_demolished

## NATURAL RESOURCE
signal send_natural_resource_selected(natural_resource)
signal send_natural_resource_deselected(natural_resource)

## POPULATION / WORKER
signal population_updated(population_count)
signal housing_capacity_updated(housing_capacity)
signal available_workers_updated(available_workers_amount)
signal worker_capacities_updated(available_worker_capacities_amount)

## RESOURCES
signal resource_updated(resource_type, resource_amount)
signal resource_prodution_rate_updated(resource_type, production_rate)

## MONEY
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

## CITY
signal send_city_name_changed(new_city_name)
