extends RefCounted
class_name BuildingWithRect

# FIXME: is this used?

# FIXME: don't remember why
# Info: can't use this for farms

var building: Entity
var rect: OrientedRect2

func _init(
	building_: Entity,
	rect_: OrientedRect2,
) -> void:
	building = building_
	rect = rect_
