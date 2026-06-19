extends Object
class_name Buildings

enum Types { Placeholder, Warehouse, MainSquare, Residential, Producing }

# WARN : if you change this order, you will have to modify the BuildingGridContainer
# In the GUI because of the serialized ids
enum Ids { 
	Warehouse,
	Tent,
	Lumberjack,
	HunterTent,
	Hut,
	Sawmill,
	Farm,
	PotatoField,
	Pigsty,
	Butchery,
	StonePit,
	Stonemason,
	Pasture,
	Weaver,
	House,
	WheatField,
	Windmill,
	Bakery,
	Fishery,
	ClayPit,
	Brickyard,
	StoneHouse,
	MainSquare,
}

# FIXME : PopulationType is duplicated with the Recipes
# If Recipes is missing, it increase PopulationType 0 on the UI

enum Datas {
	Name,
	Type,
	Cost,
	Produce,
	Max_Workers,
	Level,
	PopulationType,
	Max_Count,
	Maintenance_Cost,
	Dependency_Max_Range,
	Require_Building,
	Require_MapCellType,
	Require_NaturalResource,
	Is_Coastal,
}

const datas = {
	Ids.Warehouse: {
		Datas.Name: &"Warehouse",
		Datas.Type: Types.Warehouse,
		Datas.Max_Count: 1,
		Datas.Is_Coastal: true,
	},
	Ids.MainSquare: {
		Datas.Name: &"Main Square",
		Datas.Type: Types.MainSquare,
		Datas.Max_Count: 1,
		Datas.Is_Coastal: false,
	},
	# Level 1
	Ids.Tent:
	{
		Datas.Name: &"Tent",
		Datas.Type: Types.Residential,
		Datas.Cost: [[Resources.Types.Plank, 1], [Resources.Types.Textile, 1]],
		Datas.Max_Workers: 4,
		Datas.Level: 1,
		Datas.PopulationType: Populations.Types.Sailor,
	},
	Ids.Lumberjack:
	{
		Datas.Name: &"Lumberjack",
		Datas.Type: Types.Producing,
		Datas.Cost: [
			[Resources.Types.Plank, 1],
			[Resources.Types.Textile, 1]
		],
		# FIXME: change it back to wood once there is an actual sawmill
		Datas.Produce: Resources.Types.Plank,
		Datas.Max_Workers: 4,
		Datas.Max_Count: 3,
		Datas.Maintenance_Cost: 1,
	},
	Ids.HunterTent:
	{
		Datas.Name: &"Hunter's tent",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1], [Resources.Types.Textile, 1]],
		Datas.Produce: Resources.Types.GameMeat,
		Datas.Max_Workers: 1,
		Datas.Max_Count: 3,
		Datas.Maintenance_Cost: 1,
	},
	Ids.Fishery:
	{
		Datas.Name: &"Fishery",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1], [Resources.Types.Textile, 1]],
		Datas.Produce: Resources.Types.Fish,
		Datas.Max_Count: 3,
		Datas.Max_Workers: 2,
		Datas.Maintenance_Cost: 1,
		Datas.Is_Coastal: true,
	},
	# Level 2
	Ids.Hut:
	{
		Datas.Name: &"Hut",
		Datas.Type: Types.Residential,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Max_Workers: 4,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Ids.Sawmill:
	{
		Datas.Name: &"Sawmill",
		Datas.Type: Types.Producing,
		Datas.Cost: [
			[Resources.Types.Plank, 1],
		],
		Datas.Produce: Resources.Types.Plank,
		Datas.Max_Workers: 4,
		Datas.Maintenance_Cost: 2,
	},
	Ids.Farm:
	{
		Datas.Name: &"Farm",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Max_Workers: 2,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
		Datas.Maintenance_Cost: 2,
		Datas.Dependency_Max_Range: 6,
	},
	Ids.PotatoField:
	{
		Datas.Name: &"Potato field",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Produce: Resources.Types.Potato,
		Datas.Max_Workers: 1,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
		Datas.Require_Building: Ids.Farm,
	},
	Ids.Pigsty:
	{
		Datas.Name: &"Pigsty",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Produce: Resources.Types.Pig,
		Datas.Max_Workers: 1,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
		Datas.Require_Building: Ids.Farm,
	},
	Ids.Pasture:
	{
		Datas.Name: &"Pasture",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Produce: Resources.Types.Wool,
		Datas.Max_Workers: 1,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
		Datas.Require_Building: Ids.Farm,
	},
	Ids.WheatField:
	{
		Datas.Name: &"Wheat field",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Produce: Resources.Types.Wheat,
		Datas.Max_Workers: 1,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
		Datas.Require_Building: Ids.Farm,
	},
	Ids.Butchery:
	{
		Datas.Name: &"Butchery",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Produce: Resources.Types.Meat,
		Datas.Max_Workers: 4,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
		Datas.Maintenance_Cost: 2,
	},
	Ids.Windmill:
	{
		Datas.Name: &"Windmill",
		Datas.Type: Types.Producing,
		Datas.Cost: [[
			Resources.Types.Plank, 1],
			[Resources.Types.StoneBrick, 1],
			[Resources.Types.Textile, 1],
		],
		Datas.Produce: Resources.Types.Flour,
		Datas.Max_Workers: 2,
		Datas.Level: 2,
		Datas.Maintenance_Cost: 1,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Ids.ClayPit:
	{
		Datas.Name: &"Clay pit",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Wood, 1], [Resources.Types.Textile, 1]],
		Datas.Produce: Resources.Types.Clay,
		Datas.Max_Workers: 2,
		Datas.Maintenance_Cost: 1,
		Datas.Require_MapCellType: MyMap.Minimap_Cell_Type.ClayDeposit,
		Datas.Require_NaturalResource: NaturalResources.Ids.ClayDeposit,
	},
	Ids.Brickyard:
	{
		Datas.Name: &"Brickyard",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Wood, 1], [Resources.Types.Textile, 1]],
		Datas.Produce: Resources.Types.ClayBrick,
		Datas.Max_Workers: 2,
		Datas.Maintenance_Cost: 1,
	},
	# Level 3
	Ids.House:
	{
		Datas.Name: &"House",
		Datas.Type: Types.Residential,
		Datas.Cost: [
			[Resources.Types.Plank, 1],
			[Resources.Types.Textile, 1],
			[Resources.Types.ClayBrick, 1],
		],
		Datas.Max_Workers: 4,
		Datas.Level: 3,
		Datas.PopulationType: Populations.Types.Settler,
	},
	Ids.Bakery:
	{
		Datas.Name: &"Bakery",
		Datas.Type: Types.Producing,
		Datas.Cost: [
			[Resources.Types.Plank, 1],
			[Resources.Types.ClayBrick, 1],
		],
		Datas.Produce: Resources.Types.Bread,
		Datas.Max_Workers: 2,
		Datas.Level: 3,
		Datas.Maintenance_Cost: 1,
		Datas.PopulationType: Populations.Types.Settler,
	},
	Ids.Weaver:
	{
		Datas.Name: &"Weaver",
		Datas.Type: Types.Producing,
		Datas.Cost: [
			[Resources.Types.Plank, 1],
			[Resources.Types.ClayBrick, 1],
		],
		Datas.Produce: Resources.Types.Textile,
		Datas.Max_Workers: 2,
		Datas.Level: 3,
		Datas.Maintenance_Cost: 1,
		Datas.PopulationType: Populations.Types.Settler,
	},
	Ids.StonePit:
	{
		Datas.Name: &"Stone pit",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Wood, 1], [Resources.Types.Textile, 1]],
		Datas.Produce: Resources.Types.Stone,
		Datas.Max_Workers: 2,
		Datas.Maintenance_Cost: 1,
		Datas.Require_MapCellType: MyMap.Minimap_Cell_Type.StoneDeposit,
		Datas.Require_NaturalResource: NaturalResources.Ids.StoneDeposit,
	},
	Ids.Stonemason:
	{
		Datas.Name: &"Stonemason",
		Datas.Type: Types.Producing,
		Datas.Cost: [
			[Resources.Types.Plank, 1],
			[Resources.Types.Textile, 1]
		],
		Datas.Produce: Resources.Types.StoneBrick,
		Datas.Max_Workers: 2,
		Datas.Maintenance_Cost: 1,
	},
	# Level 4
	Ids.StoneHouse:
	{
		Datas.Name: &"Stone house",
		Datas.Type: Types.Residential,
		Datas.Cost: [
			[Resources.Types.Plank, 1],
			[Resources.Types.Textile, 1],
			[Resources.Types.StoneBrick, 1],
		],
		Datas.Max_Workers: 4,
		Datas.Level: 3,
		Datas.PopulationType: Populations.Types.Citizen,
	},
}

