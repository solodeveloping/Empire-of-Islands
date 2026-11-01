extends System
class_name EntityMiscSystem

#var check_remove_time: float = 0
#var check_remove_time_limit: float = 0.1
#
#func _ready() -> void:
	#check_remove_time = 0

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_RemoveEntity,
			])\
			#.enabled()\
			.iterate([
				C_RemoveEntity
			])\
			,
			remove_entities
		],
	]	

func remove_entities(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	# TODO: optimize
	
	var C_RemoveEntity_Index: int = 0
	
	for i in entities.size():
		var entity: Entity = entities[i]
		
		var c_remove: C_RemoveEntity = components[C_RemoveEntity_Index][i]

		if c_remove.remove_immediatly:
			cmd.remove_entity(
				entity
			)
			continue
		
		c_remove.time_limit -= delta
		if c_remove.time_limit <= 0:
			cmd.remove_entity(
				entity
			)
		
	
