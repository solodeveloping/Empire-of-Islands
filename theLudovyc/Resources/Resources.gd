extends Object
class_name Resources

enum Types {
	# Level 1
	Wood,
	Textile,
	# Level 2
	Plank,
}

const Icons = {
	# Level 1
	Types.Wood: preload("res://Art/Image/Gui/Icons/Resources/32/008.png"),
	Types.Textile: preload("res://Art/Image/Gui/Icons/Resources/32/003.png"),
	# Level 2
	Types.Plank: preload("res://Art/Image/Gui/Icons/Resources/32/004.png"),
}

enum Datas { Name, Type, Level, }

const datas = {
	Types.Wood: {
		Datas.Name: &"Wood", 
		Datas.Type: Types.Wood,
	},
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
	Types.Textile: LevelTypes.TransformedTwice,
	Types.Plank: LevelTypes.TransformedOnce,
}

static func get_resource_level(resource_type: Types) -> LevelTypes:
	if not datas.has(resource_type):
		push_error('resource of id "%d" was not found ' % resource_type)
		return LevelTypes.Gathered
	return Levels[resource_type]
