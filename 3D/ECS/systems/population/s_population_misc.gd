extends System
class_name PopulationMiscSystem

# Info : we put temporary or hard to classify or miscelleanous systems here
# If it concerns the population

@export
var jobless_leave_island_time: float = 30.0

@export
var looking_for_housing_leave_island_time: float = 30.0

func sub_systems():
	return [
		[
			# Info: could not use an Observer for that because the calls are sync
			ECS.world.query.with_all(
				[
					C_PopUnit,
					C_LookingForMoveTarget,
				]
			),
			find_move_targets
		],
		[
			ECS.world.query.with_all(
				[
					C_PopUnit,
					C_JobLess,
				]
			),
			increment_jobless_time
		],
		[
			ECS.world.query.with_all(
				[
					C_PopUnit,
					C_LookingForHousing,
				]
			),
			increment_looking_for_housing_time
		],
	]

func find_move_targets(
	entities: Array[Entity],
	_components: Array,
	_delta: float
):
	# FIXME: it's always 1 entity
	#print("find_move_targets %s %s" % [
		#entities[0].name,
		#entities.size(),
	#])
	if entities.size() > 1:
		printerr("find_move_targets %s" % [
			entities.size(),
		])
	
	for pop_unit in entities:
		LogMonitor.info(pop_unit.name, "find_move_targets %s" % [
			pop_unit.name,
		])
		var work_rel = pop_unit.get_relationship(Rels.works_at)
		var c_loc: C_PopUnitLocation = pop_unit.get_component(C_PopUnitLocation)
		
		# Info: moving to workplace if present
		if work_rel and work_rel.target:
			print("moving target will be work %s" % [
				pop_unit.name,
			])
			if c_loc.location == C_PopUnitLocation.LOCATION.WORKPLACE:
				printerr("unit is already at WORKPLACE")
			
			c_loc.location = C_PopUnitLocation.LOCATION.MOVING_ON_LAND
			cmd.add_component(
				pop_unit,
				C_NavigationDestination.new(
					work_rel.target.global_position
				)
			)
			cmd.add_component(
				pop_unit,
				C_PopMovingToTarget.new(
					C_PopMovingToTarget.MOVE_TARGET_TYPE.WORKPLACE,
				)
			)
			cmd.remove_component(
				pop_unit,
				C_LookingForMoveTarget
			)
			continue
		else:
			var c_pop_unit: C_PopUnit = pop_unit.get_component(C_PopUnit)
			if c_pop_unit.pop_type == 0:
				print("could not find work for %s" % [
					pop_unit.name,
				])
		
		# Moving to housing if present
		var housing_rel = pop_unit.get_relationship(Rels.lives_in)
		if housing_rel and housing_rel.target:
			print("moving target will be housing %s" % [
				pop_unit.name,
			])
			if c_loc.location != C_PopUnitLocation.LOCATION.HOUSING:
				c_loc.location = C_PopUnitLocation.LOCATION.MOVING_ON_LAND
				cmd.add_component(
					pop_unit,
					C_NavigationDestination.new(
						housing_rel.target.global_position
					)
				)
				cmd.add_component(
					pop_unit,
					C_PopMovingToTarget.new(
						C_PopMovingToTarget.MOVE_TARGET_TYPE.HOUSING,
					)
				)
			else:
				# Shouldn't be happening
				if c_loc.location == C_PopUnitLocation.LOCATION.HOUSING:
					printerr("pop_unit is already at housing")
			
			cmd.remove_component(
				pop_unit,
				C_LookingForMoveTarget
			)
			continue
		else:
			var c_pop_unit: C_PopUnit = pop_unit.get_component(C_PopUnit)
			if c_pop_unit.pop_type == 0:
				print("could not find housing for %s" % [
					pop_unit.name,
				])
		
		#print("has_housing: %s" % [
			#has_housing,
		#])
		
		if !work_rel and !housing_rel:
			var c_pop_unit: C_PopUnit = pop_unit.get_component(C_PopUnit)
			#print("has no housing or work %s %s" % [
				#pop_unit.name,
				#c_pop_unit.pop_type,
			#])
			if c_pop_unit.pop_type == 0:
				print("has no housing or work %s" % [
					pop_unit.name,
				])
			
			# Move to a dock if looking to leave island
			if pop_unit.has_component(C_LookingToLeaveIsland):
				#print("pop_unit looking to leave island %s %s" % [
					#pop_unit.has_component(C_JobLess),
					#pop_unit.has_component(C_LookingForHousing),
				#])
				var r_island = pop_unit.get_relationship(Rels.is_on_island)
				if r_island == null:
					printerr("r_island is null %s %s" % [
						pop_unit.has_component(C_JobLess),
						pop_unit.has_component(C_LookingForHousing),
					])
					continue
				
				var docks = Queries.find_docks_of_island(r_island.target)
				if !docks.is_empty():
					c_loc.location = C_PopUnitLocation.LOCATION.MOVING_ON_LAND
					cmd.add_component(
						pop_unit,
						C_NavigationDestination.new(
							docks[0].global_position
						)
					)
					cmd.add_component(
						pop_unit,
						C_PopMovingToTarget.new(
							C_PopMovingToTarget.MOVE_TARGET_TYPE.DOCK,
						)
					)
				else:
					print("no dock on the island %s" % [
						r_island.target,
					])
			
			# TODO: find a random loc to idle to
			# FIXME: seem to be bugged
			#c_loc.location = C_PopUnitLocation.LOCATION.MOVING_ON_LAND
			#var offset = Vector3(
				#randf_range(5, 10),
				#0,
				#randf_range(5, 10),
			#)
			#cmd.add_component(
				#pop_unit,
				#C_NavigationDestination.new(
					#pop_unit.global_position + offset
				#)
			#)
			#cmd.add_component(
				#pop_unit,
				#C_PopMovingToTarget.new(
					#C_PopMovingToTarget.MOVE_TARGET_TYPE.IDLING,
				#)
			#)
		else:
			printerr("should not be happening %s" % [
				pop_unit.name,
			])

