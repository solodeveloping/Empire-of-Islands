extends System
class_name LootSystem

signal loots_realized(
	loots: LootsPerFactionDef,
)

var check_in_range_time: float = 0
var check_in_range_time_limit: float = 0.1

func _ready() -> void:
	check_in_range_time = 0

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_LookingForLoot,
			])\
			.with_none([
				C_IsDead,
			])
			#.enabled()\
			.iterate([
				#C_LookingForLoot,
				C_CargoStorage
			])\
			,
			verify_loots
		],
		[
			ECS.world.query.with_all([
				C_ShipPopulation,
				C_LookingForPopUnits,
			])\
			.with_none([
				C_IsDead,
			])
			#.enabled()\
			.iterate([
				C_ShipPopulation
			])\
			,
			verify_pop_units
		],
	]

func verify_loots(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	check_in_range_time -= delta
	if check_in_range_time > 0:
		return
	check_in_range_time = check_in_range_time_limit
	
	print("verify_loots %s" % [
		entities.size(),
	])
	
	var C_CargoStorage_Index: int = 0
	
	var loots_per_faction: LootsPerFactionDef = LootsPerFactionDef.new()
	
	for i in entities.size():
		var entity: Entity = entities[i]
		
		if entity.has_loot_in_range == false:
			continue
		
		var loots: Array[Entity] = entity.loot_entities
		
		var c_storage: C_CargoStorage = components[C_CargoStorage_Index][i]
		
		var loot_change: LootChangeDef = null
		
		var r_faction = entity.get_relationship(
			Rels.belongs_to_faction
		)
		var c_faction: C_Faction = r_faction.target.get_component(
			C_Faction
		)

		#print("has loot in range %s" % [
			#loots.size(),
		#])
		
		for loot in loots:
			var c_loot_storage: C_CargoStorage = loot.get_component(
				C_CargoStorage,
			)
			if !c_loot_storage:
				printerr("loot does not has C_CargoStorage")
			else:
				var did_not_loot_all = false
				var looted_something = false
				var looted_gold = false
				
				if c_loot_storage.gold_count > 0:
					c_storage.gold_count += c_loot_storage.gold_count
					looted_something = true
					looted_gold = true
					
					# FIXME: duplicated
					if loot_change == null:
						loot_change = LootChangeDef.new()
						loot_change.global_position = loot.global_position
						if loots_per_faction.changes.has(c_faction.faction_id):
							var loot_of_faction: Array[LootChangeDef] = loots_per_faction.changes.get(
								c_faction.faction_id
							)
							loot_of_faction.push_back(loot_change)
						else:
							var loot_of_faction: Array[LootChangeDef] = [
								loot_change
							]
							loots_per_faction.changes.set(
								c_faction.faction_id,
								loot_of_faction,
							)
					
					loot_change.change_def.gold_change += c_loot_storage.gold_count
					
					c_loot_storage.gold_count = 0
				
				
				if c_loot_storage.storage.size() > 0:
					for key in c_loot_storage.storage.keys():
						var val: CargoResourceStorageDef = c_loot_storage.storage.get(key)
						# FIXME: what to do if not enough space?
						var storage_def: CargoResourceStorageDef = null
						
						for j in val.quantity:
							if val.space + val.space_per_quantity > c_storage.max_space:
								did_not_loot_all = true
								break
							if val.weight + val.weight_per_quantity > c_storage.max_weight:
								did_not_loot_all = true
								break
							
							if storage_def == null:
								if c_storage.storage.has(key):
									storage_def = c_storage.storage.get(key)
								else:
									storage_def = CargoResourceStorageDef.new()
									c_storage.storage.set(key, storage_def)
									storage_def.item_id = val.item_id
									storage_def.space_per_quantity = val.space_per_quantity
									storage_def.weight_per_quantity = val.weight_per_quantity
							
							# TODO: make a method for this
							storage_def.quantity += 1
							storage_def.space += storage_def.space_per_quantity
							storage_def.weight += storage_def.weight_per_quantity
							
							c_storage.space += storage_def.space_per_quantity
							c_storage.weight += storage_def.weight_per_quantity
							
							looted_something = true
							
							if loot_change == null:
								loot_change = LootChangeDef.new()
								loot_change.global_position = loot.global_position
								if loots_per_faction.changes.has(c_faction.faction_id):
									var loot_of_faction: Array[LootChangeDef] = loots_per_faction.changes.get(
										c_faction.faction_id
									)
									loot_of_faction.push_back(loot_change)
								else:
									var loot_of_faction: Array[LootChangeDef] = [
										loot_change
									]
									loots_per_faction.changes.set(
										c_faction.faction_id,
										loot_of_faction,
									)
							
							loot_change.change_def.add_resource(
								storage_def.item_id,
								1,
							)
							
				
				if looted_something == false:
					return
				
				#print("looting loot")
				loot.play_looted()
				if looted_gold:
					loot.play_gold_looted_sfx()
				else:
					loot.play_default_looted_sfx()
				
				if did_not_loot_all == false:
					loot.disable_physics()
					# TODO: loot should indicate this?
					cmd.add_component(
						loot,
						C_RemoveEntity.new(
							false,
							1
						)
					)
				
				cmd.remove_component(
					entity,
					C_LookingForLoot,
				)
				
		
	
	if !loots_per_faction.changes.is_empty():
		loots_realized.emit(
			loots_per_faction
		)
	

func verify_pop_units(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	check_in_range_time -= delta
	if check_in_range_time > 0:
		return
	check_in_range_time = check_in_range_time_limit
	
	print("verify_loots %s" % [
		entities.size(),
	])
	
	var C_ShipPopulation_Index: int = 0
	
	#var loots_per_faction: LootsPerFactionDef = LootsPerFactionDef.new()
	
	for i in entities.size():
		var entity: Entity = entities[i]
		
		if entity.has_loot_in_range == false:
			continue
		
		var loots: Array[Entity] = entity.loot_entities
		
		var c_ship_pop: C_ShipPopulation = components[C_ShipPopulation_Index][i]
		
		if c_ship_pop.is_full():
			continue
		
		if loots.is_empty():
			continue
		
		var picked_people_up: bool = false
		
		for loot in loots:
			if !loot.has_component(C_PopUnit):
				continue
			
			c_ship_pop.current += 1
			
			cmd.remove_component(
				loot,
				C_HasWaterEndurance,
			)
			cmd.add_relationship(
				loot,
				Rels.create_travels_in(entity)
			)
			
			loot.disable_physics()
			loot.hide()
			
			if c_ship_pop.is_full():
				break
		
		if picked_people_up == true:
			cmd.remove_component(
				entity,
				C_LookingForPopUnits
			)
		
