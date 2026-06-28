class_name NavigationSystem
extends System

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_NavigationDestination,
				C_NavigationAgent3D,
			]),
			move_agents
		],
	]

func move_agents(entities: Array[Entity], _components: Array, delta: float):
	if entities.size() == 0:
		return
	
	#print("move_agents %s" % [
		#entities.size(),
	#])
	
	for entity in entities:
		var c_navigation_agent: C_NavigationAgent3D = entity.get_component(C_NavigationAgent3D)
		var dest: C_NavigationDestination = entity.get_component(C_NavigationDestination)
		
		var nav_agent: NavigationAgent3D = entity.get_node(c_navigation_agent.navigation_agent_3d_path)
		
		#print("target %s %s" % [
			#dest.target,
			#nav_agent.get_final_position(),
		#])
		
		if nav_agent.target_position != dest.target:
			nav_agent.set_target_position(dest.target)
		
		if nav_agent.is_navigation_finished():
			print("navigation finished %s %s" % [
				entity.get_path(),
				dest.target,
			])
			# TODO : handle moving to dock, moving to exit
			cmd.remove_components(entity, [
				C_NavigationDestination,
				C_Velocity,
			])
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
			
			# Info: we are arriving at an exut
			if entity.has_component(C_ShipMovingToExit):
				print("ship exited the map")
				cmd.remove_entity(entity)
			continue

		var next_path_position: Vector3 = nav_agent.get_next_path_position()
		
		var c_trans: C_Transform = entity.get_component(C_Transform)
		var c_movement: C_Movement = entity.get_component(C_Movement)
		
		var dir: Vector3 = c_trans.transform.origin.direction_to(next_path_position)
		var vel: Vector3 = dir * c_movement.speed
		
		# TODO : make it configuraable
		var rotation_speed = 4
		var target_rotation = dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
		if abs(target_rotation - entity.rotation.y) > deg_to_rad(60):
			rotation_speed = 10
		entity.rotation.y = move_toward(
			entity.rotation.y,
			target_rotation,
			rotation_speed * delta
		)
		
		if entity.has_component(C_Velocity):
			var c_velocity: C_Velocity = entity.get_component(C_Velocity)
			c_velocity.velocity = vel
		else:
			var c_velocity: C_Velocity = C_Velocity.new()
			c_velocity.velocity = vel
			
			cmd.add_component(entity, c_velocity)
