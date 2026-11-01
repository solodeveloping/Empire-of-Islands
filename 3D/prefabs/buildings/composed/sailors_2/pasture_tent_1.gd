@tool
extends Entity

# TODO: should these scripts be here?

signal multimesh_instance_area_entered_main_area(area: MultiMeshInstanceArea)
signal multimesh_instance_area_exited_main_area(area: MultiMeshInstanceArea)

@export_flags_3d_physics
var ray_ground_layers: int = 0

@onready var building_editable_children_area: BuildingEditableChildrenArea = $BuildingEditableChildrenArea

@onready var ground_sensor_editable_1: GroundSensorEditable1 = $GroundSensorEditable1

@onready var sprite_indicator: Sprite3D = $SpriteIndicators/SpriteIndicator

@onready var ground_indicator: MeshInstance3D = $GroundIndicator

@onready var multi_mesh_instances_remover: MultiMeshInstancesRemover = $MultiMeshInstancesRemover

@onready var minimap_entity_display_handler: MinimapEntityDisplayHandler = $MinimapEntityDisplayHandler

@onready var extensions: Node3D = $Extensions

var is_constructible: bool:
	get:
		return building_editable_children_area.is_empty \
			and ground_sensor_editable_1.is_valid

var is_constructed: bool = false

var snap_objects: Array[Node3D] = []

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.Pasture),
		C_Name.new("Pasture"),
		C_Transform.new(),
		C_Health.new(100),
		#C_Production.new(
			#Resources.Types.Fish,
			#1,
			#3.0
		#),
		#C_CollectionBuilding.new(),
		C_CanExtendFarm.new(),
		C_RangeBox.new(
			Vector3(
				50,
				1,
				50,
			)
		),
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
			Populations.Types.Sailor: WorkerQuantity.new(
				Populations.Types.Sailor,
				0
			)
		})
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
	
	ground_indicator.hide()

func _on_BuildingWaterSensor1_state_changed() -> void:
	_on_state_changed()
	
func _on_state_changed():
	print("building_editable_children_area.is_empty %s" % [
		building_editable_children_area.is_empty,
	])
	print("ground_sensor_editable_1.is_valid %s" % [
		ground_sensor_editable_1.is_valid,
	])
	if is_constructible:
		sprite_indicator.modulate = Color.GREEN
	else:
		sprite_indicator.modulate = Color.RED

func _on_GroundSensorEditable1_state_changed() -> void:
	_on_state_changed()

func finalize_construction():
	print("FishermanTent:finalize_construction %s" % [
		self.name
	])
	is_constructed = true
	multi_mesh_instances_remover.disable_instance_areas()

func add_children_entities():
	var is_possible_extension_of = get_relationship(
		Rels.is_possible_extension_of
	)
	if !is_possible_extension_of:
		printerr("!is_extension_of not found in pasture tent")
		return
	
	for node in extensions.get_children():
		if node is Entity:
			node.add_relationship(
				Rels.create_is_possible_extension_of(
					is_possible_extension_of.target
				)
			)
			node.add_component(
				C_FarmExtension.new()
			)
			node.hide()
			ECS.world.add_entity(node)

func update_minimap_display():
	#print("update_minimap_display")
	minimap_entity_display_handler.update_display(
		self,
	)

func hide_indicators():
	sprite_indicator.hide()
	ground_sensor_editable_1.hide()
	for node in extensions.get_children():
		node.hide()

func show_ground_indicator():
	print("show_ground_indicator")
	ground_indicator.show()

func hide_ground_indicator():
	print("hide_ground_indicator")
	ground_indicator.hide()

# WARN: this could interact right back with the building's area
func show_all_tree_hidden():
	multi_mesh_instances_remover.show_all_instances()

func get_hidden_trees() -> Array[MultiMeshInstanceArea]:
	return multi_mesh_instances_remover.get_instances()

func _on_BuildingEditableChildrenArea_multimesh_instance_area_entered(area: MultiMeshInstanceArea) -> void:
	multimesh_instance_area_entered_main_area.emit(area)
	if !is_constructed:
		multi_mesh_instances_remover._on_multimesh_instance_area_entered_main_area(area)

func _on_BuildingEditableChildrenArea_multimesh_instance_area_exited(area: MultiMeshInstanceArea) -> void:
	multimesh_instance_area_exited_main_area.emit(area)
	if !is_constructed:
		multi_mesh_instances_remover._on_multimesh_instance_area_exited_main_area(area)

func _on_BuildingEditableChildrenArea_state_changed() -> void:
	_on_state_changed()


func _on_SnapArea3d_area_entered(area: Area3D) -> void:
	print("_on_SnapArea3d_area_entered")
	# FIXME: should do verifications here?
	snap_objects.push_back(area)

func _on_SnapArea3d_area_exited(area: Area3D) -> void:
	print("_on_SnapArea3d_area_exited")
	snap_objects.erase(area)