enum ComsumptionDatas { ResourceType, ResourceAmount }

# FIXME : this could be per pop type instead
const Comsumptions = {
	Buildings.Ids.Tent: [
		{
			ComsumptionDatas.ResourceType: -1,
			ComsumptionDatas.ResourceAmount: 4,
		}
	],
	Buildings.Ids.Hut: [
		{
			ComsumptionDatas.ResourceType: -1,
			ComsumptionDatas.ResourceAmount: 2,
		},
		{
			ComsumptionDatas.ResourceType: Resources.Types.Potato,
			ComsumptionDatas.ResourceAmount: 1,
		},
		{
			ComsumptionDatas.ResourceType: Resources.Types.Meat,
			ComsumptionDatas.ResourceAmount: 1,
		},
	],
	Buildings.Ids.House: [
		{
			ComsumptionDatas.ResourceType: -1,
			ComsumptionDatas.ResourceAmount: 1,
		},
		{
			ComsumptionDatas.ResourceType: Resources.Types.Potato,
			ComsumptionDatas.ResourceAmount: 1,
		},
		{
			ComsumptionDatas.ResourceType: Resources.Types.Meat,
			ComsumptionDatas.ResourceAmount: 1,
		},
		{
			ComsumptionDatas.ResourceType: Resources.Types.Bread,
			ComsumptionDatas.ResourceAmount: 1,
		},
	],
	Buildings.Ids.StoneHouse: [
		{
			ComsumptionDatas.ResourceType: -1,
			ComsumptionDatas.ResourceAmount: 1,
		},
		{
			ComsumptionDatas.ResourceType: Resources.Types.Potato,
			ComsumptionDatas.ResourceAmount: 1,
		},
		{
			ComsumptionDatas.ResourceType: Resources.Types.Meat,
			ComsumptionDatas.ResourceAmount: 1,
		},
		{
			ComsumptionDatas.ResourceType: Resources.Types.Bread,
			ComsumptionDatas.ResourceAmount: 1,
		},
	],
}

