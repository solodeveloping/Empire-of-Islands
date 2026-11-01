extends Node3D
class_name HealthProgressBar1

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

## progress should be between 0 and 1
func set_progress(progress: float):
	mesh_instance_3d.set_instance_shader_parameter(
		"health",
		progress
	)
