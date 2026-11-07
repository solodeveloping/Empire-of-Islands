@tool
extends Entity
class_name Faction_ECS

# TODO: this is not good
# We need to figure out a proper way of implementing this

# Info: this is here because it's a node reference
# use [C_Faction] for other things
@export
var storage_node: Node
