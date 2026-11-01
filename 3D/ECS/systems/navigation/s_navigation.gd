extends System
class_name NavigationSystem

signal ship_arrived_at_dock(ship: Entity, dock: Entity)

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_NavigationDestination,
				C_NavigationAgent3D,
			])\
			.iterate([
				C_NavigationDestination,
				C_NavigationAgent3D,
			])
			,
			move_agents
		],
		[
			ECS.world.query.with_all([
				C_NavigationDestination2D,
				C_NavigationAgent2D,
			])\
			.iterate([
				C_NavigationDestination2D,
				C_NavigationAgent2D,
			])
			,
			move_agents_2d
		],
	]

func move_agents(
	entities: Array[Entity],
	components: Array,
	delta: float
):
	if entities.size() == 0:
		return

	#print("move_agents %s" % [
		#entities.size(),
	#])

	var C_NavigationDestination_Index: int = 0
	var C_NavigationAgent3D_Index: int = 1

	for i in entities.size():
		var entity: Entity = entities[i]
		var dest: C_NavigationDestination = components[C_NavigationDestination_Index][i]
		var c_navigation_agent: C_NavigationAgent3D = components[C_NavigationAgent3D_Index][i]

		# TODO: could have a ref, it never changes
		var nav_agent: NavigationAgent3D = entity.get_node(
			c_navigation_agent.navigation_agent_3d_path
		)

		#print("target %s %s" % [
			#dest.target,
			#nav_agent.get_final_position(),
		#])

		if nav_agent.target_position != dest.target:
			nav_agent.set_target_position(dest.target)

		if nav_agent.is_navigation_finished():
			#print("navigation finished %s %s" % [
				#entity.get_path(),
				#dest.target,
			#])

			# Info: we are arriving at a dock
			# TODO : move it elsewhere
			if entity.has_component(C_ShipMovingToDock):
				var c_docks_visited: C_DocksVisited = entity.get_component(C_DocksVisited)
				var r_going_to = entity.get_relationship(Rels.going_to)
				var buoy = r_going_to.target as Entity
				#var c_dock_buoy: C_DockBuoy = buoy.get_component(C_DockBuoy)
				c_docks_visited.visited_dock_buoy_ids.push_back(
					#c_dock_buoy.id
					buoy.id,
				)
				cmd.add_component(entity, C_ShipWaitingAtDock.new(10.0))

				var r_dock: Relationship = buoy.get_relationship(
					Relationship.new(
						R_BelongsTo.new()
					)
				)
				if !r_dock:
					push_error("dock not found")

				var dock: Entity = r_dock.target
				var r_island: Relationship = dock.get_relationship(
					Relationship.new(
						R_BuiltOn.new()
					)
				)
				if !r_island:
					push_error("island not found")

				var island: Entity = r_island.target
				if !island:
					push_error("island is null")

				ECS.world.emit_event(
					ECSEvents.SHIP_UNLOAD_REQUESTED,
					entity,
					{
						"buoy": buoy,
						"dock": dock,
						"island": island,
					}
				)

				ship_arrived_at_dock.emit(
					entity,
					dock,
				)

			# Info: we are arriving at an exut
			if entity.has_component(C_ShipMovingToExit):
				print("ship exited the map")
				cmd.remove_entity(entity)

			if entity.has_component(C_PopUnit):
				#print("pop_unit arrived at destination")
				ECS.world.emit_event(
					ECSEvents.POP_UNIT_REACHED_MOVE_TARGET,
					entity,
					{}
				)

			if entity.has_component(C_FollowPath):
				#print("entity has C_FollowPath")
				# FIXME: we can deaggro while not gaining aggro
				if entity.has_component(C_IsDeAggroing):
					print("removing C_IsDeAggroing %s %s %s %s" % [
						entity.get_path(),
						Engine.get_physics_frames(),
						entity.global_position,
						dest.target,
					])
					cmd.remove_component(
						entity,
						C_IsDeAggroing,
					)
					#cmd.remove_component(
						#entity,
						#
					#)
				# FIXME: not good
				if entity.has_component(C_HasAggro):
					return
				# TODO: this is bad
				var c_follow_path: C_FollowPath = entity.get_component(
					C_FollowPath
				)
				if entity.has_meta("path_3d_node"):
					var follow_path_node: Path3D = entity.get_meta(
						"path_3d_node"
					)
					c_follow_path.target_path_point_index += 1
					if c_follow_path.target_path_point_index >= follow_path_node.curve.point_count:
						c_follow_path.target_path_point_index = 0

					dest.target = follow_path_node.curve.get_point_position(
						c_follow_path.target_path_point_index
					)

					return
				else:
					printerr("node does not have path_3d_node")
					pass


			# TODO : handle moving to dock, moving to exit
			cmd.remove_components(entity, [
				C_NavigationDestination,
				C_Velocity,
			])

			continue

		# TODO: way of debugging this
		var next_path_position: Vector3 = nav_agent.get_next_path_position()

		var c_trans: C_Transform = entity.get_component(C_Transform)
		var c_movement: C_Movement = entity.get_component(C_Movement)

		# FIXME: could we just use transform?

		var dir: Vector3 = c_trans.transform.origin.direction_to(
			next_path_position
		)
		#var dir: Vector3 = entity.global_transform.origin.direction_to(
			#next_path_position
		#)

		# TODO : make it configuraable
		var rotation_speed = c_movement.rotation_speed
		var target_rotation = dir.signed_angle_to(
			Vector3.MODEL_FRONT,
			Vector3.DOWN,
		)
		if abs(target_rotation - entity.rotation.y) > deg_to_rad(90):
			rotation_speed = c_movement.fast_rotation_speed

		#print("rotating %s %s" % [
			#entity.rotation.y,
			#target_rotation,
		#])

		# this is bad
		#entity.rotation.y = move_toward(
			#entity.rotation.y,
			#target_rotation,
			#rotation_speed * delta
		#)

		# TODO: now shark can't attack closeby without something here
		# somthing like moving away and coming back
		# this is good
		entity.rotation.y = rotate_toward(
			entity.rotation.y,
			target_rotation,
			rotation_speed * delta
		)

		# WARNING
		# FIXME: entity can just circle around if the target is at their loc

		#print("moving %s" % [
			#entity.name,
		#])
		#
		#print("after rotating %s" % [
			#entity.rotation.y,
		#])

		# TODO: for shark
		# when path is 1.5
		# the shark just circle around
		# not sure how to fix it
		# start at right pos or something maybe

		#var vel: Vector3
		#if entity.has_component(C_CharacterBody3D):
			# Info: old way; works fine
			#vel = dir * c_movement.speed
			#var _entity: CharacterBody3D = entity as Variant as CharacterBody3D
			#vel = entity.transform.basis.z * c_movement.speed
		#else:
			#vel = entity.transform.basis.z * c_movement.speed

		if c_movement.speed < 0:
			printerr("speed is negative %s %s" % [
				entity.get_path(),
				c_movement.speed,
			])

		var vel: Vector3 = entity.transform.basis.z * c_movement.speed

		if entity.has_component(C_Velocity):
			var c_velocity: C_Velocity = entity.get_component(C_Velocity)
			c_velocity.velocity = vel
		else:
			var c_velocity: C_Velocity = C_Velocity.new()
			c_velocity.velocity = vel

			cmd.add_component(entity, c_velocity)

