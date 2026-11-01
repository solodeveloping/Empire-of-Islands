extends System
class_name MiscDebugSystem

# TODO: a system for drawing
# and another for other stuff

@export
var information_debug_scene: PackedScene

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_Name,
				C_Transform,
			])\
			.without_relationship([
				Rels.information_is_being_debugged_by,
			]),
			add_debug_information
		],
		[
			ECS.world.query.with_all([
				C_Name,
				C_Transform,
			])\
			.with_relationship([
				Rels.information_is_being_debugged_by,
			]),
			debug_nodes
		],
		[
			ECS.world.query.with_all([
				C_NavigationDestination,
			])\
			.iterate([
				C_NavigationDestination,
			]),\
			debug_pathing
		],
	]

func add_debug_information(
	entities: Array[Entity],
	_components: Array,
	_delta: float
):
	# FIXME: this is causing issues
	# Entities that have this are iterated one by one
	# Because the archetype become unique per entity
	return
	if entities.is_empty():
		return
	#print("MiscDebugSystem:add_debug_information %s" % [
		#entities.size(),
	#])
	for entity in entities:
		var instance = information_debug_scene.instantiate()
		ECS.world.add_entity(instance)
		cmd.add_relationship(
			entity,
			Rels.create_information_is_being_debugged_by(instance)
		)

func debug_nodes(
	entities: Array[Entity],
	_components: Array,
	_delta: float,
):
	if entities.is_empty():
		return
	#print("MiscDebugSystem:debug_nodes %s" % [
		#entities.size(),
	#])
	for entity in entities:
		var relationship: Relationship = entity.get_relationship(
			Rels.information_is_being_debugged_by
		)
		if !relationship:
			push_error("debug relationship not present")
		if !relationship.target:
			push_error("debug relationship target not present")
		
		var c_name: C_Name = entity.get_component(C_Name)
		
		if entity.has_component(C_Island):
			relationship.target.global_position = Vector3(
				entity.global_position.x,
				entity.global_position.y + 20,
				entity.global_position.z,
			)
		elif entity.has_component(C_Ship):
			relationship.target.global_position = Vector3(
				entity.global_position.x,
				entity.global_position.y + 5,
				entity.global_position.z,
			)
		else:
			relationship.target.global_position = Vector3(
				entity.global_position.x,
				entity.global_position.y + 3,
				entity.global_position.z,
			)
		
		# FIXME: something more optimized
		if entity.visible:
			relationship.target.visible = true
		else:
			relationship.target.visible = false
		
		if entity.has_component(C_HousingCapacity):
			var c_housing: C_HousingCapacity = entity.get_component(C_HousingCapacity)
			relationship.target.set_text(
				"%s %s/%s" % [
					c_name.name_,
					c_housing.current,
					c_housing.maximum,
				]
			)
		elif entity.has_component(C_ShipPopulation):
			var c_pop: C_ShipPopulation = entity.get_component(C_ShipPopulation)
			relationship.target.set_text(
				"%s %s/%s" % [
					c_name.name_,
					c_pop.current,
					c_pop.maximum,
				]
			)
		elif entity.has_component(C_PopUnit):
			var c_pop_unit: C_PopUnit = entity.get_component(
				C_PopUnit
			)
			var has_housing = entity.has_relationship(Rels.lives_in)
			var has_work = entity.has_relationship(Rels.works_at)
			var suffix = ""
			suffix += str(c_pop_unit.pop_type) + " "
			if has_housing:
				suffix += "H "
			else:
				suffix += "NH "
			if has_work:
				suffix += "W "
			else:
				suffix += "NW "
			relationship.target.set_text(
				"%s %s" % [
					c_name.name_,
					suffix,
				]
			)
		else:
			relationship.target.set_text(
				"%s" % [
					c_name.name_,
				]
			)

func debug_pathing(
	entities: Array[Entity],
	components: Array,
	_delta: float
):
	return;
	#print("debug_pathing %s" % [
		#entities.size(),
	#])
	
	# FIXME: might be useless
	if entities.is_empty():
		return
	
	var C_NavigationDestination_Index: int = 0
	
	for i in entities.size():
		var entity: Entity = entities[i]
		var c_dest: C_NavigationDestination = components[C_NavigationDestination_Index][i]
		
		#var dist: float = Vector3.ZERO.distance_to(
			#c_dest.target,
		#)
		#if dist > 200:
			#printerr("dist is big %s %s %s" % [
				#entity.get_path(),
				#c_dest.target,
				#dist,
			#])
		#
		#if Engine.get_physics_frames() % 10 == 0:
			#print("debug stuff %s %s %s" % [
				#entity.get_path(),
				#c_dest.target,
				#dist,
			#])
		
		DebugDraw3D.draw_line(
			entity.global_position,
			c_dest.target,
			Color.PURPLE,
		)
		DebugDraw3D.draw_sphere(
			c_dest.target,
			4,
			Color.PURPLE,
		)
		#DebugDraw3D.draw_arrow(
			#entity.global_position,
			#c_dest.target,
			#Color.PURPLE,
			#0.1,
		#)
