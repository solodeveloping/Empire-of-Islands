class_name CharacterBody3DMovementSystem
extends System

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_CharacterBody3D,
				C_Velocity,
				C_Transform,
			]),
			move_bodies
		],
	]

func move_bodies(entities: Array[Entity], _components: Array, _delta: float):
	if entities.size() == 0:
		return
	
	print("move_bodies %s" % [
		entities.size(),
	])
	
	for entity in entities:
		# TODO: open issues in github for godot
		#if is_instance_of(entity, CharacterBody3D):
		#if entity is CharacterBody3D:
		#var toto: CharacterBody3D
		if true:
			var vel: C_Velocity = entity.get_component(C_Velocity)
			var trans: C_Transform = entity.get_component(C_Transform)
			
			entity.velocity = vel.velocity
			
			if entity.move_and_slide():
				pass
			
			vel.velocity = entity.velocity
			trans.transform = entity.global_transform
		else:
			push_error("entity %s is not a CharacterBody3D" % [
				entity.name,
			])
		
