extends Camera3D
class_name CameraFollowTarget_XZ

@export
#var target: Camera3D
var target: Node3D

func _physics_process(_delta: float) -> void:
	if !target:
		return
	
	self.global_position.x = target.global_position.x
	self.global_position.z = target.global_position.z
