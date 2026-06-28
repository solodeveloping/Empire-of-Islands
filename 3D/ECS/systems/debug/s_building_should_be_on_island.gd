extends System
class_name BuildingShouldBeOnIslandSystem

@export
var information_debug_scene: PackedScene

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_Building,
			])\
			.without_relationship([
				Rels.built_on,
			]),
			debug_buildings
		],
	]

func debug_buildings(
	entities: Array[Entity],
	_components: Array,
	_delta: float
):
	if entities.is_empty():
		return
	
	var msg = "buildings do not have a built_on relationship %s %s %s" % [
		entities.size(),
		entities[0].name,
		entities[0].get_path(),
	]
	printerr(msg)
	push_error(msg)
	
