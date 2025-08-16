extends Node

const Building_2D_Scene = preload("res://theLudovyc/Building/Building2D.tscn")

var warehouse: Building2D

@onready var node_buildings:Node = %Buildings

@onready var tilemap:TileMap = %TileMap

@onready var event_bus = $"../EventBus"

var buildings_count = {
	Buildings.Ids.Lumberjack: 0,
}

## Use this method to obtain an instance of the building
## It is used to get a floating building that follows the mouse pos for instance
func instantiate_building(building_id: Buildings.Ids) -> Building2D:
	var instance = Building_2D_Scene.instantiate() as Building2D
	
	instance.building_id = building_id

	node_buildings.add_child(instance)

	return instance
	
func build(building_id:Buildings.Ids, pos:Vector2) -> Building2D:
	var building = instantiate_building(building_id)
	
	if building == null:
		push_error("Cannot create a building from null instance")
		
		return null
	
	building.position = pos
	
	tilemap.conclude_building_construction(building)

	building.build()
	
	conclude_building_construction(building_id)
	
	return building
	
func build_warehouse(pos:Vector2):
	warehouse = build(Buildings.Ids.Warehouse, pos)

func conclude_building_construction(building_id:Buildings.Ids):
	if !buildings_count.has(building_id):
		buildings_count[building_id] = 1
	else:
		buildings_count[building_id] += 1
	
	var limit = Buildings.get_max_count(building_id)
	if limit != -1:
		if buildings_count[building_id] >= limit:
			event_bus.send_building_limit_updated.emit(building_id, true)

func conclude_building_destruction(building_id:Buildings.Ids):
	var previous_count = buildings_count[building_id]
	buildings_count[building_id] -= 1
	var limit = Buildings.get_max_count(building_id)
	if limit != -1:
		if previous_count == limit:
			event_bus.send_building_limit_updated.emit(building_id, false)

func get_buildings_save() -> Dictionary:
	var datas:Array
	
	for child:Building2D in node_buildings.get_children():
		datas.append([child.building_id, child.position.x, child.position.y])
	
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
		
		if build(building_data[0],
			Vector2(building_data[1], building_data[2])) == null:
			# TODO handle error with a popup and return to MainMenu
			
			pass
		
		if building_data[0] == 0:
			warehouse = building
	
	return OK
