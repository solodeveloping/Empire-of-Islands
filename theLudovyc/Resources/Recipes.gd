extends Object
class_name Recipes

# Needed 1 resource input, tick(s) and Worker(s) to produce 1 resource output
enum Datas { InputType, InputAmount, Ticks, Workers, PopulationType }

const datas = {
	Resources.Types.Wood: {
		Datas.InputType: -1,
		Datas.Ticks: 1,
		Datas.Workers: 4,
		Datas.PopulationType: Populations.Types.Sailor,
	},
	Resources.Types.Plank: {
		Datas.InputType: Resources.Types.Wood,
		Datas.InputAmount: 2,
		Datas.Ticks: 1,
		Datas.Workers: 4,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.Potato: {
		Datas.InputType: -1,
		Datas.Ticks: 1,
		Datas.Workers: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.Pig: {
		Datas.InputType: Resources.Types.Potato,
		Datas.InputAmount: 1,
		Datas.Ticks: 1,
		Datas.Workers: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.Meat: {
		Datas.InputType: Resources.Types.Pig,
		Datas.InputAmount: 2,
		Datas.Ticks: 1,
		Datas.Workers: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
}


static func get_recipe_input_type(resource_type: Resources.Types) -> int:
	if not datas.has(resource_type):
		return 0

	return datas[resource_type].get(Datas.InputType)

static func get_recipe_input_amount(resource_type: Resources.Types) -> int:
	if not datas.has(resource_type):
		return 0

	return datas[resource_type].get(Datas.InputAmount, 0)

static func get_recipe_needed_ticks(resource_type: Resources.Types) -> int:
	if not datas.has(resource_type):
		return 0

	return datas[resource_type].get(Datas.Ticks, 0)


static func get_recipe_needed_workers(resource_type: Resources.Types) -> int:
	if not datas.has(resource_type):
		return 0

	return datas[resource_type].get(Datas.Workers, 0)
	
static func get_recipe_population_type(resource_type: Resources.Types) -> int:
	if not datas.has(resource_type):
		return 0

	return datas[resource_type].get(Datas.PopulationType)
