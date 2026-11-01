@tool
extends Entity
class_name SimpleCharacter1

@onready var character_visual: SimpleCharacterVisual1 = $CharacterVisualContainer/CharacterVisual

@onready var adventurer: SimpleCharacterVisual1 = $CharacterVisualContainer/Adventurer

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var area_collision_shape_3d: CollisionShape3D = $Area3D/CollisionShape3D
@onready var area_3d: Area3D = $Area3D

@onready var endurange_progress_bar_1: EndurangeProgressBar1 = $EndurangeProgressBar1
@onready var health_progress_bar_1: HealthProgressBar1 = $HealthProgressBar1

@onready var water_bubbles_vfx_1: StartOneShotParticleVFX = $WaterBubblesVfx1

# FIXME : could be done in ECS
# should it be done in ECS?
var update_time: float = 0.1
var computed_time: float = 0
var last_position: Vector3 = Vector3.ZERO

var is_in_water: bool = false

var initial_collision_layer: int = 0
var initial_collision_mask: int = 0

func define_components() -> Array:
	return [
		# TODO : option to have simple name or dual name
		#C_Name.new("John"),
		C_Health.new(100.0),
		C_Movement.new(
			5.0,
			4,
			8,
		),
		C_Transform.new(),
		C_NavigationAgent3D.new("NavigationAgent3D"),
		#C_PopUnitLocation.new(),
		C_CharacterBody3D.new(),
		C_HasDeathAnimation.new(3.0),
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform

func _ready() -> void:
	initial_collision_layer = self.get("collision_layer")
	initial_collision_mask = self.get("collision_mask")
	#print("layers %s %s" % [
		#initial_collision_layer,
		#initial_collision_mask,
	#])

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	computed_time += delta
	if computed_time >= update_time:
		computed_time = 0
		if last_position.distance_to(self.global_position) >= 0.1:
			if is_in_water == false:
				character_visual.play_walk()
				adventurer.play_walk()
		else:
			if is_in_water == false:
				character_visual.play_idle()
				adventurer.play_idle()
		
		last_position = self.global_position

# TODO: proper way for doing this
# There is an issue on github
# Not sure what is best
# Edit: There is no "proper way"
# https://github.com/godotengine/godot-proposals/issues/3424
func enable_physics():
	#collision_shape_3d.set_deferred("disabled", false)
	#area_collision_shape_3d.set_deferred("disabled", false)
	self.set("collision_layer", initial_collision_layer)
	self.set("collision_mask", initial_collision_mask)
	#area_3d.collision_layer = initial_collision_layer
	#area_3d.collision_mask = initial_collision_mask
	area_3d.monitorable = true
	area_3d.monitoring = true
	#PhysicsServer3D.space_create()

func disable_physics():
	#collision_shape_3d.set_deferred("disabled", true)
	#area_collision_shape_3d.set_deferred("disabled", true)
	self.set("collision_layer", 0)
	self.set("collision_mask", 0)
	#area_3d.collision_layer = 0
	#area_3d.collision_mask = 0
	area_3d.monitorable = false
	area_3d.monitoring = false

func play_death():
	character_visual.play_death()
	adventurer.play_death()

func play_swim_idle():
	character_visual.play_swim_idle()
	adventurer.play_swim_idle()

func play_water_death():
	water_bubbles_vfx_1.start()
	
	character_visual.play_death()
	adventurer.play_death()
	
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
		3.0
	).from_current().as_relative()
	

func update_health_bar(progress: float):
	health_progress_bar_1.set_progress(
		progress
	)

func update_endurance_bar(progress: float):
	endurange_progress_bar_1.set_progress(
		progress
	)

func hide_endurance_bar():
	endurange_progress_bar_1.hide()

func _print_all():
	_print_all_components()

func _print_all_components():
	print("")
	for key in components.keys():
		print("_print_all_components: %s %s %s %s %s" % [
			self.name,
			key,
			components.get(key).get_class(),
			components.get(key).get_script().get_path(),
			components.get(key),
		])
