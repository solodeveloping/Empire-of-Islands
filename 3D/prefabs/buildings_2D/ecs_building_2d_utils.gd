extends Node
class_name ECSBuilding2DUtils

# There is an identity region: small
# There is the detection region: bigger

# TOOD: proposal for this?
# Would be nice to be able to add the methods dynamically

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
		# detection area
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = c_vision.radius
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		collision_shape.shape = circle
		var area: Area2D = Area2D.new()
		#area.collision_layer = Global.physics_visible_entity_layers_2d
		area.collision_mask = Global.physics_visible_entity_layers_2d
		# maybe this is an optimization
		area.monitorable = false
		area.monitoring = true
		area.name = "AreaVisibilityDetection"
		entity.add_child(area)
		area.add_child(collision_shape)
		
		#if entity.has_method("_on_vision_area_body_entered"):
			#area.body_entered.connect(
				#Callable(entity, "_on_vision_area_body_entered")
			#)
			#area.body_exited.connect(
				#Callable(entity, "_on_vision_area_body_exited")
			#)
		
		if entity.has_method("_on_vision_area_area_entered"):
			area.area_entered.connect(
				Callable(entity, "_on_vision_area_area_entered")
			)
			area.area_exited.connect(
				Callable(entity, "_on_vision_area_area_exited")
			)
		
		_add_identity_area(entity)
		
static func _add_identity_area(
	entity: Entity,
):
	var circle2: CircleShape2D = CircleShape2D.new()
	circle2.radius = 50
	var collision_shape2: CollisionShape2D = CollisionShape2D.new()
	collision_shape2.shape = circle2
	var area2: Area2D = Area2D.new()
	area2.collision_layer = Global.physics_visible_entity_layers_2d
	#area.collision_mask = Global.physics_visible_entity_layers_2d
	# maybe this is an optimization
	area2.monitorable = true
	area2.monitoring = true
	area2.name = "AreaVisibilityIdentity"
	entity.add_child(area2)
	area2.add_child(collision_shape2)
	
