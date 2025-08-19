extends Object
class_name Buildings

enum Types { Placeholder, Warehouse, Residential, Producing }

enum Ids { 
	Warehouse,
	# Level 1
	Tent,
	Lumberjack,
	# Level 2
	Hut,
	Sawmill,
	Farm,
	PotatoField,
	Pigsty,
	Butchery,
}

# FIXME : PopulationType is duplicated with the Recipes
# If Recipes is missing, it increase PopulationType 0 on the UI

enum Datas { Name, Type, Cost, Produce, Max_Workers, Level, PopulationType, Max_Count }

const datas = {
	Ids.Warehouse: {Datas.Name: &"Warehouse", Datas.Type: Types.Warehouse},
	# Level 1
	Ids.Tent:
	{
		Datas.Name: &"Tent",
		Datas.Type: Types.Residential,
		Datas.Cost: [[Resources.Types.Wood, 1], [Resources.Types.Textile, 1]],
		Datas.Max_Workers: 4,
		Datas.Level: 1,
		Datas.PopulationType: Populations.Types.Sailor,
	},
	Ids.Lumberjack:
	{
		Datas.Name: &"Lumberjack",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Wood, 1], [Resources.Types.Textile, 1]],
		Datas.Produce: Resources.Types.Wood,
		Datas.Max_Workers: 4,
		Datas.Max_Count: 3,
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
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Produce: Resources.Types.Plank,
		Datas.Max_Workers: 4
	},
	Ids.Farm:
	{
		Datas.Name: &"Farm",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Max_Workers: 2,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Ids.PotatoField:
	{
		Datas.Name: &"Potato field",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Produce: Resources.Types.Potato,
		Datas.Max_Workers: 2,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Ids.Pigsty:
	{
		Datas.Name: &"Pigsty",
		Datas.Type: Types.Producing,
		Datas.Cost: [[Resources.Types.Plank, 1],],
		Datas.Produce: Resources.Types.Pig,
		Datas.Max_Workers: 2,
		Datas.Level: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
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
	},
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
