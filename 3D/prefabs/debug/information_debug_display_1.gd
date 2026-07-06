@tool
extends Entity
class_name InformationDebugDisplay1

@onready var label_3d: Label3D = $Label3D

func _ready() -> void:
	label_3d.modulate = Color.from_hsv(
		randf_range(0, 1),
		randf_range(0, 1),
		0.8,
	)

func set_text(text: String):
	label_3d.text = text
