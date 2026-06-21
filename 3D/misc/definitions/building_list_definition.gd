extends Resource
class_name BuildingListDefinition

# Info: we are using Ids, this way we have autocompletion

@export
var builtin_buildings: Dictionary[Buildings.Ids, BuildingDefinition] = {}

@export
var extra_buildings: Dictionary[int, BuildingDefinition] = {}
