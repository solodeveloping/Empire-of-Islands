extends System
class_name Node3DMovementSystem

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_Velocity,
				C_Transform,
			]).with_none([
				C_CharacterBody3D
			]).iterate([
				C_Velocity,
				C_Transform,
			]),
			move_nodes
		],
	]

func move_nodes(
	entities: Array[Entity],
	components: Array,
	delta: float
):
	var C_Velocity_Index: int = 0
	var C_Transform_Index: int = 1
	
	for i in entities.size():
		var entity: Entity = entities[i]
		var vel: C_Velocity = components[C_Velocity_Index][i]
		var trans: C_Transform = components[C_Transform_Index][i]
		
		#print("move_node %s %s" % [
			#entity.name,
			#vel.velocity,
		#])
		
		entity.global_transform.origin += vel.velocity * delta
		
		trans.transform = entity.global_transform
