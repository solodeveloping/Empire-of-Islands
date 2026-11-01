extends System
class_name AttackSystem

const SHIP_BARREL_DROP_1 = preload("uid://c7iqtnp71y8dg")

#var ship_loot_y_position: float = -0.5
var ship_loot_y_position: float = 0

var check_in_range_time: float = 0
var check_in_range_time_limit: float = 0.1

var event_bus: EventBus

func _ready() -> void:
	check_in_range_time = 0
	event_bus = get_tree().current_scene.get_node("EventBus")

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_HasAggro,
				C_Attack,
			])\
			.with_none([
				C_AttackInCoolDown,
			])
			#.enabled()\
			.iterate([
				C_Attack,
			])\
			,
			verify_distances
		],
		[
			ECS.world.query.with_all([
				C_AttackInCoolDown,
			])\
			#.enabled()\
			.iterate([
				C_AttackInCoolDown,
			])\
			,
			compute_attack_cooldowns
		],
		[
			# FIXME: is this the best way?
			ECS.world.query.with_all([
				C_IsDoingAnimationAttack,
				C_Attack,
			])\
			#.enabled()\
			.iterate([
				C_IsDoingAnimationAttack,
				C_Attack,
			])\
			,
			do_attacks
		],
	]	

func verify_distances(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	check_in_range_time -= delta
	if check_in_range_time > 0:
		return
	check_in_range_time = check_in_range_time_limit
	
	var C_Attack_Index: int = 0
	
	for i in entities.size():
		var entity: Entity = entities[i]
		#if !("aggro_target" in entity):
			#printerr("aggro_target not in entity")
			#continue
		if !entity.has_meta("aggro_target"):
			printerr("entity does not has meta aggro_target")
			continue
		
		var c_attack: C_Attack = components[C_Attack_Index][i]
		
		# FIXME: should we use metas
		# or props?
		# TODO: 2D version?
		var target_ = entity.get_meta("aggro_target")
		# Info: entity could had been removed from elsewhere
		if !is_instance_valid(target_):
			entity.remove_meta("aggro_target")
			cmd.remove_component(
				entity,
				C_HasAggro,
			)
			cmd.remove_component(
				entity,
				C_NavigationDestination,
			)
			# FIXME: not that good?
			if entity.has_component(C_GainSpeedWhenAggroing):
				print("s_attack diminish speed")
				var c_gain: C_GainSpeedWhenAggroing = entity.get_component(
					C_GainSpeedWhenAggroing
				)
				var c_movement: C_Movement = entity.get_component(
					C_Movement
				)
				c_movement.speed -= c_gain.speed_gain
			continue
		
		var target: Node3D = target_ as Node3D
		
		# FIXME: not that good
		# Ray would be better
		# Center is used here, or the origin
		# We can be in range while still not "be in range"
		# TODO: also, target can be behind
		#var dist = target.global_position.distance_to(
			#entity.global_position
		#)
		#if dist > c_attack.attack_range:
			#continue
		
		var entities_in_attack_range: Dictionary[String, Entity] = entity.entities_in_attack_range
		if !entities_in_attack_range.has(target.id):
			print("no entities_in_attack_range %s" % [
				entity.get_path(),
			])
			continue
		
		# TODO: make sure it faces the target
		# here or in play_attack
		entity.play_attack()
		
		# TODO: system for when we don't want the entity to be moving when attacking
		# not always the case
		
		cmd.add_components(
			entity,
			[
				C_AttackInCoolDown.new(c_attack.attack_cooldown),
				C_IsDoingAnimationAttack.new(),
			]
		)

func compute_attack_cooldowns(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	# TODO: something more perf
	
	var C_AttackInCoolDown_Index: int = 0
	
	for i in entities.size():
		
		var c_anim: C_AttackInCoolDown = components[C_AttackInCoolDown_Index][i]
		c_anim.time -= delta
		if c_anim.time > 0:
			continue

		var entity: Entity = entities[i]
		# TODO: check if remove c_anim is better compared to C_AttackInCoolDown
		cmd.remove_component(
			entity,
			C_AttackInCoolDown
		)

func do_attacks(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	# FIXME: something more perf
	# use Time maybe
	# we know when it started
	
	var C_IsDoingAnimationAttack_Index: int = 0
	var C_Attack_Index: int = 1
	
	for i in entities.size():
		var entity: Entity = entities[i]
		var c_anim: C_IsDoingAnimationAttack = components[C_IsDoingAnimationAttack_Index][i]
		var c_attack: C_Attack = components[C_Attack_Index][i]
		c_anim.animation_time += delta
		c_anim.apply_attack_time += delta
		
		# FIXME: maybe 2 components?
		if c_anim.has_applied_attack == false:
			if c_anim.animation_time >= c_attack.apply_attack_delay_time:
				c_anim.has_applied_attack = true
				entity.play_apply_attack(c_attack.base_damage)
				
				var aggro_target: Entity = entity.get_meta("aggro_target")
				if aggro_target:
					var c_health: C_Health = aggro_target.get_component(
						C_Health
					)
					c_health.current -= c_attack.base_damage
					
					# TODO: damage counter?
					# In a system or here?
					
					if c_health.current <= 0:
						c_health.current = 0
						
						aggro_target.disable_physics()
						aggro_target.play_death()
						
						entity.remove_meta("aggro_target")
						
						entity.hide_has_aggro()
						
						cmd.remove_component(
							entity,
							C_HasAggro,
						)
						cmd.add_component(
							aggro_target,
							C_IsDead.new()
						)
						# FIXME: not that good?
						# Maybe a C_AggroJustDropped and a System?
						if entity.has_component(C_GainSpeedWhenAggroing):
							var c_gain: C_GainSpeedWhenAggroing = entity.get_component(
								C_GainSpeedWhenAggroing
							)
							var c_movement: C_Movement = entity.get_component(
								C_Movement
							)
							c_movement.speed -= c_gain.speed_gain
						
						var c_kill_count: C_KillCount = entity.get_component(
							C_KillCount
						)
						if c_kill_count:
							if aggro_target.has_component(C_Ship):
								c_kill_count.ships += 1
							elif aggro_target.has_component(C_PopUnit):
								c_kill_count.units += 1
							elif aggro_target.has_component(C_IsAnimal):
								c_kill_count.animals += 1
						
						# TODO: pop units
						
						# FIXME : not the best place?
						
						# FIXME: if we have revive at some point
						# Do the checks?
						var c_cargo_storage: C_CargoStorage = aggro_target.get_component(
							C_CargoStorage
						)
						if c_cargo_storage:
							for storage_ref: CargoResourceStorageDef in c_cargo_storage.storage.values():
								var instance: Entity = SHIP_BARREL_DROP_1.instantiate()
								var new_cargo: C_CargoStorage = C_CargoStorage.new()
								new_cargo.storage.set(
									storage_ref.item_id,
									# FIXME: could use the actual instance?
									storage_ref.duplicate(),
								)
								instance.add_component(new_cargo)
								ECS.world.add_entity(instance)
								var offset = Vector3(
									randf_range(-3, 3),
									ship_loot_y_position,
									randf_range(-3, 3),
								)
								instance.global_position = aggro_target.global_position + offset
							
							if c_cargo_storage.gold_count > 0:
								var instance: Entity = SHIP_BARREL_DROP_1.instantiate()
								var new_cargo: C_CargoStorage = C_CargoStorage.new(
									c_cargo_storage.gold_count,
								)
								instance.add_component(new_cargo)
								ECS.world.add_entity(instance)
								var offset = Vector3(
									randf_range(-3, 3),
									ship_loot_y_position,
									randf_range(-3, 3),
								)
								instance.global_position = aggro_target.global_position + offset
							
						# TODO: normal storage
						
						# Spawn population in the sea
						if aggro_target.has_component(C_ShipPopulation):
							ECS.world.emit_event(
								ECSEvents.SHIP_UNLOAD_AT_SEA_REQUESTED, 
								aggro_target,
								{
								}
							)
						
						if aggro_target.has_component(C_Ship):
							event_bus.send_ecs_ship_destroyed.emit(
								aggro_target
							)
						
						if aggro_target.has_component(C_HasDeathAnimation):
							var death_anim: C_HasDeathAnimation = aggro_target.get_component(
								C_HasDeathAnimation
							)
							cmd.add_component(
								aggro_target,
								C_DeathAnimationIsPlaying.new(
									death_anim.animation_time,
								)
							)
							# FIXME: not sure what is the best way to handle those cleanups
							cmd.remove_component(
								aggro_target,
								C_NavigationDestination,
							)
						else:
							# FIXME: something else
							# could just decrease y
							cmd.remove_entity(
								aggro_target
							)
						
						# TODO
						# Probably want another system?
						# This is reagroing
						var entities_in_aggro_range: Dictionary[String, Entity] = entity.entities_in_aggro_range
						print("entities_in_aggro_range %s %s" % [
							entity.get_path(),
							entities_in_aggro_range.size(),
						])
						# Change aggro?
						#if entity.has_component(C_ComputeDeAggro):
							#pass
					
					# end of killed unit region
					
				
				# remove this if we are using other things
				cmd.remove_component(
					entity,
					C_IsDoingAnimationAttack
				)
		
		# TODO: could stop moving until then
		# Or auto move anyway
		#if c_anim.animation_time 
		
