@tool
class_name Dock_ECS
extends Entity

# TODO: where should the scripts be?

signal multimesh_instance_area_entered_main_area(area: MultiMeshInstanceArea)
signal multimesh_instance_area_exited_main_area(area: MultiMeshInstanceArea)

@export_flags_3d_physics
var ray_ground_layers: int = 0

@onready var building_main_area_1: BuildingMainArea1 = $BuildingMainArea1
# TODO : useless?
@onready var building_water_sensor_1: BuildingRiverWaterSensor1 = $BuildingWaterSensor1
@onready var ground_sensor_editable_1: GroundSensorEditable1 = $GroundSensorEditable1

@onready var sprite_indicator: Sprite3D = $SpriteIndicators/SpriteIndicator
@onready var water_sensor_sprite_indicator: Sprite3D = $SpriteIndicators/WaterSensorSpriteIndicator
@onready var water_sensor_sprite_indicator_2: Sprite3D = $SpriteIndicators/WaterSensorSpriteIndicator2

@onready var water_ray_cast_3d: RayCast3D = $WaterRayCast3D
@onready var water_ray_cast_3d_2: RayCast3D = $WaterRayCast3D2

@onready var multi_mesh_instances_remover: MultiMeshInstancesRemover = $MultiMeshInstancesRemover

@onready var buoy: DockBuoy_ECS = $Buoy

@onready var spawn_point_container: Node3D = $SpawnPointContainer

var is_constructible: bool:
	get:
		return building_main_area_1.is_empty \
			and building_water_sensor_1.is_empty \
			and ground_sensor_editable_1.is_valid

var is_constructed: bool = false

func get_spawn_point() -> Node3D:
	var id_ = randi_range(
		0,
		spawn_point_container.get_child_count() - 1
	)
	return spawn_point_container.get_child(id_)

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.Warehouse),
		C_Name.new("Dock"),
		C_Health.new(100),
		C_Storage.new(),
		C_Range.new(100.0),
		C_Transform.new(),
		C_Dock.new(),
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

func _print_state():
	print("state main_area %s water %s ground %s" % [
		building_main_area_1.is_empty,
		building_water_sensor_1.is_empty,
		ground_sensor_editable_1.is_valid,
	])

func _on_state_changed():
	if is_constructible:
		sprite_indicator.modulate = Color.GREEN
	else:
		sprite_indicator.modulate = Color.RED
	
	if building_water_sensor_1.is_empty:
		water_sensor_sprite_indicator.modulate = Color.GREEN
	else:
		water_sensor_sprite_indicator.modulate = Color.RED

func _on_BuildingMainArea1_state_changed() -> void:
	_on_state_changed()

func _on_BuildingWaterSensor1_state_changed() -> void:
	_on_state_changed()

func _on_UpdateWaterSensorTimer_timeout() -> void:
	# FIXME: we have to do this because of some Area3D bug
	# They don't detect bodies entering
	# IDK why
	var collider = water_ray_cast_3d.get_collider()
	var collider2 = water_ray_cast_3d_2.get_collider()
	if !collider and !collider2:
		sprite_indicator.modulate = Color.GREEN
	else:
		sprite_indicator.modulate = Color.RED
	
	if collider:
		water_sensor_sprite_indicator.modulate = Color.RED
	else:
		water_sensor_sprite_indicator.modulate = Color.GREEN
		
	if collider2:
		water_sensor_sprite_indicator_2.modulate = Color.RED
	else:
		water_sensor_sprite_indicator_2.modulate = Color.GREEN

func _on_GroundSensorEditable1_state_changed() -> void:
	_on_state_changed()

func finalize_construction():
	print("Dock:finalize_construction %s" % [
		self.name
	])
	is_constructed = true
	multi_mesh_instances_remover.disable_instance_areas()

# WARN: this could interact right back with the building's area
func show_all_tree_hidden():
	multi_mesh_instances_remover.show_all_instances()

func get_hidden_trees() -> Array[MultiMeshInstanceArea]:
	return multi_mesh_instances_remover.get_instances()

func _on_BuildingMainArea1_multimesh_instance_area_entered(area: MultiMeshInstanceArea) -> void:
	#print("_on_BuildingMainArea1_multimesh_instance_area_entered")
	multimesh_instance_area_entered_main_area.emit(area)
	if !is_constructed:
		multi_mesh_instances_remover._on_multimesh_instance_area_entered_main_area(area)

func _on_BuildingMainArea1_multimesh_instance_area_exited(area: MultiMeshInstanceArea) -> void:
	multimesh_instance_area_exited_main_area.emit(area)
	if !is_constructed:
		multi_mesh_instances_remover._on_multimesh_instance_area_exited_main_area(area)
