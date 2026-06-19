class_name Node3DMovementSystem
extends System

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_Velocity,
				C_Transform,
			]).with_none([
				C_CharacterBody3D
			]),
			move_nodes
		],
	]

func move_nodes(entities: Array[Entity], _components: Array, delta: float):
	for entity in entities:
		var vel: C_Velocity = entity.get_component(C_Velocity)
		var trans: C_Transform = entity.get_component(C_Transform)
		
		entity.global_transform.origin += vel.velocity * delta
		
		trans.transform = entity.global_transform