# FIXME: should it be in it's own class?
func move_agents_2d(
	entities: Array[Entity],
	components: Array,
	_delta: float
):
	if entities.size() == 0:
		print("no entities")
		return

	#print("move_agents %s" % [
		#entities.size(),
	#])

	var C_NavigationDestination2D_Index: int = 0
	var C_NavigationAgent2D_Index: int = 1

	for i in entities.size():
		var entity: Entity = entities[i]
		var dest: C_NavigationDestination2D = components[C_NavigationDestination2D_Index][i]
		var c_navigation_agent: C_NavigationAgent2D = components[C_NavigationAgent2D_Index][i]

		# TODO: could have a ref, it never changes
		var nav_agent: NavigationAgent2D = entity.get_node(
			c_navigation_agent.navigation_agent_2d_path
		)

		if nav_agent.target_position != dest.target:
			nav_agent.set_target_position(dest.target)

		if nav_agent.is_navigation_finished():
			#print("navigation finished %s %s" % [
				#entity.get_path(),
				#dest.target,
			#])

			# Info: we are arriving at a dock
			# TODO : move it elsewhere
			if entity.has_component(C_ShipMovingToDock):
				var c_docks_visited: C_DocksVisited = entity.get_component(
					C_DocksVisited
				)
				var r_going_to = entity.get_relationship(Rels.going_to)
				var buoy = r_going_to.target as Entity
				#var c_dock_buoy: C_DockBuoy = buoy.get_component(C_DockBuoy)
				c_docks_visited.visited_dock_buoy_ids.push_back(
					#c_dock_buoy.id
					buoy.id,
				)
				cmd.add_component(entity, C_ShipWaitingAtDock.new(10.0))

				var r_dock: Relationship = buoy.get_relationship(
					Relationship.new(
						R_BelongsTo.new()
					)
				)
				if !r_dock:
					push_error("dock not found")

				var dock: Entity = r_dock.target
				var r_island: Relationship = dock.get_relationship(
					Relationship.new(
						R_BuiltOn.new()
					)
				)
				if !r_island:
					push_error("island not found")

				var island: Entity = r_island.target
				if !island:
					push_error("island is null")

				ECS.world.emit_event(
					ECSEvents.SHIP_UNLOAD_REQUESTED,
					entity,
					{
						"buoy": buoy,
						"dock": dock,
						"island": island,
					}
				)

				ship_arrived_at_dock.emit(
					entity,
					dock,
				)

			# Info: we are arriving at an exut
			if entity.has_component(C_ShipMovingToExit):
				print("ship exited the map")
				cmd.remove_entity(entity)

			if entity.has_component(C_PopUnit):
				#print("pop_unit arrived at destination")
				ECS.world.emit_event(
					ECSEvents.POP_UNIT_REACHED_MOVE_TARGET,
					entity,
					{}
				)

			if entity.has_component(C_FollowPath):
				#print("entity has C_FollowPath")
				# FIXME: we can deaggro while not gaining aggro
				if entity.has_component(C_IsDeAggroing):
					print("removing C_IsDeAggroing %s %s %s %s" % [
						entity.get_path(),
						Engine.get_physics_frames(),
						entity.global_position,
						dest.target,
					])
					cmd.remove_component(
						entity,
						C_IsDeAggroing,
					)
					#cmd.remove_component(
						#entity,
						#
					#)
				# FIXME: not good
				if entity.has_component(C_HasAggro):
					return
				# TODO: this is bad
				var c_follow_path: C_FollowPath = entity.get_component(
					C_FollowPath
				)
				if entity.has_meta("path_3d_node"):
					var follow_path_node: Path2D = entity.get_meta(
						"path_2d_node"
					)
					c_follow_path.target_path_point_index += 1
					if c_follow_path.target_path_point_index >= follow_path_node.curve.point_count:
						c_follow_path.target_path_point_index = 0

					dest.target = follow_path_node.curve.get_point_position(
						c_follow_path.target_path_point_index
					)

					return
				else:
					printerr("node does not have path_3d_node")
					pass


			# TODO : handle moving to dock, moving to exit
			cmd.remove_components(entity, [
				C_NavigationDestination2D,
				C_Velocity2D,
			])

			continue

		# TODO: way of debugging this
		var next_path_position: Vector2 = nav_agent.get_next_path_position()

		var c_trans: C_Transform2D = entity.get_component(C_Transform2D)
		var c_movement: C_Movement = entity.get_component(C_Movement)

		# FIXME: could we just use transform?

		var dir: Vector2 = c_trans.transform.origin.direction_to(
			next_path_position
		)

		var vel: Vector2 = dir * c_movement.speed

		if entity.has_component(C_Velocity2D):
			var c_velocity: C_Velocity2D = entity.get_component(
				C_Velocity2D
			)
			c_velocity.velocity = vel
		else:
			var c_velocity: C_Velocity2D = C_Velocity2D.new()
			c_velocity.velocity = vel

			cmd.add_component(entity, c_velocity)
