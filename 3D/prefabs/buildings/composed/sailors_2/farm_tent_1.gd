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

@onready var white_icon_main: MeshInstance3D = $WhiteIconMain

@onready var multi_mesh_instances_remover: MultiMeshInstancesRemover = $MultiMeshInstancesRemover

@onready var minimap_entity_display_handler: MinimapEntityDisplayHandler = $MinimapEntityDisplayHandler

@onready var extensions: Node3D = $Extensions

@onready var ground_beds: Node3D = $GroundBeds

var is_constructible: bool:
	get:
		return building_editable_children_area.is_empty \
			and ground_sensor_editable_1.is_valid

var is_constructed: bool = false

var current_stages: Dictionary[int, int] = {}

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.Farm),
		C_Farm.new(),
		C_Name.new("Farm tent"),
		C_Transform.new(),
		C_Health.new(100),
		C_CanExtendFarm.new(),
		C_RangeBox.new(
			Vector3(
				50,
				1,
				50,
			)
		),
		#C_Production.new(
			#Resources.Types.Fish,
			#1,
			#3.0
		#),
		C_SlotProduction.new(
			9,
			Resources.Types.Tomato,
		),
		#C_CollectionBuilding.new(),
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
	else:
		c_trans.transform = self.global_transform
	
	var c_slots: C_SlotProduction = get_component(C_SlotProduction)
	if c_slots:
		for i in c_slots.slot_count:
			current_stages.set(
				i,
				-1
			)
	

func _ready() -> void:
	_on_state_changed()
	
	ground_sensor_editable_1.ray_ground_layers = ray_ground_layers

	ground_indicator.hide()
	
	if !Engine.is_editor_hint():
		white_icon_main.show()

func _on_BuildingWaterSensor1_state_changed() -> void:
	_on_state_changed()
	
func _on_state_changed():
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
	for node in extensions.get_children():
		if node is Entity:
			node.add_relationship(
				Rels.create_is_possible_extension_of(
					self
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
	ground_indicator.show()

func hide_ground_indicator():
	ground_indicator.hide()

func update_slot_progress(
	slot_index: int,
	progress_index: int,
	stages: BuiltinResourceGrowthStages,
):
	var current_stage: int = current_stages.get(
		slot_index
	)
	if current_stage == progress_index:
		return
	
	if !stages.stages.has(progress_index):
		return
	
	var stage: PackedScene = stages.stages[progress_index]
	
	var ground_bed: GroundDirtBed_1 = ground_beds.get_child(
		slot_index
	)
	
	ground_bed.update_visuals(
		stage
	)
	
	current_stages.set(
		slot_index,
		progress_index,
	)
	

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
