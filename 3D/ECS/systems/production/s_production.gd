class_name ProductionSystem
extends System

# TODO: should the storage emit events?
signal produced_resources(changes_per_faction: Dictionary[int, FactionProductionChangeDef])

# FIXME: could implement a script here
# To provide access to the faction's storage
# We're storing it inside the Faction_ECS entity for now
@export var the_storage: Node

@export
var resource_growth_stages_array: BuiltinResourceGrowthStagesArray

var resource_growth_stages_dict: Dictionary[int, BuiltinResourceGrowthStages] = {}

func sub_systems():
	return [
		# FIXME: do we need both components
		[
			ECS.world.query.with_all([
				C_Production,
				C_CollectionBuilding
			])
			.enabled()
			.iterate([
				C_Production,
			]),
			produce_resources
		],
		# FIXME: would be faster to not mutualize?
		[
			ECS.world.query.with_all([
				C_Production,
				C_HasResources
			])
			.enabled()
			.iterate([
				C_Production,
			]),
			produce_resources
		],
		[
			ECS.world.query.with_all([
				C_SlotProduction,
				C_CollectionBuilding
			])
			.enabled()
			.iterate([
				C_SlotProduction,
			]),
			produce_resources_using_slots
		],
	]

# TODO: implement this
#func setup():
	#set_tick_rate(0.5)

# TODO : handle remove worker

# FIXME : different methods?
# don't need it

func produce_resources(
	entities: Array[Entity],
	components: Array,
	delta: float
):
	#print("produce_resources %s" % [
		#entities.size(),
	#])
	var C_Production_Index: int = 0
	
	var changes_per_faction: Dictionary[int, FactionProductionChangeDef] = {}
	
	for i in entities.size():
		var building: Entity = entities[i]
		var c_production: C_Production = components[C_Production_Index][i]
		
		var efficiency: float = 1
		# do avg of all efficiency
		if building.has_component(C_WorkerRequirement):
			var c_requirement: C_WorkerRequirement = building.get_component(C_WorkerRequirement)
			if !building.has_component(C_Workers):
				continue
			
			var total = 0
			var missing_workers = false
			var c_workers: C_Workers = building.get_component(C_Workers)
			for req in c_requirement.requirements.values():
				var workers = c_workers.present_workers[req.worker_type]
				# FIXME : use min_count
				if workers.worker_count < req.min_count:
					#print("missing workers %s %s %s" % [
						#building.name,
						#building.get_path(),
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
		var r_faction = building.get_relationship(Rels.belongs_to_faction)
		if !r_faction:
			printerr("building does not have belongs_to_faction %s %s" % [
				building.name,
				building.get_path(),
			])
			continue
		
		var faction_entity: Faction_ECS = r_faction.target
		var c_faction: C_Faction = r_faction.target.get_component(C_Faction)
		
		var put_result = faction_entity.storage_node.put_as_much_as_possible(
			c_production.production_type,
			c_production.production_per_cycle
		)
		c_production.time = c_production.production_time
		
		# Info: this is for production building transforming resources
		var c_has_resources = building.get_component(C_HasResources)
		if c_has_resources:
			cmd.remove_component(building, C_HasResources)
			cmd.add_component(building, C_AwaitingResources)
		
		if put_result.successful == false or put_result.quantity_put <= 0:
			continue
		
		var changes: FactionProductionChangeDef
		if changes_per_faction.has(c_faction.faction_id):
			changes = changes_per_faction.get(c_faction.faction_id)
		else:
			changes = FactionProductionChangeDef.new()
			changes_per_faction.set(c_faction.faction_id, changes)
		
		#print("successfully produced resources")
		if changes.changes_per_resource.has(put_result.item_id):
			changes.changes_per_resource[put_result.item_id] += put_result.quantity_put
		else:
			changes.changes_per_resource.set(
				put_result.item_id,
				put_result.quantity_put
			)
	
		var change: ProductionChangeDef = ProductionChangeDef.new()
		change.faction_id = c_faction.faction_id
		change.production_building = building
		change.resources_changes.set(
			put_result.item_id,
			put_result.quantity_put,
		)
		changes.list.push_back(change)
	
	if changes_per_faction.keys().size() > 0:
		produced_resources.emit(changes_per_faction)

