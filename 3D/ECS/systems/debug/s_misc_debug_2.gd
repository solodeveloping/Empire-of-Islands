extends System
class_name MiscDebug2System

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_NavigationAgent2D,
			])\
			,
			debug_navigation_agent_2D
		],
		[
			ECS.world.query.with_all([
				C_NavigationDestination2D,
			])\
			,
			debug_navigation_destination_2D
		],
		[
			ECS.world.query.with_all([
				C_NavigationAgent2D,
				C_NavigationDestination2D,
			])\
			,\
			debug_both
		],
	]

func debug_navigation_agent_2D(
	entities: Array[Entity],
	_components: Array,
	_delta: float
):
	print("debug_navigation_agent_2D %s" % [
		entities.size(),
	])

func debug_navigation_destination_2D(
	entities: Array[Entity],
	_components: Array,
	_delta: float
):
	print("debug_navigation_destination_2D %s" % [
		entities.size(),
	])

func debug_both(
	entities: Array[Entity],
	_components: Array,
	_delta: float
):
	print("debug_both %s" % [
		entities.size(),
	])
