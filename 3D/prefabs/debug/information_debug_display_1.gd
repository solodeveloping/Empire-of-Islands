@tool
extends Entity
class_name InformationDebugDisplay1

@onready var label_3d: Label3D = $Label3D

func set_text(text: String):
	label_3d.text = text
