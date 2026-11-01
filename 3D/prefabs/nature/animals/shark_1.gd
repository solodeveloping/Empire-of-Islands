@tool
extends Entity
# TODO: find a name convention
class_name CharacterShark_1

const BASIC_FLOATING_TEXT_INDICATOR_1 = preload("uid://dbxbmrnml36xp")

const BLOOD_HIT_VFX_1 = preload("uid://byce3l57l0wt7")

@export_flags_3d_physics
var target_physics_layer: int = 0

@onready var characters_shark: CharacterSharkVisual_1 = $CharacterVisualContainer/Characters_Shark

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@onready var area_3d: Area3D = $Area3D
@onready var area_collision_shape_3d: CollisionShape3D = $Area3D/AreaCollisionShape3D

@onready var aggro_area_3d: Area3D = $AggroArea3D
@onready var aggro_collision_shape_3d: CollisionShape3D = $AggroArea3D/AggroCollisionShape3D

@onready var aggro_sprite_3d: Sprite3D = $AggroSprite3D

@onready var hit_vfx_1: StartOneShotParticleVFX = $HitVfx1

@onready var wood_hit_audio_stream_player_3d_1: AudioStreamPlayer3D = $WoodHitAudioStreamPlayer3D_1

@onready var can_attack_area_3d: Area3D = $CanAttackArea3D

@onready var aggro_area_indicator_vfx_2: AggroAreaIndicatorVFX_2 = $AggroAreaIndicatorVfx2

var entities_in_aggro_range: Dictionary[String, Entity]

var entities_in_attack_range: Dictionary[String, Entity]

# Info: we are not using it for now
# FIXME: should we be using this?
var aggro_target: Node3D

func define_components() -> Array:
	return [
		C_IsAnimal.new(),
		C_Name.new("Shark"),
		C_Health.new(100.0),
		C_Movement.new(
			8.0,
			4,
			8,
		),
		C_GainSpeedWhenAggroing.new(
			5
		),
		C_Transform.new(),
		C_NavigationAgent3D.new("NavigationAgent3D"),
		C_CharacterBody3D.new(),
		C_CanAggro.new(),
		# Info: can't put that in the editor
		# because will be overrided if overriding it
		# by putting it in the map
		C_CanDeAggro.new(
			true,
			200,
			true,
			100,
			true,
			15,
		),
		C_Attack.new(
			7,
			25,
			0.2,
			0,
			1,
		),
		C_KillCount.new(),
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform

func _ready() -> void:
	aggro_area_indicator_vfx_2.set_radius(
		aggro_collision_shape_3d.shape.radius,
	)
	aggro_area_indicator_vfx_2.hide()

#func _process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#return
	#computed_time += delta
	#if computed_time >= update_time:
		#computed_time = 0
		#if last_position.distance_to(self.global_position) >= 0.1:
			#character_visual.play_walk()
		#else:
			#character_visual.play_idle()
		
		#last_position = self.global_position

func enable_physics():
	collision_shape_3d.set_deferred("disabled", false)
	area_3d.monitorable = true
	area_3d.monitoring = true
	
	aggro_area_3d.monitorable = true
	aggro_area_3d.monitoring = true
	
	can_attack_area_3d.monitorable = true
	can_attack_area_3d.monitoring = true
	

func disable_physics():
	collision_shape_3d.set_deferred("disabled", true)
	
	area_3d.monitorable = false
	area_3d.monitoring = false
	
	aggro_area_3d.monitorable = false
	aggro_area_3d.monitoring = false
	
	can_attack_area_3d.monitorable = false
	can_attack_area_3d.monitoring = false


func _on_AggroArea3d_area_entered(area: Area3D) -> void:
	print("_on_AggroArea3d_area_entered %s" % [
		area.get_path(),
	])
	var entity = area.get_parent() as Entity
	if entity:
		print("adding entity %s" % [
			area.get_path(),
		])
		# FIXME: int id would be much better
		entities_in_aggro_range.set(
			entity.id,
			entity
		)

func _on_AggroArea3d_area_exited(area: Area3D) -> void:
	print("_on_AggroArea3d_area_exited %s" % [
		area.get_path(),
	])
	var entity = area.get_parent() as Entity
	if entity:
		print("removing entity %s" % [
			area.get_path(),
		])
		# FIXME: int id would be much better
		entities_in_aggro_range.erase(
			entity.id,
		)

func show_aggro_area():
	aggro_area_indicator_vfx_2.show()

func hide_aggro_area():
	aggro_area_indicator_vfx_2.hide()

func display_has_aggro():
	aggro_sprite_3d.show()

func hide_has_aggro():
	aggro_sprite_3d.hide()

func play_attack():
	characters_shark.play_attack()
	
func play_death():
	pass

# TODO: indicator VFX
func play_apply_attack(damage: float):
	#print("play_apply_attack")
	var _self: Node3D = self as Variant as Node3D
	var target = self.get_meta("aggro_target")
	if _self and target:
		var space_state = _self.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			_self.global_position,
			#aggro_target.global_position,
			target.global_position,
		)
		query.exclude = [self]
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.collision_mask = target_physics_layer
		var result = space_state.intersect_ray(query)
		if result:
			print("shark hit %s %s" % [
				result.collider.get_path(),
				result.position,
			])
			hit_vfx_1.global_position = result.position
		else:
			#print("hit nothing")
			hit_vfx_1.global_position = can_attack_area_3d.global_position
	
	hit_vfx_1.start()
	
	if !target:
		printerr("target is null")
	
	if target and target.has_component(C_PopUnit):
		print("add blood")
		var blood: StartOneShotParticleVFX = BLOOD_HIT_VFX_1.instantiate()
		get_tree().current_scene.add_child(blood)
		blood.global_position = target.global_position
		blood.start()
	
	wood_hit_audio_stream_player_3d_1.play()
	
	var floating_text: BasicFloatingTextIndicator_1 = BASIC_FLOATING_TEXT_INDICATOR_1.instantiate()
	get_tree().current_scene.add_child(floating_text)
	
	#var target = get_meta("aggro_target")
	var offset: Vector3 = Vector3(
		0,
		2,
		0,
	)
	floating_text.global_position = target.global_position + offset
	
	#print("position %s %s %s" % [
		#self.global_position,
		#target.global_position,
		#floating_text.global_position,
	#])
	
	floating_text.set_text(str(damage))
	floating_text.start_tween()

func _on_VerifyAggroValidityTimer_timeout() -> void:
	var offset: float = 1
	for entity in entities_in_aggro_range.values():
		var dist = self.global_position.distance_to(
			entity.global_position
		)
		if dist + offset > aggro_collision_shape_3d.shape.radius:
			printerr("entity should not be in range anymore %s %s %s %s" % [
				dist,
				aggro_collision_shape_3d.shape.radius,
				self.name,
				entity.name,
			])

func _on_CanAttackArea3d_area_entered(area: Area3D) -> void:
	print("_on_CanAttackArea3d_area_entered %s" % [
		area.get_path()
	])
	var area_parent: Entity = area.get_parent()
	if area_parent:
		entities_in_attack_range.set(
			area_parent.id,
			area_parent,
		)

func _on_CanAttackArea3d_area_exited(area: Area3D) -> void:
	var area_parent: Entity = area.get_parent()
	if area_parent:
		entities_in_attack_range.erase(
			area_parent.id,
		)
