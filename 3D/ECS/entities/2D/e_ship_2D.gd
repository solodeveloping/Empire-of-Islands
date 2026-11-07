@tool
extends Entity
class_name Ship2D_ECS

# Info: kept the 3D code for later

#const death_animation_time: float = 5

#@onready var destruction_audio_stream_player_3d: AudioStreamPlayer3D = $DestructionAudioStreamPlayer3D
#
#@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
#
#@onready var area_3d: Area3D = $Area3D
#
#@onready var loot_detection_area_3d_2: Area3D = $LootDetectionArea3D2

#var has_loot_in_range: bool = false
#var loot_entities: Array[Entity] = []

@export
#var selected_color: Color = Color.hex(0xcffc339)
var selected_color: Color = Color.YELLOW

@export
var mouse_hover_color: Color = Color.WHITE

@onready var sprites: Node2D = $Sprites

@onready var east_sprite_2d: Sprite2D = $Sprites/EastSprite2D
@onready var south_east_sprite_2d: Sprite2D = $Sprites/SouthEastSprite2D
@onready var south_sprite_2d: Sprite2D = $Sprites/SouthSprite2D
@onready var south_west_sprite_2d: Sprite2D = $Sprites/SouthWestSprite2D
@onready var west_sprite_2d: Sprite2D = $Sprites/WestSprite2D
@onready var north_west_sprite_2d: Sprite2D = $Sprites/NorthWestSprite2D
@onready var north_sprite_2d: Sprite2D = $Sprites/NorthSprite2D
@onready var north_east_sprite_2d: Sprite2D = $Sprites/NorthEastSprite2D

@onready var selection_sprite_2d: Sprite2D = $SelectionSprite2D

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var event_bus: EventBus

var is_selected: bool = false
var is_mouse_hover: bool = false

# clock-wise but anti circle
#enum Direction {
	#EAST,
	#SOUTH_EAST,
	#SOUTH,
	#SOUTH_WEST,
	#WEST,
	#NORTH_EAST,
	#NORTH,
	#NORTH_WEST,
#}
# anti-clock-wise but circle wise
enum Direction {
	EAST,
	NORTH_EAST,
	NORTH,
	NORTH_WEST,
	WEST,
	SOUTH_WEST,
	SOUTH,
	SOUTH_EAST,
}

var direction: Direction = Direction.SOUTH

const ANGLE_SECTION = 45.0

var last_position: Vector2 = Vector2.ZERO

func define_components() -> Array:
	return [
		C_Ship.new(),
		C_Name.new("Ship"),
		C_Health.new(250.0),
		C_Movement.new(
			#10.0 * 8,
			10.0 * 16 * 2,
			4,
			8,
		),
		# In 2D, the size is in pixels
		C_CircularVision.new(250),
		C_Transform2D.new(),
		C_NavigationAgent2D.new("NavigationAgent2D"),
		C_CharacterBody2D.new(),
		#C_Velocity2D.new(),
		#C_HasDeathAnimation.new(death_animation_time)
	]

func on_ready():
	ECSBuilding2DUtils.setup_trans_and_vision(
		self
	)

func _ready():
	if Engine.is_editor_hint():
		return
	
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

	# Info: code if not using the ECS systems
	# Make sure to not await during _ready.
	#actor_setup.call_deferred()
	
	var current_scene = get_tree().current_scene
	if current_scene.has_node("EventBus"):
		event_bus = current_scene.get_node("EventBus")
		event_bus.send_selection_changed.connect(
			_on_event_bus_send_selection_changed
		)
	
	selection_sprite_2d.hide()
	
	# Info: this is for testing the rotation of the ship
	#for i in 360:
		#print("Tests: %s %s" % [
			#i,
			#get_index_from_deg_angle(float(i)),
		#])

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	
	var direction_ = last_position.direction_to(
		self.position
	)
	last_position = self.position
	
	update_facing(direction_)
	update_animation()

