extends System
class_name MiscDebugSystem

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
	]

func add_debug_information(
	entities: Array[Entity],
	_components: Array,
	_delta: float
):
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
		else:
			relationship.target.set_text(
				"%s" % [
					c_name.name_,
				]
			)
		
