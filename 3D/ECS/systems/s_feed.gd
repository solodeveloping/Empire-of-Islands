extends System
class_name FeedSystem

signal consumed_resources(changes_per_faction: Dictionary[int, Dictionary])
signal pop_units_died(changes_per_faction: Dictionary[int, Dictionary])
signal workers_died(changes_per_faction: Dictionary[int, Dictionary])
signal island_population_changed(islands: Dictionary[Entity, int])

# TODO: this probably should control the instantiation of a system
enum FeedSystemOption {
	USE_UNIT_FACTION_GLOBAL_FOOD,
}

@export
var feed_system_option: FeedSystemOption = FeedSystemOption.USE_UNIT_FACTION_GLOBAL_FOOD

# TODO: could be better to have all these in same place
# Production & Consumption
# TODO: could be per entity
# If we need it
@export
var consume_resources_time_limit: float = 10

@export
var starving_death_time_limit: float = 30

# TODO: satisfaction stuff
# TODO: find a way to have autocompletion in the Editor
@export
var food_consumptions: Dictionary[Populations.Types, ConsumptionList] = {}

func sub_systems():
	return [
		[
			ECS.world.query.with_all([C_ConsumeResources,]),
			feed_entities
		],
		[
			ECS.world.query.with_all([C_IsStarving,]),
			process_starving_entities
		],
	]

func feed_entities(
	entities: Array[Entity],
	_components: Array,
	delta: float
):
	#print("feed_entities %s" % [
		#entities.size(),
	#])
	var changes_per_faction: Dictionary[int, Dictionary] = {}
	
	for entity: Entity in entities:
		var c_consume_resources: C_ConsumeResources = entity.get_component(
			C_ConsumeResources
		)
		c_consume_resources.time += delta
		if c_consume_resources.time <= consume_resources_time_limit:
			continue
		
		match feed_system_option:
			FeedSystemOption.USE_UNIT_FACTION_GLOBAL_FOOD:
				var r_faction = entity.get_relationship(
					Rels.belongs_to_faction
				)
				var faction: Faction_ECS = r_faction.target
				var c_faction: C_Faction = faction.get_component(
					C_Faction
				)
				
				if c_faction.def.is_neutral_faction:
					var r_works_at = entity.get_relationship(
						Rels.works_at
					)
					if r_works_at:
						var r_faction_2 = r_works_at.target.get_relationship(
							Rels.belongs_to_faction
						)
						faction = r_faction_2.target
						c_faction = faction.get_component(
							C_Faction
						)
					else:
						# TODO: option to take housing if present
						pass
					
				var c_pop_unit: C_PopUnit = entity.get_component(
					C_PopUnit
				)
				var consumption_list: ConsumptionList = food_consumptions.get(
					c_pop_unit.pop_type
				)
				
				var found_all: bool = true
				for consumption: Builtin_Resource_Requirement in consumption_list.needed:
					# TODO: could have consume at least as an option
					if faction.storage_node.has_at_least(
						consumption.resource_type,
						consumption.resource_count,
					):
						var result = faction.storage_node.take_at_least(
							consumption.resource_type,
							consumption.resource_count,
						)
						if !result.successful:
							printerr("!result.successful when taking food")
							found_all = false
							break
						
						var changes: Dictionary[int, int]
						if changes_per_faction.has(c_faction.faction_id):
							changes = changes_per_faction.get(c_faction.faction_id)
						else:
							changes = {}
							changes_per_faction.set(c_faction.faction_id, changes)
						
						if changes.has(consumption.resource_type):
							changes[consumption.resource_type] -= consumption.resource_count
						else:
							changes.set(
								consumption.resource_type,
								-consumption.resource_count
							)
						
					else:
						found_all = false
						break
				
				if !consumption_list.any_of.is_empty():
					var found_any_of: bool = false
					for consumption: Builtin_Resource_Requirement in consumption_list.any_of:
						# TODO: could have consume at least as an option
						if faction.storage_node.has_at_least(
							consumption.resource_type,
							consumption.resource_count,
						):
							var result = faction.storage_node.take_at_least(
								consumption.resource_type,
								consumption.resource_count,
							)
							if !result.successful:
								printerr("!result.successful when taking food")
							else:
								found_any_of = true
								var changes: Dictionary[int, int]
								if changes_per_faction.has(c_faction.faction_id):
									changes = changes_per_faction.get(c_faction.faction_id)
								else:
									changes = {}
									changes_per_faction.set(c_faction.faction_id, changes)
								
								if changes.has(consumption.resource_type):
									changes[consumption.resource_type] -= consumption.resource_count
								else:
									changes.set(
										consumption.resource_type,
										-consumption.resource_count
									)
								break
					
					if !found_any_of:
						found_all = false
						
				if !found_all:
					#print("is_starving %s %s" % [
						#entity.name,
						#entity.get_path(),
					#])
					if !entity.has_component(C_IsStarving):
						cmd.add_component(
							entity,
							C_IsStarving.new()
						)
				else:
					c_consume_resources.time = 0
					if entity.has_component(C_IsStarving):
						cmd.remove_component(
							entity,
							C_IsStarving
						)
			_:
				printerr("unknown feed_system_option %s" % [
					feed_system_option,
				])
		
	if !changes_per_faction.is_empty():
		consumed_resources.emit(changes_per_faction)

