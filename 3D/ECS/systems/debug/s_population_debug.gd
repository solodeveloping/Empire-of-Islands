extends System
class_name PopulationDebugSystem

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_PopUnit,
			])\
			,
			#.without_relationship([
				#Rels.built_on,
			#]),
			debug_pop_units
		],
	]

func debug_pop_units(
	entities: Array[Entity],
	_components: Array,
	_delta: float
):
	#print("debug_pop_units")
	for entity in entities:
		#LogMonitor.info(entity.name, "entity found", entity)
		if entity.has_component(C_LookingForMoveTarget):
			LogMonitor.info(entity.name, "pop_unit has C_LookingForMoveTarget", entity)
			if !entity.has_component(C_JobLess):
				if !entity.has_component(C_LookingForHousing):
					print("this might be weird %s" % [
						entity.name,
					])