func update_facing(direction_vector: Vector2) -> void:
	if direction_vector == Vector2.ZERO:
		#print("direction_vector is ZERO")
		return
	
	var angle := rad_to_deg(
		atan2(-direction_vector.y, direction_vector.x)
	)
	var index = get_index_from_deg_angle(angle)
	
	direction = index as Direction

func get_index_from_deg_angle(angle: float) -> int:
	angle = fposmod(angle, 360)
	
	var index := int(round(angle / ANGLE_SECTION))
	
	index = posmod(index, 8)
	
	return index

func update_animation() -> void:
	match direction:
		Direction.EAST:
			#print("show EAST")
			east_sprite_2d.show()
			NodeUtils.hide_other_children(
				sprites,
				east_sprite_2d,
			)
		Direction.SOUTH_EAST:
			#print("show SOUTH_EAST")
			south_east_sprite_2d.show()
			NodeUtils.hide_other_children(
				sprites,
				south_east_sprite_2d,
			)
		Direction.SOUTH:
			#print("show SOUTH")
			south_sprite_2d.show()
			NodeUtils.hide_other_children(
				sprites,
				south_sprite_2d,
			)
		Direction.SOUTH_WEST:
			#print("show SOUTH_WEST")
			south_west_sprite_2d.show()
			NodeUtils.hide_other_children(
				sprites,
				south_west_sprite_2d,
			)
		Direction.WEST:
			#print("show WEST")
			west_sprite_2d.show()
			NodeUtils.hide_other_children(
				sprites,
				west_sprite_2d,
			)
		Direction.NORTH_WEST:
			#print("show NORTH_WEST")
			north_west_sprite_2d.show()
			NodeUtils.hide_other_children(
				sprites,
				north_west_sprite_2d,
			)
		Direction.NORTH:
			#print("show NORTH")
			north_sprite_2d.show()
			NodeUtils.hide_other_children(
				sprites,
				north_sprite_2d,
			)
		Direction.NORTH_EAST:
			#print("show NORTH_EAST")
			north_east_sprite_2d.show()
			NodeUtils.hide_other_children(
				sprites,
				north_east_sprite_2d,
			)
		_:
			push_error("unrecognized direction %s" % [
				direction
			])

# TODO: physics, destruction, loot, etc

#func enable_physics():
	#collision_shape_3d.set_deferred("disabled", false)
	#area_3d.monitorable = true
	#area_3d.monitoring = true
	#
	#loot_detection_area_3d_2.monitorable = true
	#loot_detection_area_3d_2.monitoring = true
	#
#
#func disable_physics():
	#collision_shape_3d.set_deferred("disabled", true)
	#
	#area_3d.monitorable = false
	#area_3d.monitoring = false
	#
	#loot_detection_area_3d_2.monitorable = false
	#loot_detection_area_3d_2.monitoring = false
	#
#
#func play_death():
	#update_floating_ui_timer.stop()
	##ship_floating_ui_3d_1.hide()
	#
	#destruction_audio_stream_player_3d.play()
#
	#play_death_tween()
#
## TODO: sound + VFX
#
#func play_death_tween():
	## TODO: disable physics
	#var dir = self.velocity
	#dir += Vector3(
		#0,
		#-5,
		#0,
	#)
	#var tween = create_tween()
	#tween.tween_property(
		#self,
		#"position",
		#dir,
		#death_animation_time
	#).from_current().as_relative()

#func _on_LootDetectionArea3d2_body_entered(body: Node3D) -> void:
	#print("_on_LootDetectionArea3d2_body_entered")
	#var body_: Entity = body as Variant as Entity
	#if body_ is Entity:
		#loot_entities.push_back(body)
		## FIXME: should we check first?
		#if !has_loot_in_range:
			#has_loot_in_range = true
	#else:
		#printerr("body is not Entity %s" % [
			#body.get_path(),
		#])
