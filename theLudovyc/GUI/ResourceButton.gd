extends TextureButton

@export var _type: Resources.Types


func set_resource_icon(type: Resources.Types):
	if Resources.Icons.has(type):
		$TextureRect.texture = Resources.Icons[type]


# Called when the node enters the scene tree for the first time.
func _ready():
	set_resource_icon(_type)
	pass  # Replace with function body.
