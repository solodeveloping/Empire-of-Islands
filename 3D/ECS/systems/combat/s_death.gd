extends System
class_name DeathSystem

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_DeathAnimationIsPlaying,
			])\
			#.enabled()\
			.iterate([
				C_DeathAnimationIsPlaying,
			])\
			,
			run_death_animations
		],
	]	

# TODO: something more perf?

func run_death_animations(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	var C_DeathAnimationIsPlaying_Index: int = 0
	
	for i in entities.size():
		var c_anim: C_DeathAnimationIsPlaying = components[C_DeathAnimationIsPlaying_Index][i]
		c_anim.time -= delta
		if c_anim.time > 0:
			continue
		
		var entity: Entity = entities[i]
		
		cmd.remove_entity(
			entity,
		)
		
		
