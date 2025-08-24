extends Object
class_name Recipes

# Needed 1 resource input, tick(s) and Worker(s) to produce 1 resource output
enum Datas {
	InputType,
	InputAmount,
	Ticks,
	Workers,
	PopulationType,
	OutputAmount,
}

const datas = {
	Resources.Types.Wood: {
		Datas.InputType: -1,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Sailor,
	},
	Resources.Types.GameMeat: {
		Datas.InputType: -1,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Sailor,
	},
	Resources.Types.Fish: {
		Datas.InputType: -1,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Sailor,
	},
	Resources.Types.Stone: {
		Datas.InputType: -1,
		Datas.Ticks: 1,
		Datas.Workers: 2,
		Datas.PopulationType: Populations.Types.Sailor,
	},
	Resources.Types.Plank: {
		Datas.InputType: Resources.Types.Wood,
		Datas.InputAmount: 1,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.Potato: {
		Datas.InputType: -1,
		Datas.OutputAmount: 2,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.Wool: {
		Datas.InputType: -1,
		Datas.OutputAmount: 2,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.Wheat: {
		Datas.InputType: -1,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.Pig: {
		Datas.InputType: Resources.Types.Potato,
		Datas.InputAmount: 1,
		Datas.OutputAmount: 2,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.Meat: {
		Datas.InputType: Resources.Types.Pig,
		Datas.InputAmount: 1,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.StoneBrick: {
		Datas.InputType: Resources.Types.Stone,
		Datas.InputAmount: 1,
		Datas.Ticks: 1,
		Datas.Workers: 2,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	Resources.Types.Flour: {
		Datas.InputType: Resources.Types.Wheat,
		Datas.InputAmount: 1,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Pioneer,
	},
	# Level 3
	Resources.Types.Textile: {
		Datas.InputType: Resources.Types.Wool,
		Datas.InputAmount: 1,
		Datas.Ticks: 1,
		Datas.Workers: 2,
		Datas.PopulationType: Populations.Types.Settler,
	},
	Resources.Types.Bread: {
		Datas.InputType: Resources.Types.Flour,
		Datas.InputAmount: 1,
		Datas.Ticks: 1,
		Datas.Workers: 1,
		Datas.PopulationType: Populations.Types.Settler,
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

static func get_recipe_output_amount(resource_type: Resources.Types) -> int:
	if not datas.has(resource_type):
		return 0

	return datas[resource_type].get(Datas.OutputAmount, 1)

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
