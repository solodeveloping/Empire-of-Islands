extends Node
class_name ECSBuilding2DUtils

static func setup_trans_and_vision(
	entity: Entity,
):
	var c_trans = entity.get_component(C_Transform2D) as C_Transform2D
	if not c_trans:
		push_error("transform component not found")
	else:
		c_trans.transform = entity.global_transform
	
	var c_vision = entity.get_component(C_CircularVision) as C_CircularVision
	if c_vision:
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = c_vision.radius
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		collision_shape.shape = circle
		var area: Area2D = Area2D.new()
		area.collision_layer = Global.physics_building_layers_2d
		entity.add_child(area)
		area.add_child(collision_shape)