func increment_jobless_time(
	entities: Array[Entity],
	_components: Array,
	delta: float
):
	for pop_unit in entities:
		var c_jobless: C_JobLess = pop_unit.get_component(C_JobLess)
		if !c_jobless:
			push_error("C_JobLess not found")
			continue
		c_jobless.jobless_time += delta
		
		if c_jobless.jobless_time < jobless_leave_island_time:
			continue
		
		# FIXME: should jobless_time be counted elsewhere?
		# would avoid the check
		if pop_unit.has_component(C_LookingToLeaveIsland):
			continue
		
		print("adding C_LookingToLeaveIsland because no work")
		cmd.add_component(
			pop_unit,
			C_LookingToLeaveIsland.new()
		)
		
		# FIXME: could put it elsewhere
		# and maybe optimize it
		var c_loc: C_PopUnitLocation = pop_unit.get_component(
			C_PopUnitLocation
		)
		if c_loc.location == C_PopUnitLocation.LOCATION.HOUSING:
			c_loc.location = C_PopUnitLocation.LOCATION.IDLE_ON_LAND
		
		cmd.add_component(
			pop_unit,
			C_LookingForMoveTarget.new()
		)
		

func increment_looking_for_housing_time(
	entities: Array[Entity],
	_components: Array,
	delta: float
):
	for entity in entities:
		var c_looking: C_LookingForHousing = entity.get_component(
			C_LookingForHousing
		)
		if !c_looking:
			push_error("C_LookingForHousing not found")
			continue
		c_looking.looking_for_housing_time += delta
		
		if c_looking.looking_for_housing_time < looking_for_housing_leave_island_time:
			continue
		
		# FIXME: should jobless_time be counted elsewhere?
		# would avoid the check
		if entity.has_component(C_LookingToLeaveIsland):
			continue
		
		print("adding C_LookingToLeaveIsland because no housing")
		cmd.add_component(
			entity,
			C_LookingToLeaveIsland.new()
		)
