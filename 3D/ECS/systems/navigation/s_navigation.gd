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
			print("navigation finished")
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
				var target_entity = r_going_to.target as Entity
				var c_dock_buoy: C_DockBuoy = target_entity.get_component(C_DockBuoy)
				c_docks_visited.visited_dock_buoy_ids.push_back(c_dock_buoy.id)
				cmd.add_component(entity, C_ShipWaitingAtDock.new(10.0))
				
				# TODO : move it to another system?
				if entity.has_component(C_ShipPopulation):
					var c_ship_population: C_ShipPopulation = entity.get_component(C_ShipPopulation)
					if !c_ship_population:
						continue
						
					if c_ship_population.current <= 0:
						continue
					
					# FIXME: better system
					# Info: we have to duplicate because we receive a copy
					var pop_units: Array = ECS.world.query.with_relationship([
						Relationship.new(R_TravelsIn.new(), entity),
					]).execute().duplicate()
					
					print("found %s - %s pop_units travelling in ship" % [
						pop_units.size(),
						c_ship_population.current,
					])
					
					if pop_units.is_empty():
						printerr("no pop units travelling in ship found")
						#continue
					
					if pop_units.size() != c_ship_population.current:
						push_error("c_pop_units.size() %s != c_ship_population.current %s" % [
							pop_units.size(),
							c_ship_population.current,
						])
					
					# Info: this can break before the loop is done
					# If it's not a duplicated array
					#for pop_unit in pop_units:
					for i in pop_units.size():
						print("emitting POP_UNIT_JOINED %s" % [
							i,
						])
						# Info: this is synchronous, the event will be processed before moving on
						# to the next loop
						ECS.world.emit_event(
							ECSEvents.POP_UNIT_JOINED, 
							#pop_unit,
							pop_units[i],
							{}
						)
						
						cmd.remove_relationship(pop_units[i], Rels.travels_in)
					
					#print("done iterating %s" % [
						#pop_units.size()
					#])
			
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
