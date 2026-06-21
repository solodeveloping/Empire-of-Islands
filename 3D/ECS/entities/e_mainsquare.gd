@tool
class_name MainSquare_ECS
extends Entity

signal multimesh_instance_area_entered_main_area(area: MultiMeshInstanceArea)
signal multimesh_instance_area_exited_main_area(area: MultiMeshInstanceArea)

@export_flags_3d_physics
var ray_ground_layers: int = 0

@onready var building_box_sensor: BuildingRiverWaterSensor1 = $BuildingBoxSensor
@onready var ground_sensor_editable_1: GroundSensorEditable1 = $GroundSensorEditable1

@onready var sprite_indicator: Sprite3D = $SpriteIndicators/SpriteIndicator

@onready var multi_mesh_instances_remover: MultiMeshInstancesRemover = $MultiMeshInstancesRemover

var is_constructible: bool:
	get:
		return building_box_sensor.is_empty \
			and ground_sensor_editable_1.is_valid

var is_constructed: bool = false

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.MainSquare),
		C_MainSquare.new(),
		C_Health.new(100),
		C_Range.new(25.0),
		C_Transform.new(),
		C_Name.new("Main square"),
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform

func _ready() -> void:
	_on_state_changed()
	
	ground_sensor_editable_1.ray_ground_layers = ray_ground_layers

func _on_state_changed():
	if is_constructible:
		sprite_indicator.modulate = Color.GREEN
	else:
		sprite_indicator.modulate = Color.RED

func _on_BuildingBoxSensor_state_changed() -> void:
	_on_state_changed()

func _on_GroundSensorEditable1_state_changed() -> void:
	_on_state_changed()

func finalize_construction():
	print("CityCenter:finalize_construction %s" % [
		self.name
	])
	is_constructed = true
	multi_mesh_instances_remover.disable_instance_areas()

# WARN: this could interact right back with the building's area
func show_all_tree_hidden():
	multi_mesh_instances_remover.show_all_instances()

func get_hidden_trees() -> Array[MultiMeshInstanceArea]:
	return multi_mesh_instances_remover.get_instances()

func _on_BuildingBoxSensor_multimesh_instance_area_entered(area: MultiMeshInstanceArea) -> void:
	#print("CityCenter:_on_BuildingBoxSensor_multimesh_instance_area_entered %s" % [
		#area.name,
	#])
	multimesh_instance_area_entered_main_area.emit(area)
	if !is_constructed:
		multi_mesh_instances_remover._on_multimesh_instance_area_entered_main_area(area)

func _on_BuildingBoxSensor_multimesh_instance_area_exited(area: MultiMeshInstanceArea) -> void:
	#print("CityCenter:_on_BuildingBoxSensor_multimesh_instance_area_entered %s" % [
		#area.name,
	#])
	multimesh_instance_area_exited_main_area.emit(area)
	if !is_constructed:
		multi_mesh_instances_remover._on_multimesh_instance_area_exited_main_area(area)
