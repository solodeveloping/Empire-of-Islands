class_name ProductionSystem
extends System

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

func produce_resources(entities: Array[Entity], _components: Array, delta: float):
	for entity in entities:
		var c_production: C_Production = entity.get_component(C_Production)
		
		var efficiency: float = 1
		# do avg of all effieicny
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
		the_storage.put_as_much_as_possible(
			c_production.production_type,
			c_production.production_per_cycle
		)
		c_production.time = c_production.production_time
		
		# Production building transforming resources
		var c_has_resources = entity.get_component(C_HasResources)
		if c_has_resources:
			cmd.remove_component(entity, C_HasResources)
			cmd.add_component(entity, C_AwaitingResources)
