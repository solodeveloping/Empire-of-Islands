extends System
class_name ShipWaitingAtDockSystem

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_ShipWaitingAtDock
			]).with_none([
				C_IsDead
			]),
			process_ships
		],
	]

# TODO : should we spawn population here?

func process_ships(entities: Array[Entity], _components: Array, delta: float):
	for entity in entities:
		var c_ship_waiting_at_dock: C_ShipWaitingAtDock = entity.get_component(
			C_ShipWaitingAtDock
		)
		c_ship_waiting_at_dock.time -= delta
		if c_ship_waiting_at_dock.time > 0:
			continue
		
		# TODO: a sound or something
		# TODO: can optimize?
		
		cmd.remove_component(entity, C_ShipWaitingAtDock)
		cmd.add_component(entity, C_ShipLookingForDock.new())
		