func produce_resources_using_slots(
	entities: Array[Entity],
	components: Array,
	delta: float
):
	#print("produce_resources %s" % [
		#entities.size(),
	#])
	var C_SlotProduction_Index: int = 0
	
	var changes_per_faction: Dictionary[int, Dictionary] = {}
	for i in entities.size():
		var building: Entity = entities[i]
		var c_production: C_SlotProduction = components[C_SlotProduction_Index][i]
		
		# TODO?: using efficiency?
		var efficiency: float = 1
		# do avg of all efficiency
		if building.has_component(C_WorkerRequirement):
			var c_requirement: C_WorkerRequirement = building.get_component(C_WorkerRequirement)
			if !building.has_component(C_Workers):
				continue
			
			var total = 0
			var missing_workers = false
			var c_workers: C_Workers = building.get_component(C_Workers)
			for req in c_requirement.requirements.values():
				var workers = c_workers.present_workers[req.worker_type]
				# FIXME : use min_count
				if workers.worker_count < req.min_count:
					#print("missing workers %s %s %s" % [
						#building.name,
						#building.get_path(),
						#workers.worker_count,
					#])
					missing_workers = true
					break
					
				total += (workers.worker_count / req.worker_count)
		
			if missing_workers:
				continue
		
			efficiency = (total / c_requirement.requirements.size())
		
		for j in c_production.slots.size():
			var slot: SlotProduction = c_production.slots[j]
			
			#slot.time -= (delta * efficiency)
			slot.time -= delta
			
			var stages: BuiltinResourceGrowthStages = resource_growth_stages_dict.get(
				slot.resource_id,
			)
			var stage_count: int = stages.stages.size() + 1
			
			var progress: float = remap(
				slot.time,
				slot.production_time,
				0,
				0,
				stage_count,
			)
			var progress_index = floori(progress)
		
			building.update_slot_progress(
				j,
				progress_index,
				stages,
			)
			
			if slot.time > 0:
				#print("time", c_production.time)
				continue
			
			# TODO : handle too much prod
			# TODO : building you can collect from
			#print(
				#"increasing res",
				#c_production.production_type,
				#c_production.production_per_cycle
			#)
			var r_faction = building.get_relationship(Rels.belongs_to_faction)
			if !r_faction:
				printerr("building does not have belongs_to_faction %s %s" % [
					building.name,
					building.get_path(),
				])
				continue
			
			var faction_entity: Faction_ECS = r_faction.target
			var c_faction: C_Faction = r_faction.target.get_component(
				C_Faction
			)
			
			var put_result = faction_entity.storage_node.put_as_much_as_possible(
				c_production.production_type,
				c_production.production_per_cycle
			)
			
			# we reset the timer
			slot.time = slot.production_time
			
			# Info: this is for production building transforming resources
			var c_has_resources = building.get_component(C_HasResources)
			if c_has_resources:
				cmd.remove_component(building, C_HasResources)
				cmd.add_component(building, C_AwaitingResources)
			
			if put_result.successful == false or put_result.quantity_put <= 0:
				continue
			
			var changes: FactionProductionChangeDef
			if changes_per_faction.has(c_faction.faction_id):
				changes = changes_per_faction.get(c_faction.faction_id)
			else:
				changes = FactionProductionChangeDef.new()
				changes_per_faction.set(c_faction.faction_id, changes)
			
			#print("successfully produced resources")
			if changes.changes_per_resource.has(put_result.item_id):
				changes[put_result.item_id] += put_result.quantity_put
			else:
				changes.changes_per_resource.set(
					put_result.item_id,
					put_result.quantity_put
				)
		
			var change: ProductionChangeDef = ProductionChangeDef.new()
			change.faction_id = c_faction.faction_id
			change.production_building = building
			change.resources_changes.set(
				put_result.item_id,
				put_result.quantity_put,
			)
			changes.list.push_back(change)
				
	
	if changes_per_faction.keys().size() > 0:
		produced_resources.emit(changes_per_faction)

func set_resource_growth_stages_array(
	resource_growth_stages_array_: BuiltinResourceGrowthStagesArray
):
	resource_growth_stages_array = resource_growth_stages_array_
	for elem in resource_growth_stages_array.list:
		resource_growth_stages_dict.set(
			elem.builtin_resource_id,
			elem
		)
