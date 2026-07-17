extends Resource
class_name ResourceCollectionDefinition

@export
var builtin_resources: Dictionary[Resources.Types, BuiltinResourceQuantityDefinition] = {}

@export
var custom_resources: Dictionary[int, ResourceQuantityDefinition] = {}

@export
var gold_count: int = 0
