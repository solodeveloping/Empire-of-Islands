extends Node
class_name TheBuildingsCost

# Info: we are doing array of ints for now
var costs: Dictionary[int, Array] = {}

func get_building_costs(building_id: int) -> Array:
	if costs.has(building_id):
		var cost: Array = costs.get(building_id)
		return cost.duplicate(true)
	return []

func set_costs(building_list: BuildingListDefinition):
	costs = {}
	for building_key in building_list.builtin_buildings.keys():
		var building: BuildingDefinition = building_list.builtin_buildings.get(building_key)
		var building_costs: Array = []
		for cost in building.costs:
			building_costs.push_back([
				cost.resource,
				cost.cost,
			])
		costs.set(building_key, building_costs)
	for building_key in building_list.extra_buildings.keys():
		var building: BuildingDefinition = building_list.builtin_buildings.get(building_key)
		var building_costs: Array = []
		for cost in building.costs:
			building_costs.push_back([
				cost.resource,
				cost.cost,
			])
		costs.set(building_key, building_costs)

	if costs.is_empty():
		push_error("no costs were set")