#
#func _on_LootDetectionArea3d2_body_exited(body: Node3D) -> void:
	#print("_on_LootDetectionArea3d2_body_exited")
	#var body_: Entity = body as Variant as Entity
	#if body_ is Entity:
		#loot_entities.erase(body)
		#if loot_entities.is_empty():
			#has_loot_in_range = false
	#else:
		#printerr("body is not Entity %s" % [
			#body.get_path(),
		#])

# FIXME: there is a recursion at the moment
func _on_event_bus_send_selection_changed(node):
	if node == self:
		return
	if is_selected == false:
		return
	deselect()

func select():
	print("Ship2D_ECS:select")
	is_selected = true
	# modulate = Color.YELLOW
	selection_sprite_2d.modulate = selected_color
	if !selection_sprite_2d.visible:
		selection_sprite_2d.show()

func deselect():
	print("Ship2D_ECS:deselect")
	is_selected = false
	# modulate = Color.WHITE
	if is_mouse_hover:
		selection_sprite_2d.modulate = mouse_hover_color
	else:
		selection_sprite_2d.hide()
	
	# WARN: do not emit an event here
	# Or there will be infinite recursion

func _unhandled_input(event: InputEvent) -> void:
	#print("Ship2D_ECS:_unhandled_input")
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("left_click"):
			if is_selected:
				deselect()
				event_bus.send_ecs_ship_deselected.emit(self)

# TODO: replace with a raysystem?
#var query := PhysicsPointQueryParameters2D.new()
#query.position = get_global_mouse_position()
#query.collide_with_areas = true
#query.collide_with_bodies = true
#
#var hits := get_world_2d().direct_space_state.intersect_point(query)
#
#if not hits.is_empty():
	#var clicked = hits[0].collider
func _on_SelectionArea2d_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if not is_selected and event.is_action_pressed("left_click"):
		select()
		event_bus.send_ecs_ship_selected.emit(self)

func _on_SelectionArea2d_mouse_entered() -> void:
	is_mouse_hover = true
	if is_selected:
		return
	selection_sprite_2d.modulate = mouse_hover_color
	selection_sprite_2d.show()

func _on_SelectionArea2d_mouse_exited() -> void:
	is_mouse_hover = false
	if is_selected:
		return
	selection_sprite_2d.hide()

# Info: this is for other ships
# not the ship as itself
# the ship seeing should notify the other one

func _on_vision_area_area_entered(
	area: Area2D
):
	print("_on_vision_area_body_entered %s %s" % [
		self.get_path(),
		area.get_path(),
	])
	if area == self or area.get_parent() == self:
		return
	
	if !area.get_parent().has_method("handle_area_entered"):
		return
	
	if area.get_parent().get_meta(StaticFactions.BELONGS_TO_LOCAL_PLAYER_META, false):
		return
	
	area.get_parent().handle_area_entered(self)
	

func _on_vision_area_area_exited(
	area: Area2D
):
	print("_on_vision_area_body_exited %s %s" % [
		self.get_path(),
		area.get_path(),
	])
	if area == self or area.get_parent() == self:
		return
	
	if !area.get_parent().has_method("handle_area_exited"):
		return
	
	# Info: this caches Rels.belongs_to_faction
	# So we don't have to query it
	if area.get_parent().get_meta(StaticFactions.BELONGS_TO_LOCAL_PLAYER_META, false):
		return
	
	area.get_parent().handle_area_exited(self)

var inside_visions: Dictionary[int, int] = {}

func handle_area_entered(
	entity: Entity
):
	print("handle_area_entered %s" % [
		inside_visions.size(),
	])
	inside_visions.set(
		entity.ecs_id,
		entity.ecs_id,
	)
	set_meta("is_visible", true)

func handle_area_exited(
	entity: Entity
):
	print("handle_area_exited %s" % [
		inside_visions.size(),
	])
	inside_visions.erase(
		entity.ecs_id,
	)
	if inside_visions.size() <= 0:
		set_meta("is_visible", false)
