class_name CharacterBody3DMovementSystem
extends System

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_CharacterBody3D,
				C_Velocity,
				C_Transform,
			])\
			.iterate([
				C_Velocity,
				C_Transform,
			]),
			move_bodies
		],
	]

func move_bodies(
	entities: Array[Entity],
	components: Array,
	_delta: float
):
	if entities.size() == 0:
		return
	
	#print("move_bodies %s" % [
		#entities.size(),
	#])
	
	var C_Velocity_Index: int = 0
	var C_Transform_Index: int = 1
	
	for i in entities.size():
		# TODO: open issues in github for godot
		#if is_instance_of(entity, CharacterBody3D):
		#if entity is CharacterBody3D:
		#var toto: CharacterBody3D
		#if true:
		var entity: Entity = entities[i]
		var vel: C_Velocity = components[C_Velocity_Index][i]
		var trans: C_Transform = components[C_Transform_Index][i]
		
		#print("move char %s %s" % [
			#entity.name,
			#vel.velocity,
		#])
		
		var _entity: CharacterBody3D
		#_entity.move_and_slide()
		#_entity.velocity
		
		entity.velocity = vel.velocity
		#entity.linear_velocity = vel.velocity
		
		if entity.move_and_slide():
			pass
		
		# FIXME: is this shit?
		vel.velocity = entity.velocity
		trans.transform = entity.global_transform
		#else:
			#push_error("entity %s is not a CharacterBody3D" % [
				#entity.name,
			#])
		
