class_name ProductionSystem
extends System

# TODO: should the storage emit events?
signal produced_resources(changes: Dictionary[int, int])

@export var the_storage: Node

func sub_systems():
	return [
		# FIXME: do we need both components
		[
			ECS.world.query.with_all([C_Production, C_CollectionBuilding]),
			produce_resources
		],
		[
			ECS.world.query.with_all([C_Production, C_HasResources]),
			produce_resources
		],
	]

# TODO : handle remove worker

# FIXME : different methods?
# don't need it

func produce_resources(entities: Array[Entity], _components: Array, delta: float):
	#print("produce_resources %s" % [
		#entities.size(),
	#])
	var changes: Dictionary[int, int] = {}
	for entity in entities:
		var c_production: C_Production = entity.get_component(C_Production)
		
		var efficiency: float = 1
		# do avg of all efficiency
		if entity.has_component(C_WorkerRequirement):
			var c_requirement: C_WorkerRequirement = entity.get_component(C_WorkerRequirement)
			if !entity.has_component(C_Workers):
				continue
			
			var total = 0
			var missing_workers = false
			var c_workers: C_Workers = entity.get_component(C_Workers)
			for req in c_requirement.requirements:
				var workers = c_workers.workers[req.worker_type]
				# FIXME : use min_count
				if workers.worker_count < req.min_count:
					#print("missing workers %s %s %s" % [
						#entity.name,
						#entity.get_path(),
						#workers.worker_count,
					#])
					missing_workers = true
					break
					
				total += (workers.worker_count / req.worker_count)
		
			if missing_workers:
				continue
		
			efficiency = (total / c_requirement.requirements.size())
		
		c_production.time -= (delta * efficiency)
		
		if c_production.time > 0:
			#print("time", c_production.time)
			continue
		
		# TODO : handle too much prod
		# TODO : building you can collect from
		#print(
			#"increasing res",
			#c_production.production_type,
			#c_production.production_per_cycle
		#)
		var put_result = the_storage.put_as_much_as_possible(
			c_production.production_type,
			c_production.production_per_cycle
		)
		c_production.time = c_production.production_time
		
		# Info: this is for production building transforming resources
		var c_has_resources = entity.get_component(C_HasResources)
		if c_has_resources:
			cmd.remove_component(entity, C_HasResources)
			cmd.add_component(entity, C_AwaitingResources)
			
		if put_result.successful == true and put_result.quantity_put > 0:
			#print("successfully produced resources")
			if changes.has(put_result.item_id):
				changes[put_result.item_id] += put_result.quantity_put
			else:
				changes.set(put_result.item_id, put_result.quantity_put)
	
	if changes.keys().size() > 0:
		produced_resources.emit(changes)
