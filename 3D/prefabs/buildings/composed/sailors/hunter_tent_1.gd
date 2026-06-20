@tool
extends Entity

signal multimesh_instance_area_entered_main_area(area: MultiMeshInstanceArea)
signal multimesh_instance_area_exited_main_area(area: MultiMeshInstanceArea)

@export_flags_3d_physics
var ray_ground_layers: int = 0

@onready var building_main_area_1: BuildingMainArea1 = $BuildingMainArea1
@onready var ground_sensor_editable_1: GroundSensorEditable1 = $GroundSensorEditable1

@onready var sprite_indicator: Sprite3D = $SpriteIndicators/SpriteIndicator

@onready var multi_mesh_instances_remover: MultiMeshInstancesRemover = $MultiMeshInstancesRemover

var is_constructible: bool:
	get:
		return building_main_area_1.is_empty and ground_sensor_editable_1.is_valid

var is_constructed: bool = false

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.HunterTent),
		C_Name.new("Hunter tent"),
		C_Transform.new(),
		C_Health.new(100),
		C_Production.new(
			Resources.Types.GameMeat,
			1,
			3.0
		),
		C_CollectionBuilding.new(),
		C_WorkerRequirement.new(
			[
				Worker_Requirement.new(
					Populations.Types.Sailor,
					2,
					1
				)
			]
		),
		C_Workers.new({
			Populations.Types.Sailor: WorkerQuantity.new(Populations.Types.Sailor, 0)
		}),
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform

func _ready() -> void:
	ground_sensor_editable_1.ray_ground_layers = ray_ground_layers

func _on_BuildingMainArea1_state_changed() -> void:
	_on_state_changed()

func _on_BuildingWaterSensor1_state_changed() -> void:
	_on_state_changed()

func _on_GroundSensorEditable1_state_changed() -> void:
	_on_state_changed()

func _on_state_changed():
	if is_constructible:
		sprite_indicator.modulate = Color.GREEN
	else:
		sprite_indicator.modulate = Color.RED

func finalize_construction():
	print("HunterTent:finalize_construction %s" % [
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
