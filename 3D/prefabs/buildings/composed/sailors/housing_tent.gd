#extends Node3D
@tool
extends Entity

# TODO : make sure we don't move a StaticBody3D

signal multimesh_instance_area_entered_main_area(area: MultiMeshInstanceArea)
signal multimesh_instance_area_exited_main_area(area: MultiMeshInstanceArea)

@export_flags_3d_physics
var ray_ground_layers: int = 0

@onready var sprite_indicator: Sprite3D = $Node3D/SpriteIndicator
@onready var decal_indicator: Decal = $DecalIndicator

@onready var building_main_area_1: BuildingMainArea1 = $BuildingMainArea1
@onready var ground_sensor_editable_1: GroundSensorEditable1 = $GroundSensorEditable1

@onready var multi_mesh_instances_remover: MultiMeshInstancesRemover = $MultiMeshInstancesRemover

#@onready
#var own_sensors: Array[Area3D] = [
	#sensor_ground_1,
	#sensor_ground_2,
	#sensor_ground_3,
	#sensor_ground_4,
#]

var is_constructible: bool:
	get:
		return building_main_area_1.is_empty and ground_sensor_editable_1.is_valid

var is_constructed: bool = false

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.Tent),
		C_Transform.new(),
		C_Health.new(100),
		C_HousingCapacity.new(4, 0),
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform

func _ready() -> void:
	sprite_indicator.modulate = Color.GREEN
	
	ground_sensor_editable_1.ray_ground_layers = ray_ground_layers

func _on_state_changed():
	#display_debug_sensors()
	if is_constructible:
		display_green()
	else:
		display_red()

func display_green():
	sprite_indicator.modulate = Color.GREEN
	decal_indicator.modulate = Color.WEB_GREEN

func display_red():
	sprite_indicator.modulate = Color.RED
	decal_indicator.modulate = Color.RED
	
func _on_BuildingMainArea1_state_changed() -> void:
	_on_state_changed()

func _on_GroundSensorEditable1_state_changed() -> void:
	_on_state_changed()

func get_main_area() -> Area3D:
	return building_main_area_1.main_area_3d

# TODO: add this
func disable_multimesh_instance_area_handling():
	pass
	
func finalize_construction():
	print("HousingTent:finalize_construction %s" % [
		self.name
	])
	is_constructed = true
	multi_mesh_instances_remover.disable_instance_areas()

func _on_BuildingMainArea1_multimesh_instance_area_entered(area: MultiMeshInstanceArea) -> void:
	#print("_on_BuildingMainArea1_multimesh_instance_area_entered")
	multimesh_instance_area_entered_main_area.emit(area)
	if !is_constructed:
		multi_mesh_instances_remover._on_multimesh_instance_area_entered_main_area(area)

func _on_BuildingMainArea1_multimesh_instance_area_exited(area: MultiMeshInstanceArea) -> void:
	multimesh_instance_area_exited_main_area.emit(area)
	if !is_constructed:
		multi_mesh_instances_remover._on_multimesh_instance_area_exited_main_area(area)

func _print_state():
	print("")
	print("state main_area %s ground %s" % [
		building_main_area_1.is_empty,
		ground_sensor_editable_1.is_valid,
	])
	print("objects inside bodies %s areas %s" % [
		building_main_area_1.overlapping_bodies.size(),
		building_main_area_1.overlapping_areas.size(),
	])
	for body in building_main_area_1.overlapping_bodies:
		print("body name %s %s %s" % [
			body.name,
			body.get_parent().name,
			body.get_parent().get_parent().name,
		])
		print("enabled ", body.process_mode)

# TODO : encapsulate this somewhere
func _on_CheckAreasTimer_timeout() -> void:
	pass
	#get_tree().physics_frame.connect(check_areas, Object.CONNECT_ONE_SHOT)

func check_areas():
	var overlappings: Array[Area3D] = building_main_area_1.main_area_3d.get_overlapping_areas()
	for area in overlappings:
		if area is MultiMeshInstanceArea:
			multi_mesh_instances_remover._hide_area(area)
