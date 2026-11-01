@tool
extends Entity
class_name Ship3D_ECS

# TODO : update UI as soon as possible

# TODO: a tool system to change size

const death_animation_time: float = 5

#@onready var ship_floating_ui_3d_1: ShipFloatingUI3D_1 = $ShipFloatingUI3D_1
@onready var update_floating_ui_timer: Timer = $UpdateFloatingUITimer

@onready var destruction_audio_stream_player_3d: AudioStreamPlayer3D = $DestructionAudioStreamPlayer3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@onready var area_3d: Area3D = $Area3D

@onready var loot_detection_area_3d_2: Area3D = $LootDetectionArea3D2

var has_loot_in_range: bool = false
var loot_entities: Array[Entity] = []

func define_components() -> Array:
	return [
		C_Ship.new(),
		C_Name.new("Ship"),
		C_Health.new(100.0),
		C_Movement.new(
			10.0,
			4,
			8,
		),
		C_Transform.new(),
		C_NavigationAgent3D.new("NavigationAgent3D"),
		# is an option
		C_CharacterBody3D.new(),
		C_HasDeathAnimation.new(death_animation_time)
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform

#func _physics_process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#return
	#print("ship pos %s %s" % [
		#self.get_path(),
		#self.global_position,
	#])

func enable_physics():
	collision_shape_3d.set_deferred("disabled", false)
	area_3d.monitorable = true
	area_3d.monitoring = true
	
	loot_detection_area_3d_2.monitorable = true
	loot_detection_area_3d_2.monitoring = true
	

func disable_physics():
	collision_shape_3d.set_deferred("disabled", true)
	
	area_3d.monitorable = false
	area_3d.monitoring = false
	
	loot_detection_area_3d_2.monitorable = false
	loot_detection_area_3d_2.monitoring = false
	

func play_death():
	update_floating_ui_timer.stop()
	#ship_floating_ui_3d_1.hide()
	
	destruction_audio_stream_player_3d.play()

	play_death_tween()

# TODO
# just Y doing down
# And anim player
# And some real stuff

# TODO: sound + VFX

func play_death_tween():
	# TODO: disable physics
	var dir = self.velocity
	dir += Vector3(
		0,
		-5,
		0,
	)
	var tween = create_tween()
	tween.tween_property(
		self,
		"position",
		dir,
		death_animation_time
	).from_current().as_relative()

# TODO: are we still using this?
# FIXME: might be worst than calling it from a system
# It is: fix it
func _on_UpdateFloatingUiTimer_timeout() -> void:
	#ship_floating_ui_3d_1.set_content(
		#self,
		#0
	#)
	pass


func _on_LootDetectionArea3d2_body_entered(body: Node3D) -> void:
	print("_on_LootDetectionArea3d2_body_entered")
	var body_: Entity = body as Variant as Entity
	if body_ is Entity:
		loot_entities.push_back(body)
		# FIXME: should we check first?
		if !has_loot_in_range:
			has_loot_in_range = true
	else:
		printerr("body is not Entity %s" % [
			body.get_path(),
		])

func _on_LootDetectionArea3d2_body_exited(body: Node3D) -> void:
	print("_on_LootDetectionArea3d2_body_exited")
	var body_: Entity = body as Variant as Entity
	if body_ is Entity:
		loot_entities.erase(body)
		if loot_entities.is_empty():
			has_loot_in_range = false
	else:
		printerr("body is not Entity %s" % [
			body.get_path(),
		])
