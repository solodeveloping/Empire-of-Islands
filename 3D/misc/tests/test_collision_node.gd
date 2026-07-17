extends MeshInstance3D

@onready var static_body_3d: StaticBody3D = $StaticBody3D

func _ready() -> void:
	# Info: this does nothing
	#set_deferred("disabled", true)
	# Info: this does nothing
	#static_body_3d.set_deferred("disabled", true)
	# Info: this actually works
	#static_body_3d.process_mode = Node.PROCESS_MODE_DISABLED
	# Info: this actually works
	self.process_mode =Node.PROCESS_MODE_DISABLED
