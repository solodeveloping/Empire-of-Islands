extends System
class_name WaterEnduranceSystem

#var check_remove_time: float = 0
#var check_remove_time_limit: float = 0.1
#
#func _ready() -> void:
	#check_remove_time = 0

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_HasWaterEndurance,
			])\
			#.enabled()\
			.with_none([
				C_IsDead,
			])
			.iterate([
				C_HasWaterEndurance
			])\
			,
			compute_endurances
		],
	]	

func compute_endurances(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	# TODO: optimize
	
	# Info: once per 0.5 seconds
	# See physics_ticks_per_second 
	var refresh: bool = (Engine.get_physics_frames() % 30 == 0)
	
	var C_HasWaterEndurance_Index: int = 0
	
	for i in entities.size():
		var entity = entities[i]
		var c_endurance: C_HasWaterEndurance = components[C_HasWaterEndurance_Index][i]
	
		c_endurance.time -= delta
		
		if refresh:
			entity.update_endurance_bar(
				remap(
					c_endurance.time,
					0,
					c_endurance.starting_time,
					0,
					1,
				)
			)
		
		if c_endurance.time > 0:
			continue
		
		var c_health: C_Health = entity.get_component(
			C_Health
		)
		c_health.current = 0
		
		entity.disable_physics()
		entity.play_water_death()
		entity.hide_endurance_bar()
		
		cmd.add_component(
			entity,
			C_IsDead.new(),
		)
		# TODO: different death anims?
		if entity.has_component(C_HasDeathAnimation):
			var death_anim: C_HasDeathAnimation = entity.get_component(
				C_HasDeathAnimation
			)
			cmd.add_component(
				entity,
				C_DeathAnimationIsPlaying.new(
					death_anim.animation_time,
				)
			)
			# FIXME: not sure what is the best way to handle those cleanups
			#cmd.remove_component(
				#entity,
				#C_NavigationDestination,
			#)
		else:
			# FIXME: something else
			# could just decrease y
			cmd.remove_entity(
				entity
			)
		
	