# warning: conflict with get_name
static func get_building_name(building_id: Buildings.Ids) -> StringName:
	if not datas.has(building_id):
		push_warning('building of id "%d" was not found ' % building_id)
		return StringName()
	return datas[building_id][Datas.Name]


static func get_building_type(building_id: Buildings.Ids) -> Types:
	if not datas.has(building_id):
		return Types.Placeholder
	return datas[building_id].get(Datas.Type, Types.Placeholder)


static func get_building_cost(building_id: Buildings.Ids) -> Array:
	if not datas.has(building_id):
		return []
	var building_datas = datas[building_id]
	if not building_datas.has(Datas.Cost):
		return []
	return building_datas[Datas.Cost]


static func get_produce_resource(building_id: Buildings.Ids) -> Resources.Types:
	if not datas.has(building_id):
		return -1
	return datas[building_id].get(Datas.Produce, -1)


static func get_max_workers(building_id: Buildings.Ids) -> int:
	if not datas.has(building_id):
		return -1
	return datas[building_id].get(Datas.Max_Workers, -1)
	
static func get_population_type(building_id: Buildings.Ids) -> Populations.Types:
	if not datas.has(building_id):
		return -1
	return datas[building_id].get(Datas.PopulationType, -1)
	
static func get_max_count(building_id: Buildings.Ids) -> int:
	if not datas.has(building_id):
		return -1
	return datas[building_id].get(Datas.Max_Count, -1)

static func get_food_consumption(building_id: Buildings.Ids) -> Array:
	if not Comsumptions.has(building_id):
		push_error("building_id " + str(building_id) + " not found")
		return []

	return Comsumptions.get(building_id)

static func get_maintenance_cost(building_id: Buildings.Ids) -> int:
	if not datas.has(building_id):
		push_error("building_id " + str(building_id) + " not found")
		return 0

	return datas[building_id].get(Datas.Maintenance_Cost, 0)
	
static func get_require_building(building_id: Buildings.Ids) -> Buildings.Ids:
	if not datas.has(building_id):
		push_error("building_id " + str(building_id) + " not found")
		return -1

	return datas[building_id].get(Datas.Require_Building, -1)

static func get_require_map_cell_type(building_id: Buildings.Ids) -> MyMap.Minimap_Cell_Type:
	if not datas.has(building_id):
		push_error("building_id " + str(building_id) + " not found")
		return -1

	return datas[building_id].get(Datas.Require_MapCellType, -1)

static func get_require_natural_resource(building_id: Buildings.Ids) -> NaturalResources.Ids:
	if not datas.has(building_id):
		push_error("building_id " + str(building_id) + " not found")
		return -1

	return datas[building_id].get(Datas.Require_NaturalResource, -1)

static func get_dependency_max_range(building_id: Buildings.Ids) -> Buildings.Ids:
	if not datas.has(building_id):
		push_error("building_id " + str(building_id) + " not found")
		return -1

	return datas[building_id].get(Datas.Dependency_Max_Range, -1)
	
static func get_building_dependencies(building_id: Buildings.Ids) -> Array[Buildings.Ids]:
	if not datas.has(building_id):
		push_error("building_id " + str(building_id) + " not found")
		return []
	var result: Array[Buildings.Ids] = []
	for key in datas.keys():
		var val = datas[key]
		if val.get(Datas.Require_Building, -1) == building_id:
			result.push_back(key)
	return result
	
static func get_is_coastal(building_id: Buildings.Ids) -> bool:
	if not datas.has(building_id):
		push_error("building_id " + str(building_id) + " not found")
		return false

	return datas[building_id].get(Datas.Is_Coastal, false)