func process_starving_entities(
	entities: Array[Entity],
	_components: Array,
	delta: float,
):
	#print("process_starving_entities %s" % [
		#entities.size(),
	#])
	var pop_units_died_per_faction: Dictionary[int, Dictionary] = {}
	var workers_died_per_faction: Dictionary[int, Dictionary] = {}
	var islands: Dictionary[Entity, int] = {}
	for entity: Entity in entities:
		var c_starving: C_IsStarving = entity.get_component(
			C_IsStarving
		)
		c_starving.starving_time += delta
		
		if c_starving.starving_time <= starving_death_time_limit:
			continue
		
		var c_pop_unit: C_PopUnit = entity.get_component(
			C_PopUnit
		)
		
		var r_works_at = entity.get_relationship(Rels.works_at)
		if r_works_at:
			var c_workers: C_Workers = r_works_at.target.get_component(
				C_Workers
			)
			var workers: WorkerQuantity = c_workers.workers.get(
				c_pop_unit.pop_type
			)
			var present_workers: WorkerQuantity = c_workers.present_workers.get(
				c_pop_unit.pop_type
			)
			workers.worker_count -= 1
			present_workers.worker_count -= 1
			
			var worker_r_faction = r_works_at.target.get_relationship(
				Rels.belongs_to_faction
			)
			var worker_faction: C_Faction = worker_r_faction.target.get_component(
				C_Faction
			)
			var changes_1: Dictionary[int, int]
			if workers_died_per_faction.has(worker_faction.faction_id):
				changes_1 = workers_died_per_faction.get(worker_faction.faction_id)
				if changes_1.has(c_pop_unit.pop_type):
					changes_1[c_pop_unit.pop_type] += 1
				else:
					changes_1.set(
						c_pop_unit.pop_type,
						1
					)
			else:
				changes_1 = {}
				workers_died_per_faction.set(
					worker_faction.faction_id,
					changes_1,
				)
				changes_1.set(
					c_pop_unit.pop_type,
					1
				)
				
			cmd.remove_relationship(
				entity,
				Rels.works_at
			)
		
		var r_lives_in = entity.get_relationship(Rels.lives_in)
		if r_lives_in:
			var c_housing: C_HousingCapacity = r_lives_in.target.get_component(
				C_HousingCapacity
			)
			c_housing.current -= 1
			
			cmd.remove_relationship(
				entity,
				Rels.lives_in
			)
			
			# TODO : emit event
		
		var r_travels_in = entity.get_relationship(Rels.travels_in)
		if r_travels_in:
			var c_ship_population: C_ShipPopulation = r_travels_in.target.get_component(
				C_ShipPopulation
			)
			c_ship_population.current -= 1
			
			cmd.remove_relationship(
				entity,
				Rels.travels_in
			)
			
			entity.global_position = r_travels_in.target.global_position
			
			# TODO: custom animation for sea?
		
		var r_island = entity.get_relationship(Rels.is_on_island)
		if r_island:
			var summary: C_PopulationSummary = r_island.target.get_component(
				C_PopulationSummary,
			)
			summary.population_decrease(
				c_pop_unit.pop_type,
				1,
			)
			summary.workers_decrease(
				c_pop_unit.pop_type,
				1,
			)
			
			if !islands.has(r_island.target):
				islands.set(r_island.target, 0)
		
		cmd.remove_component(
			entity,
			C_IsStarving
		)
		
		if !entity.visible:
			entity.show()
		
		entity.disable_physics()
		entity.play_death()
		
		cmd.add_component(
			entity,
			C_RemoveEntity.new(
				false,
				10
			)
		)
		cmd.add_component(
			entity,
			C_IsDead.new()
		)
		
		if entity.has_component(C_NavigationDestination):
			cmd.remove_component(
				entity,
				C_NavigationDestination,
			)
		
		var r_faction = entity.get_relationship(Rels.belongs_to_faction)
		var pop_unit_faction: C_Faction = r_faction.target.get_component(
			C_Faction
		)
		var changes: Dictionary[int, int]
		if pop_units_died_per_faction.has(pop_unit_faction.faction_id):
			changes = workers_died_per_faction.get(pop_unit_faction.faction_id)
			if changes.has(c_pop_unit.pop_type):
				changes[c_pop_unit.pop_type] += 1
			else:
				changes.set(
					c_pop_unit.pop_type,
					1
				)
		else:
			changes = {}
			pop_units_died_per_faction.set(
				pop_unit_faction.faction_id,
				changes,
			)
			changes.set(
				c_pop_unit.pop_type,
				1
			)
	
	if !pop_units_died_per_faction.is_empty():
		pop_units_died.emit(pop_units_died_per_faction)
	if !workers_died_per_faction.is_empty():
		workers_died.emit(workers_died_per_faction)
	if !islands.is_empty():
		island_population_changed.emit(islands)
	
