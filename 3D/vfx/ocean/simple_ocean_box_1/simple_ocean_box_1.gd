@tool
extends Node3D

@export
var color: Color = Color("00a0e683"):
	set(value):
		color = value
		
		if mesh_instance_3d:
			mesh_instance_3d.set_instance_shader_parameter("albedo", color)
		
@export
var metallic: float = 0:
	set(value):
		metallic = value
		
		if mesh_instance_3d:
			mesh_instance_3d.set_instance_shader_parameter("metallic", metallic)
		
@export
var roughness: float = 0:
	set(value):
		roughness = value
		
		if mesh_instance_3d:
			mesh_instance_3d.set_instance_shader_parameter("roughness", roughness)

@export
var specular: float = 0:
	set(value):
		specular = value
		
		if mesh_instance_3d:
			mesh_instance_3d.set_instance_shader_parameter("specular", specular)

@export
var refraction: float = 0:
	set(value):
		refraction = value
		
		if mesh_instance_3d:
			mesh_instance_3d.set_instance_shader_parameter("refraction", refraction)

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
