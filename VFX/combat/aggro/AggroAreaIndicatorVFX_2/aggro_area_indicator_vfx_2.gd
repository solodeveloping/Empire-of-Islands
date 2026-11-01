extends Node3D
class_name AggroAreaIndicatorVFX_2

# FIXME: this is a lot of vertices

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func set_radius(radius: float):
	mesh_instance_3d.mesh.top_radius = radius
	mesh_instance_3d.mesh.bottom_radius = radius
