extends System
class_name PaySystem

signal gold_count_changed(changes_per_faction: Dictionary[int, int])

func sub_systems():
	return [
		[
			ECS.world.query.with_all([C_Working,]),
			pay_entities
		],
		[
			ECS.world.query.with_all([C_NotGettingPaid,]),
			process_entities_not_getting_paid
		],
	]

func pay_entities(
	entities: Array[Entity],
	_components: Array,
	delta: float
):
	#print("produce_resources %s" % [
		#entities.size(),
	#])
	var gold_count_changes_per_faction: Dictionary[int, int] = {}
	for entity: Entity in entities:
		var c_working: C_Working = entity.get_component(C_Working)
		if c_working.is_active == false:
			continue
		
		c_working.working_time += delta
		
		if c_working.working_time <= c_working.pay_time_limit:
			continue
			
		var c_storage: C_Storage = entity.get_component(C_Storage)
		if !c_storage:
			printerr("C_Storage not found")
			continue
		
		# Info: we have to query the building
		# because that's the entity that pays the workers
		var r_works_at = entity.get_relationship(Rels.works_at)
		if !r_works_at:
			printerr("works_at not found")
			continue
		
		# FIXME: get_relationship is kinda slow compared to get_compoent
		# or instant access
		var r_faction = r_works_at.target.get_relationship(Rels.works_at)
		if !r_faction:
			printerr("r_faction not found")
			continue
		
		var c_faction: C_Faction = r_faction.target.get_component(C_Faction)
		var faction_c_storage: C_Storage = r_faction.target.get_component(
			C_Storage
		)
		if faction_c_storage.gold_count >= c_working.pay:
			faction_c_storage.gold_count -= c_working.pay
			c_storage.gold_count += c_working.pay
			c_working.working_time = 0
			
			if gold_count_changes_per_faction.has(c_faction.faction_id):
				gold_count_changes_per_faction[c_faction.faction_id] -= c_working.pay
			else:
				gold_count_changes_per_faction.set(
					c_faction.faction_id,
					-c_working.pay,
				)
			
			# TODO: other systems for not getting paid
			if entity.has_component(C_NotGettingPaid):
				var c_not_getting_paid: C_NotGettingPaid = entity.get_component(
					C_NotGettingPaid
				)
				if c_not_getting_paid.stopped_working:
					var c_workers: C_Workers = r_works_at.target.get_component(
						C_Workers
					)
					var c_pop_unit: C_PopUnit = entity.get_component(
						C_PopUnit
					)
					var workers: WorkerQuantity = c_workers.present_workers.get(
						c_pop_unit.pop_type
					)
					
					workers.worker_count += 1
					
				cmd.remove_component(
					entity,
					C_NotGettingPaid
				)
				
		else:
			var c_not_getting_paid: C_NotGettingPaid = entity.get_component(
				C_NotGettingPaid
			)
			if !c_not_getting_paid:
				cmd.add_component(
					entity,
					C_NotGettingPaid.new(10)
				)
	
	if !gold_count_changes_per_faction.is_empty():
		gold_count_changed.emit(
			gold_count_changes_per_faction
		)

func process_entities_not_getting_paid(
	entities: Array[Entity],
	_components: Array,
	delta: float
):
	#print("process_entities_not_getting_paid %s" % [
		#entities.size(),
	#])
	# TODO: discontentment system
	# And reputation system
	for entity: Entity in entities:
		var c_not_getting_paid: C_NotGettingPaid = entity.get_component(
			C_NotGettingPaid
		)
		c_not_getting_paid.time += delta
		
		if c_not_getting_paid.time <= c_not_getting_paid.stop_working_time_limit:
			continue
		
		var r_works_at = entity.get_relationship(Rels.works_at)
		if !r_works_at:
			printerr("works_at not found")
			continue
			
		var c_workers: C_Workers = r_works_at.target.get_component(
			C_Workers
		)
		var c_pop_unit: C_PopUnit = entity.get_component(
			C_PopUnit
		)
		var workers: WorkerQuantity = c_workers.present_workers.get(
			c_pop_unit.pop_type
		)
		
		workers.worker_count -= 1
		c_not_getting_paid.stopped_working = true
		
		# TODO: leave at some point
		
