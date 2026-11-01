extends Resource
class_name BuildingDefinition

@export
var scene: PackedScene

# FIXME?
# This allows us to define only one resource
# And to share the costs
# Maybe it could be used to transfer games
# Maybe it should be scenes in one place
# costs in one place
@export
var scene_2d: PackedScene

@export
var costs: Array[CostDefinition] = []
