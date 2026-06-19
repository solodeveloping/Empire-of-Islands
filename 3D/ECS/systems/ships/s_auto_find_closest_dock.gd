extends System
class_name AutoFindClosestDockSystem

func sub_systems():
	return [
		[
			ECS.world.query.with_all([C_Ship, C_ShipLookingForDock]),
			find_docks
		],
	]

func find_docks(entities: Array[Entity], _components: Array, _delta: float):
	# TODO: factions?
	var docks = ECS.world.query.with_all([C_DockBuoy]).execute()
	var exits = ECS.world.query.with_all([C_MapShipExitPoint, C_Transform]).execute()
	if docks.size() == 0:
		push_error("could not find a C_DockBuoy")
	if exits.size() == 0:
		push_error("could not find an exit")
	for entity in entities:
		# TODO : optimize
		var c_visited_buoys: C_DocksVisited = entity.get_component(C_DocksVisited)
		var c_transform: C_Transform = entity.get_component(C_Transform)
		if docks.size() == 0 or \
			c_visited_buoys.visited_dock_buoy_ids.size() >= c_visited_buoys.max_docks_to_visit:
			_find_and_assign_closest_exit(
				entity,
				c_transform,
				exits,
			)
			continue
		
		var closest_buoy: Entity = null
		var closest_transform: C_Transform = null
		var closestDistance: float = 0
		for i in range(0, docks.size()):
			var dock_buoy: Entity = docks[i]
			var c_dock_buoy: C_DockBuoy = dock_buoy.get_component(C_DockBuoy)
			if c_dock_buoy.id in c_visited_buoys.visited_dock_buoy_ids:
				continue
			var c_dock_transform: C_Transform = dock_buoy.get_component(C_Transform)
			var dist = c_transform.transform.origin.distance_to(
				c_dock_transform.transform.origin
			)
			# TODO: godot bug? when not assigning null
			if closest_transform == null or dist < closestDistance:
				closest_buoy = dock_buoy
				closest_transform = c_dock_transform
				closestDistance = dist
		
		if closest_transform == null:
			_find_and_assign_closest_exit(
				entity,
				c_transform,
				exits,
			)
		else:
			cmd.remove_component(entity, C_ShipLookingForDock)
			cmd.add_components(
				entity,
				[
					C_NavigationDestination.new(closest_transform.transform.origin),
					C_ShipMovingToDock.new(),
				]
			)
			cmd.remove_relationship(entity, Rels.going_to)
			cmd.add_relationship(entity, Rels.create_going_to(closest_buoy))

func _find_and_assign_closest_exit(
	entity: Entity,
	c_transform: C_Transform,
	entities_with_transform: Array,
):
	#var closestExit: Entity
	var closest_transform: C_Transform
	var closestDistance: float = 0
	for i in range(0, entities_with_transform.size()):
		var exit: Entity = entities_with_transform[i]
		var exit_transform: C_Transform = exit.get_component(C_Transform)
		var dist = c_transform.transform.origin.distance_to(
			exit_transform.transform.origin
		)
		if i == 0 or dist < closestDistance:
			#closestExit = exit
			closest_transform = exit_transform
			closestDistance = dist
	
	cmd.remove_component(entity, C_ShipLookingForDock)
	cmd.add_components(
		entity,
		[
			C_NavigationDestination.new(closest_transform.transform.origin),
			C_ShipMovingToExit.new(),
		]
	)
