@tool
extends Entity
class_name SquareExtension_1

@onready var sprite_indicator: Sprite3D = $Marker3D/SpriteIndicator

@onready var ground_sensor_editable_1: GroundSensorEditable1 = $GroundSensorEditable1
@onready var building_editable_children_area: BuildingEditableChildrenArea = $BuildingEditableChildrenArea

var is_constructible: bool:
	get:
		return building_editable_children_area.is_empty \
			and ground_sensor_editable_1.is_valid

func _on_state_changed():
	if is_constructible:
		sprite_indicator.modulate = Color.GREEN
	else:
		sprite_indicator.modulate = Color.RED

func _on_GroundSensorEditable1_state_changed() -> void:
	_on_state_changed()

func _on_BuildingEditableChildrenArea_state_changed() -> void:
	_on_state_changed()
