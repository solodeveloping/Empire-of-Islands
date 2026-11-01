extends Node
class_name TheBuildingsCost

# Info: we are doing array of ints for now
var costs: Dictionary[int, Array] = {}

func get_building_costs(building_id: int) -> Array:
	if costs.has(building_id):
		var cost: Array = costs.get(building_id)
		return cost.duplicate(true)
	return []

func set_costs(
	building_list: BuildingListDefinition,
):
	costs = {}
	for building_key in building_list.builtin_buildings.keys():
		var building: BuildingDefinition = building_list.builtin_buildings.get(
			building_key
		)
		var building_costs: Array = []
		for cost in building.costs:
			building_costs.push_back([
				cost.resource,
				cost.cost,
			])
		costs.set(building_key, building_costs)
	for building_key in building_list.extra_buildings.keys():
		var building: BuildingDefinition = building_list.builtin_buildings.get(
			building_key
		)
		var building_costs: Array = []
		for cost in building.costs:
			building_costs.push_back([
				cost.resource,
				cost.cost,
			])
		costs.set(building_key, building_costs)

	if costs.is_empty():
		push_error("no costs were set")
	
	_verify_buildings_settings(building_list)
	

func _verify_buildings_settings(
	building_list: BuildingListDefinition,
):
	for building_key in building_list.builtin_buildings.keys():
		var building: BuildingDefinition = building_list.builtin_buildings.get(
			building_key
		)
		var _name = Buildings.get_building_name(
			building_key
		)
		if building.scene == null:
			printerr("scene of building is null %s %s" % [
				building_key,
				_name,
			])
		if building.scene_2d == null:
			printerr("scene_2d of building is null %s %s" % [
				building_key,
				_name,
			])
		if building.costs == null or building.costs.is_empty():
			printerr("scene of building is null or empty %s %s" % [
				building_key,
				_name,
			])

	for building_key in building_list.extra_buildings.keys():
		var building: BuildingDefinition = building_list.extra_buildings.get(
			building_key
		)
		# TODO: name for extra buildings
		#var _name = Buildings.get_building_name(
			#building_key
		#)
		if building.scene == null:
			printerr("scene of building is null %s" % [
				building_key,
				#_name,
			])
		if building.scene_2d == null:
			printerr("scene_2d of building is null %s" % [
				building_key,
				#_name,
			])
		if building.costs == null or building.costs.is_empty():
			printerr("scene of building is null or empty %s" % [
				building_key,
				#_name,
			])
