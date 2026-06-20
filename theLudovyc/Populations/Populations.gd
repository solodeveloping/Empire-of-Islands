extends Object
class_name Populations

enum Types {
	# Level 1
	Sailor,
	# Level 2
	Pioneer,
	# Level 3
	Settler,
	# Level 4
	Citizen,
}

enum Datas {
	Name,
	#Description,
}

const datas = {
	Types.Sailor:
	{
		Datas.Name: &"Sailor",
	},
	Types.Pioneer:
	{
		Datas.Name: &"Pioneer",
	},
	Types.Settler:
	{
		Datas.Name: &"Settler",
	},
	Types.Citizen:
	{
		Datas.Name: &"Citizen",
	},
}

static func get_population_name(pop_type: Populations.Types) -> StringName:
	if not datas.has(pop_type):
		push_warning('pop_type of id "%d" was not found ' % pop_type)
		return StringName()
	return datas[pop_type][Datas.Name]
