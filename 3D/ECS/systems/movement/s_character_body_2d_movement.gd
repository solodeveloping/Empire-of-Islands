extends System
class_name CharacterBody2DMovementSystem

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_Velocity2D,
				C_Transform2D,
				C_CharacterBody2D,
			])\
			.iterate([
				C_Velocity2D,
				C_Transform2D,
				C_CharacterBody2D,
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
	
	#print("move_bodies_2d %s" % [
		#entities.size(),
	#])
	
	if entities.size() != components[0].size():
		printerr("sizes are different")
	
	#print("move_bodies %s" % [
		#entities.size(),
	#])
	
	# FIXME: add issues with sizes being different
	var C_Velocity2D_Index: int = 0
	var C_Transform2D_Index: int = 1
	
	for i in entities.size():
		var entity: Entity = entities[i]
		#var vel: C_Velocity2D = components[C_Velocity2D_Index][i]
		#var trans: C_Transform2D = components[C_Transform2D_Index][i]
		var vel: C_Velocity2D = entity.get_component(
			C_Velocity2D
		)
		var trans: C_Transform2D = entity.get_component(
			C_Transform2D
		)
		
		#print("move char %s %s" % [
			#entity.name,
			#vel.velocity,
		#])
		
		entity.velocity = vel.velocity
		
		if entity.move_and_slide():
			pass
		
		vel.velocity = entity.velocity
		trans.transform = entity.global_transform
		
