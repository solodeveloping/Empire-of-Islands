extends Observer
class_name O_PopulationMovementObserver

# TODO: move the enums elsewhere

enum POP_UNIT_WORK_SYSTEM {
	TIMER_BASED_HIDE_POP,
	TIMER_BASED_IDLE_POP,
	SIMULATE_WORK,
}

@export
var pop_unit_work_system: POP_UNIT_WORK_SYSTEM = POP_UNIT_WORK_SYSTEM.TIMER_BASED_HIDE_POP

enum POP_UNIT_HOME_IDLING_SYSTEM {
	HIDE,
	IDLE,
}

@export
var pop_unit_home_idling_system: POP_UNIT_HOME_IDLING_SYSTEM = POP_UNIT_HOME_IDLING_SYSTEM.HIDE

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_all([C_PopUnit]).on_event(
				ECSEvents.POP_UNIT_REACHED_MOVE_TARGET
			),
			_on_pop_unit_reached_move_target
		],
	]

func _on_pop_unit_reached_move_target(
	_event: Variant,
	entity: Entity,
	_data: Variant,
):
	var c_loc: C_PopUnitLocation = entity.get_component(
		C_PopUnitLocation
	)
	var c_moving: C_PopMovingToTarget = entity.get_component(
		C_PopMovingToTarget
	)
	if c_moving:
		match c_moving.move_target_type:
			C_PopMovingToTarget.MOVE_TARGET_TYPE.WORKPLACE:
				c_loc.location = C_PopUnitLocation.LOCATION.WORKPLACE
				match pop_unit_work_system:
					POP_UNIT_WORK_SYSTEM.TIMER_BASED_HIDE_POP:
						entity.hide()
						entity.disable_physics()
						var works_at = entity.get_relationship(Rels.works_at)
						if !works_at:
							printerr("!works_at but reached workplace")
						var c_workers: C_Workers = works_at.target.get_component(C_Workers)
						var c_unit: C_PopUnit = entity.get_component(C_PopUnit)
						var workers: WorkerQuantity = c_workers.present_workers.get(c_unit.pop_type)
						workers.worker_count += 1
					_:
						printerr("pop_unit_work_system %s is not implemented" % [
							pop_unit_work_system,
						])
			C_PopMovingToTarget.MOVE_TARGET_TYPE.HOUSING:
				c_loc.location = C_PopUnitLocation.LOCATION.HOUSING
				match pop_unit_home_idling_system:
					POP_UNIT_HOME_IDLING_SYSTEM.HIDE:
						entity.hide()
						entity.disable_physics()
					POP_UNIT_HOME_IDLING_SYSTEM.IDLE:
						pass
						# TODO: implement an idling sytem
					_:
						printerr("pop_unit_home_idling_system %s is not implemented" % [
							pop_unit_home_idling_system,
						])
			C_PopMovingToTarget.MOVE_TARGET_TYPE.DOCK:
				# TODO: option choose to hide or not
				c_loc.location = C_PopUnitLocation.LOCATION.DOCK
				entity.hide()
				entity.disable_physics()
			C_PopMovingToTarget.MOVE_TARGET_TYPE.IDLING:
				pass
				# TODO: implement something better
				#cmd.add_component(
					#entity,
					#C_LookingForMoveTarget.new(),
				#)
			C_PopMovingToTarget.MOVE_TARGET_TYPE.ORDER:
				pass
				# TODO: implement something
				# return to work after some time for instance
			_:
				printerr("move_target_type %s is not implemented" % [
					c_moving.move_target_type,
				])
	
		cmd.remove_component(
			entity,
			C_PopMovingToTarget
		)
	else:
		printerr("pop_unit does not have C_PopMovingToTarget")
		entity.hide()
		entity.disable_physics()
