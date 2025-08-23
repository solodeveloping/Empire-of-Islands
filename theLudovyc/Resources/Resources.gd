extends Object
class_name Resources

# WARN : if you change the order or insert something
# You will have to modify the resources indicators in the GUI as of now
enum Types {
	# Level 1
	Wood,
	Textile,
	GameMeat,
	# Level 2
	Plank,
	Potato,
	Pig,
	Meat,
}

const Icons = {
	# Level 1
	Types.Wood: preload("res://Art/Image/Gui/Icons/Resources/32/008.png"),
	Types.Textile: preload("res://Art/Image/Gui/Icons/Resources/32/003.png"),
	Types.GameMeat: preload("res://Art/Image/Gui/Icons/Resources/32/013.png"),
	# Level 2
	Types.Plank: preload("res://Art/Image/Gui/Icons/Resources/32/004.png"),
	Types.Potato: preload("res://Art/Image/Gui/Icons/Resources/32/015.png"),
	Types.Pig: preload("res://Art/Image/Gui/Icons/Resources/32/036.png"),
	Types.Meat: preload("res://Art/Image/Gui/Icons/Resources/32/005.png"),
}

enum Datas { Name, Type, Level, }

const datas = {
	# Level 1
	Types.Wood: {
		Datas.Name: &"Wood", 
		Datas.Type: Types.Wood,
	},
	Types.GameMeat:
	{
		Datas.Name: &"Game meat",
		Datas.Type: Types.GameMeat,
	},
	Types.Potato:
	{
		Datas.Name: &"Potato",
		Datas.Type: Types.Potato,
	},
	# Level 2
	Types.Textile:
	{
		Datas.Name: &"Textile",
		Datas.Type: Types.Textile,
	},
	Types.Plank:
	{
		Datas.Name: &"Plank",
		Datas.Type: Types.Plank,
	},
	Types.Pig:
	{
		Datas.Name: &"Pig",
		Datas.Type: Types.Pig,
	},
	# Level 3
	Types.Meat:
	{
		Datas.Name: &"Meat",
		Datas.Type: Types.Meat,
	},
}

static func get_resource_icon(resource_type: Types) -> Texture2D:
	return Icons.get(resource_type)

# warning: conflict with get_name
static func get_resource_name(resource_type: Types) -> StringName:
	if not datas.has(resource_type):
		push_warning('resource of id "%d" was not found ' % resource_type)
		return StringName()
	return datas[resource_type][Datas.Name]

enum LevelTypes { Gathered, TransformedOnce, TransformedTwice }

const Levels = {
	Types.Wood: LevelTypes.Gathered,
	Types.GameMeat: LevelTypes.Gathered,
	Types.Textile: LevelTypes.TransformedTwice,
	Types.Plank: LevelTypes.TransformedOnce,
	Types.Potato: LevelTypes.Gathered,
	Types.Pig: LevelTypes.TransformedOnce,
	Types.Meat: LevelTypes.TransformedTwice,
}

static func get_resource_level(resource_type: Types) -> LevelTypes:
	if not datas.has(resource_type):
		push_error('resource of id "%d" was not found ' % resource_type)
		return LevelTypes.Gathered
	return Levels[resource_type]
	
const Foods = [
	Types.GameMeat,
	Types.Potato,
	Types.Meat
]

static func is_food(resource_type: Types) -> bool:
	return Foods.has(resource_type)
