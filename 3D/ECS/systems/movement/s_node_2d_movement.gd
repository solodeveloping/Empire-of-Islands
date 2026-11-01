extends System
class_name Node2DMovementSystem

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_Velocity2D,
				C_Transform2D,
			]).with_none([
				C_CharacterBody2D
			]).iterate([
				C_Velocity2D,
				C_Transform2D,
			]),
			move_nodes
		],
	]

func move_nodes(
	entities: Array[Entity],
	components: Array,
	delta: float
):
	var C_Velocity2D_Index: int = 0
	var C_Transform2D_Index: int = 1
	
	for i in entities.size():
		var entity: Entity = entities[i]
		var vel: C_Velocity2D = components[C_Velocity2D_Index][i]
		var trans: C_Transform2D = components[C_Transform2D_Index][i]
		
		#print("move_node %s %s" % [
			#entity.name,
			#vel.velocity,
		#])
		
		entity.global_transform.origin += vel.velocity * delta
		
		trans.transform = entity.global_transform
