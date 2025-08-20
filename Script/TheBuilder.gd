extends Node

const Building_2D_Scene = preload("res://theLudovyc/Building/Building2D.tscn")

var warehouse: Building2D

@onready var node_buildings:Node = %Buildings
@onready var node_buildings_preview:Node = %BuildingsPreview

@onready var tilemap:TileMap = %TileMap

@onready var event_bus = $"../EventBus"

@onready var the_storage = $"../TheStorage"
@onready var the_population = $"../ThePopulation"
@onready var the_bank = $"../TheBank"

var buildings_count = {
	Buildings.Ids.Lumberjack: 0,
}

var maintenance_cost := 0:
	set(value):
		maintenance_cost = value
		the_bank.update_money_production_rate()

## Use this method to obtain an instance of the building
## It is used to get a floating building that follows the mouse pos for instance
func instantiate_building(building_id: Buildings.Ids) -> Building2D:
	var instance = Building_2D_Scene.instantiate() as Building2D
	
	instance.building_id = building_id
	
	node_buildings_preview.add_child(instance)
	
	return instance
	
func build(building_id: Buildings.Ids, pos: Vector2) -> Building2D:
	var building = instantiate_building(building_id)
	
	if building == null:
		push_error("Cannot create a building from null instance")
		
		return null
	
	building.position = pos
	
	tilemap.conclude_building_construction(building)

	building.build()
	
	conclude_building_construction(building_id)
	
	return building
	
func build_warehouse(pos: Vector2):
	warehouse = build(Buildings.Ids.Warehouse, pos)

func conclude_building_construction(building_id: Buildings.Ids):
	var preview_buildings = node_buildings_preview.get_children()
	for building in preview_buildings:
		node_buildings_preview.remove_child(building)
		node_buildings.add_child(building)
		
	if !buildings_count.has(building_id):
		buildings_count[building_id] = 1
	else:
		buildings_count[building_id] += 1
	
	var limit = Buildings.get_max_count(building_id)
	if limit != -1:
		if buildings_count[building_id] >= limit:
			event_bus.send_building_limit_updated.emit(building_id, true)
			
	maintenance_cost += Buildings.get_maintenance_cost(building_id)

func conclude_building_destruction(building_id:Buildings.Ids):
	var previous_count = buildings_count[building_id]
	buildings_count[building_id] -= 1
	var limit = Buildings.get_max_count(building_id)
	if limit != -1:
		if previous_count == limit:
			event_bus.send_building_limit_updated.emit(building_id, false)
			
	maintenance_cost -= Buildings.get_maintenance_cost(building_id)

func get_buildings() -> Array[Node]:
	return node_buildings.get_children()

# FIXME : we could find a way to make sure this is called
# after TheFactory
func _on_TheTicker_cycle() -> void:
	var buildings: Array[Node] = get_buildings()
	var one_building_has_no_food = false
	var money = 0
	for building in buildings:
		if building is Building2D:
			var building_type = Buildings.get_building_type(building.building_id)
			# FIXME : we could have operative costs for the buildings
			# Different than the normal ones depending on whether 
			# they are active or not
			if building_type == Buildings.Types.Residential:
				if one_building_has_no_food:
					_handle_building_and_food_result(
						building,
						false
					)
					continue
				
				var had_enough_food = true
				var comsumptions = Buildings.get_food_consumption(building.building_id)
				
				for consumption in comsumptions:
					var remaining = 0
					var type = consumption[Buildings.ComsumptionDatas.ResourceType]
					if type != -1:
						var result = the_storage.try_to_consume_resource(
							type,
							consumption[Buildings.ComsumptionDatas.ResourceAmount]
						)
						remaining = result[0]
						money += result[1]
					else:
						var result = the_storage.try_to_consume_most_available_food(
							consumption[Buildings.ComsumptionDatas.ResourceAmount]
						)
						remaining = result[0]
						money += result[1]
						if remaining > 0:
							one_building_has_no_food = true
							
					if remaining > 0:
						had_enough_food = false
						
				_handle_building_and_food_result(
					building,
					had_enough_food
				)
		else:
			push_warning('building is not Building2D')
			continue
	
	the_bank.give_taxes(money)
	the_bank.apply_maintenance_cost(maintenance_cost)

func _handle_building_and_food_result(building: Building2D, had_enough_food: bool):
	if had_enough_food:
		if building.is_starving:
			building.hide_starving_indicator()
			the_population.population_increase(
				Buildings.get_population_type(
					building.building_id
				),
				Buildings.get_max_workers(
					building.building_id
				)
			)
	else:
		if !building.is_starving:
			building.show_starving_indicator()
			the_population.population_decrease(
				Buildings.get_population_type(
					building.building_id
				),
				Buildings.get_max_workers(
					building.building_id
				)
			)

func get_buildings_save() -> Dictionary:
	var datas:Array
	
	for child:Building2D in node_buildings.get_children():
		datas.append([
			child.building_id,
			child.position.x,
			child.position.y,
			child.is_starving,
		])
	
	return {"Buildings":datas}
	
func load_buildings_save() -> Error:
	if SaveHelper.last_loaded_data.is_empty():
		return FAILED
		
	var buildings_data:Array = SaveHelper.last_loaded_data.get("Buildings", [])
	
	if buildings_data.is_empty():
		return FAILED
	
	for building_data in SaveHelper.last_loaded_data["Buildings"]:
		var building = build(building_data[0],
				Vector2(building_data[1], building_data[2]))
				
		building.is_starving = building_data[3]
		if building.is_starving:
			building.show_starving_indicator()
		
		# FIXME : this seem wrong
		if build(building_data[0],
			Vector2(building_data[1], building_data[2])) == null:
			# TODO handle error with a popup and return to MainMenu
			
			pass
		
		if building_data[0] == 0:
			warehouse = building
	
	return OK
