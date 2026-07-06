extends Node
class_name Queries

static func find_docks_of_island(island: Entity) -> Array:
	var docks = ECS.world.query.with_all([C_Dock])\
		.with_relationship([Rels.create_built_on(island)])\
		.execute()
	return docks

static func find_main_squares_of_island(island: Entity) -> Array:
	var entities = ECS.world.query.with_all([C_MainSquare])\
		.with_relationship([Rels.create_built_on(island)])\
		.execute()
	return entities
