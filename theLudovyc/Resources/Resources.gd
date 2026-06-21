extends Object
class_name Resources

# WARN : if you change the order or insert something
# You will have to modify the resources indicators in the GUI as of now
enum Types {
	# WARN: do not use Wood for now, use Plank instead
	Wood,
	Textile,
	GameMeat,
	Plank,
	Potato,
	Pig,
	Meat,
	Stone,
	StoneBrick,
	Wool,
	Wheat,
	Flour,
	Bread,
	Fish,
	Clay,
	ClayBrick,
	Gold,
}

const Icons = {
	# Level 1
	Types.Wood: preload("res://Art/Image/Gui/Icons/Resources/32/008.png"),
	Types.GameMeat: preload("res://Art/Image/Gui/Icons/Resources/32/013.png"),
	Types.Fish: preload("res://Art/Temp/cc0-food-icons/fish_tail.png"),
	# Level 2
	Types.Plank: preload("res://Art/Image/Gui/Icons/Resources/32/004.png"),
	Types.Potato: preload("res://Art/Image/Gui/Icons/Resources/32/015.png"),
	Types.Pig: preload("res://Art/Image/Gui/Icons/Resources/32/036.png"),
	Types.Meat: preload("res://Art/Image/Gui/Icons/Resources/32/005.png"),
	Types.Wool: preload("res://Art/Image/Gui/Icons/Resources/32/010.png"),
	Types.Wheat: preload("res://Art/Image/Gui/Icons/Resources/32/042.png"),
	Types.Flour: preload("res://Art/Image/Gui/Icons/Resources/32/044.png"),
	Types.Clay: preload("res://Art/Image/Gui/Icons/Resources/32/021.png"),
	Types.ClayBrick: preload("res://Art/Image/Gui/Icons/Resources/32/007.png"),
	# Level 3
	Types.Bread: preload("res://Art/Temp/cc0-food-icons/bread.png"),
	Types.Textile: preload("res://Art/Image/Gui/Icons/Resources/32/003.png"),
	Types.Stone: preload("res://Art/Image/Gui/Icons/Resources/32/051.png"),
	Types.StoneBrick: preload("res://Art/Image/Gui/Icons/Resources/32/052.png"),
	# Level 4
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
	Types.Fish:
	{
		Datas.Name: &"Fish",
		Datas.Type: Types.Fish,
	},
	Types.Potato:
	{
		Datas.Name: &"Potato",
		Datas.Type: Types.Potato,
	},
	Types.Wool:
	{
		Datas.Name: &"Wool",
		Datas.Type: Types.Wool,
	},
	Types.Wheat:
	{
		Datas.Name: &"Wheat",
		Datas.Type: Types.Wheat,
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
	Types.Flour:
	{
		Datas.Name: &"Flour",
		Datas.Type: Types.Flour,
	},
	Types.Clay:
	{
		Datas.Name: &"Clay",
		Datas.Type: Types.Clay,
	},
	Types.ClayBrick:
	{
		Datas.Name: &"Clay brick",
		Datas.Type: Types.ClayBrick,
	},
	# Level 3
	Types.Meat:
	{
		Datas.Name: &"Meat",
		Datas.Type: Types.Meat,
	},
	Types.Bread:
	{
		Datas.Name: &"Bread",
		Datas.Type: Types.Bread,
	},
	Types.Stone:
	{
		Datas.Name: &"Stone",
		Datas.Type: Types.Stone,
	},
	Types.StoneBrick:
	{
		Datas.Name: &"Stone brick",
		Datas.Type: Types.StoneBrick,
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
	# Gathered
	Types.Wood: LevelTypes.Gathered,
	Types.GameMeat: LevelTypes.Gathered,
	Types.Fish: LevelTypes.Gathered,
	Types.Stone: LevelTypes.Gathered,
	Types.Clay: LevelTypes.Gathered,
	Types.Potato: LevelTypes.Gathered,
	Types.Wool: LevelTypes.Gathered,
	Types.Wheat: LevelTypes.Gathered,
	# Transformed once
	Types.Pig: LevelTypes.TransformedOnce,
	Types.Plank: LevelTypes.TransformedOnce,
	Types.StoneBrick: LevelTypes.TransformedOnce,
	Types.ClayBrick: LevelTypes.TransformedOnce,
	Types.Flour: LevelTypes.TransformedOnce,
	# Transformed twice
	Types.Textile: LevelTypes.TransformedTwice,
	Types.Meat: LevelTypes.TransformedTwice,
	Types.Bread: LevelTypes.TransformedTwice,
}

static func get_resource_level(resource_type: Types) -> LevelTypes:
	if not datas.has(resource_type):
		push_error('resource of id "%d" was not found ' % resource_type)
		return LevelTypes.Gathered
	return Levels[resource_type]
	
const Foods = [
	Types.GameMeat,
	Types.Fish,
	Types.Potato,
	Types.Meat,
	Types.Bread,
]

static func is_food(resource_type: Types) -> bool:
	return Foods.has(resource_type)
