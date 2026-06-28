@tool
extends Node3D

const CUBE_WITH_STATIC_BODY = preload("uid://nmaynqovhgo7")
const CUBE_WITH_STATIC_BODY_AND_TOOL_SCRIPT = preload("uid://mk2th34j416s")
const CUBE_WITH_STATIC_BODY_AND_TOOL_SCRIPT_AND_MORE_SHAPES = preload("uid://c27d44f87d2g3")
const CUBE_AS_SCN = preload("uid://xc1aov2caltv")
const CUBE_AS_SCN_NO_OVERLAP = preload("uid://dh788m7tsllug")


@export_tool_button("clear_children")
var clear_children = _clear_children

@export_tool_button("add_boxes_with_rigid_body")
var add_boxes_with_rigid_body = _add_boxes_with_rigid_body

@export_tool_button("add_boxes_with_rigid_body_and_tool_script")
var add_boxes_with_rigid_body_and_tool_script = _add_boxes_with_rigid_body_and_tool_script

@export_tool_button("add_boxes_with_rigid_body_and_tool_script_and_more_shapes")
var add_boxes_with_rigid_body_and_tool_script_and_more_shapes = _add_boxes_with_rigid_body_and_tool_script_and_more_shapes

@export_tool_button("add_boxes_as_scn")
var add_boxes_as_scn = _add_boxes_as_scn

@export_tool_button("add_boxes_as_scn_no_overlap")
var add_boxes_as_scn_no_overlap = _add_boxes_as_scn_no_overlap

@export_tool_button("add_boxes_using_custom_scene")
var add_boxes_using_custom_scene = _add_boxes_using_custom_scene


@export_tool_button("hide_visual_instances")
var hide_visual_instances = _hide_visual_instances

@export_tool_button("show_visual_instances")
var show_visual_instances = _show_visual_instances

@export_tool_button("hide_physics_bodies")
var hide_physics_bodies = _hide_physics_bodies

@export_tool_button("show_physics_bodies")
var show_physics_bodies = _show_physics_bodies

@export_tool_button("hide_collision_shapes")
var hide_collision_shapes = _hide_collision_shapes

@export_tool_button("show_collision_shapes")
var show_collision_shapes = _show_collision_shapes

@export_tool_button("count_physics_bodies")
var count_physics_bodies = _count_physics_bodies

@export
var add_with_ownership: bool = true

@export
var x_count: int = 40

@export
var y_count: int = 40

@export
var custom_scene: PackedScene

@onready var container: Node3D = $container

func _clear_children():
	NodeUtils.remove_all_children(container)

func _add_boxes_with_rigid_body():
	_add_instances(CUBE_WITH_STATIC_BODY)

func _add_boxes_with_rigid_body_and_tool_script():
	_add_instances(CUBE_WITH_STATIC_BODY_AND_TOOL_SCRIPT)

func _add_boxes_with_rigid_body_and_tool_script_and_more_shapes():
	_add_instances(CUBE_WITH_STATIC_BODY_AND_TOOL_SCRIPT_AND_MORE_SHAPES)

func _add_boxes_as_scn():
	_add_instances(CUBE_AS_SCN)

func _add_boxes_as_scn_no_overlap():
	_add_instances(CUBE_AS_SCN_NO_OVERLAP)

func _add_boxes_using_custom_scene():
	_add_instances(custom_scene)

func _add_instances(scene: PackedScene):
	Loggie.msg("_add_boxes_with_rigid_body").info()
	NodeUtils.remove_all_children(container)
	var i = 0
	var x_pos = 0
	var y_pos = 0
	for x in x_count:
		y_pos = 0
		for y in y_count:
			var instance: Node3D = scene.instantiate()
			instance.name = "box_%s" % [
				i,
			]
			i += 1
			if add_with_ownership:
				SceneUtils.add_child(container, instance, true)
				#SceneUtils.add_child(container, instance, false)
			else:
				SceneUtils.add_child(container, instance, false)
				#container.add_child(instance)
			instance.global_position.x = x_pos
			instance.global_position.z = y_pos
			
			y_pos += 5
			#y_pos += 1.5
		x_pos += 5
		#x_pos += 1.5
	
	Loggie.msg("_add_boxes_with_rigid_body:done").info()
	Loggie.msg("child count: %s" % [
		container.get_child_count(true),
	]).info()

func _hide_visual_instances():
	_hide_visual_instances_rec(self)
	
func _hide_visual_instances_rec(node: Node):
	if node is VisualInstance3D:
		node.hide()
	for child in node.get_children(true):
		_hide_visual_instances_rec(child)

func _show_visual_instances():
	_show_visual_instances_rec(self)
	
func _show_visual_instances_rec(node: Node):
	if node is VisualInstance3D:
		node.show()
	for child in node.get_children(true):
		_show_visual_instances_rec(child)

func _hide_physics_bodies():
	_hide_physics_bodies_rec(self)
	
func _hide_physics_bodies_rec(node: Node):
	if node is CollisionObject3D:
		node.hide()
	for child in node.get_children(true):
		_hide_physics_bodies_rec(child)
		
func _show_physics_bodies():
	_show_physics_bodies_rec(self)
	
func _show_physics_bodies_rec(node: Node):
	if node is CollisionObject3D:
		node.show()
	for child in node.get_children(true):
		_show_physics_bodies_rec(child)

func _hide_collision_shapes():
	_hide_collision_shapes_rec(self)
	
func _hide_collision_shapes_rec(node: Node):
	if node is CollisionShape3D:
		node.hide()
	for child in node.get_children(true):
		_hide_collision_shapes_rec(child)

func _show_collision_shapes():
	_show_collision_shapes_rec(self)

func _show_collision_shapes_rec(node: Node):
	if node is CollisionShape3D:
		node.show()
	for child in node.get_children(true):
		_show_collision_shapes_rec(child)

class ComputePhysicsBodiesResult:
	var collision_object_count: int = 0
	var collision_shape_count: int = 0

func _count_physics_bodies():
	var result: ComputePhysicsBodiesResult = ComputePhysicsBodiesResult.new()
	_count_physics_bodies_rec(self, result)
	Loggie.msg("Collision objects (bodies): %s, shapes: %s" % [
		result.collision_object_count,
		result.collision_shape_count,
	]).info()

func _count_physics_bodies_rec(node: Node, result: ComputePhysicsBodiesResult):
	if node is CollisionObject3D:
		result.collision_object_count += 1
	if node is CollisionShape3D:
		result.collision_shape_count += 1
	for child in node.get_children(true):
		_count_physics_bodies_rec(child, result)
