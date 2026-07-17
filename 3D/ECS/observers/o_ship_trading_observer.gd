extends Observer
class_name O_ShipTradingObserver

signal exchange_realized(
	dock_changes: StorageChangeDef,
	ship_changes: StorageChangeDef,
	dock: Entity,
	ship: Entity,
)

var default_builtin_resources_space_weight_ref_def: BuiltinResourcesSpaceWeightRefList

var space_weight_red_def_dict: Dictionary[int, BuiltinResourceSpaceWeightRefDef] = {}

# TODO: implement trade routes ship unloading and stuff

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_all([C_Ship]).on_event(
				ECSEvents.SHIP_TRADING_REQUESTED
			),
			_on_ship_trading_requested
		],
		
	]
	
func _on_ship_trading_requested(
	_event: Variant,
	ship: Entity,
	data: Variant,
	#"buoy": buoy,
	#"dock": dock,
	#"island": island,
) -> void:
	print("_on_ship_trading_requested")
	# sell
	var dock_r_faction = data.dock.get_relationship(
		Rels.belongs_to_faction
	)
	var dock_c_faction: C_Faction = dock_r_faction.target.get_component(
		C_Faction
	)
	var ship_r_faction = ship.get_relationship(
		Rels.belongs_to_faction
	)
	var ship_c_faction : C_Faction = ship_r_faction.target.get_component(
		C_Faction
	)
	if ship_c_faction.faction_id == dock_c_faction.faction_id:
		# transfer resources
		# TODO: implement transfer
		printerr("transfer of resoures hasn't been implemented yet")
		return
	
	var dock_changes: StorageChangeDef = StorageChangeDef.new()
	dock_changes.faction_id = dock_c_faction.faction_id
	
	var ship_changes: StorageChangeDef = StorageChangeDef.new()
	ship_changes.faction_id = ship_c_faction.faction_id
	
	var ship_c_storage: C_CargoStorage = ship.get_component(
		C_CargoStorage
	)
	#var dock_faction_storage: C_Storage = dock_r_faction.target.get_component(
		#C_Storage
	#)
	var dock_faction_storage2 = dock_r_faction.target.storage_node
	
	
	# FIXME: should we go in a different method if this is present?
	var ship_c_custom_trade: C_CustomTrade = ship.get_component(
		C_CustomTrade
	)
	
	# sell
	for res_id in ship_c_storage.storage.keys():
		print("ship attempting to sell %s" % [
			res_id,
		])
		var ship_res_storage: CargoResourceStorageDef = ship_c_storage.storage.get(
			res_id
		)
		if ship_res_storage.quantity == 0:
			print("quantity is 0")
			continue
		
		var dock_trade_def: TradeResourceDefinition = dock_c_faction.global_trades_as_dict.get(
			res_id
		)
		if dock_trade_def == null:
			print("dock_trade_def is null")
			continue
		
		if dock_trade_def.enabled == false:
			print("dock is not buying %s" % [
				res_id,
			])
			continue
		
		# TODO : implement verson where dock has own storage
		#var dock_faction_storage_def: ResourceStorageDef = dock_faction_storage.get_storage_def_or_init(
			#res_id
		#)
		var dock_faction_storage_def = dock_faction_storage2.get_storage(
			res_id
		)
		if !dock_faction_storage_def:
			printerr("!dock_faction_storage_def")
			continue
		
		if dock_trade_def.buy_max_quantity > 0:
			if dock_faction_storage_def.quantity > dock_trade_def.buy_max_quantity:
				print("dock has too much of the resource")
				continue
		
		if ship_c_custom_trade:
			print("using ship_c_custom_trade")
			var ship_trade: BuiltinDefaultResourceTradePrice = ship_c_custom_trade.global_trades_as_dict.get(
				res_id
			)
			if !ship_trade:
				print("!ship_trade")
				continue
			
			if ship_trade.initial_sell_price > dock_trade_def.buy_max_price:
				print("initial_sell_price %s > buy_max_price %s" % [
					ship_trade.initial_sell_price,
					dock_trade_def.buy_max_price,
				])
				continue
			
			# TODO: could optimize by doing some arithmetic
			
			var space_weight_def: BuiltinResourceSpaceWeightRefDef = space_weight_red_def_dict.get(
				res_id
			)
			
			print("dock is buying %s %s" % [
				dock_c_faction.gold_count,
				ship_res_storage.quantity,
			])
			
			# FIXME: if we have the min sell price 
			# then we can early return
			# Info: buy as much as possible
			var i = 0
			while dock_c_faction.gold_count > 0 and ship_res_storage.quantity > 0:
				if dock_trade_def.buy_max_quantity > 0:
					if dock_faction_storage_def.quantity > dock_trade_def.buy_max_quantity:
						print("dock has too much of the resource")
						break
				
				# TODO: could mimic intelligence by reach buy price
				
				print("dock is buying the resource at %s" % [
					ship_trade.initial_sell_price,
				])
				
				dock_c_faction.gold_count -= ship_trade.initial_sell_price
				ship_c_storage.gold_count += ship_trade.initial_sell_price
				
				ship_res_storage.quantity -= 1
				dock_faction_storage_def.quantity += 1
				
				# update the ship cargo weight and space
				ship_res_storage.space -= space_weight_def.space_per_quantity
				ship_res_storage.weight -= space_weight_def.weight_per_quantity
				
				ship_c_storage.space -= space_weight_def.space_per_quantity
				ship_c_storage.weight -= space_weight_def.weight_per_quantity
				
				dock_changes.gold_change -= ship_trade.initial_buy_price
				dock_changes.add_resource(
					res_id,
					1
				)
				ship_changes.gold_change += ship_trade.initial_buy_price
				ship_changes.remove_resource(
					res_id,
					-1
				)
				
				# TODO: summary
				# changes
				
				i += 1
				# TODO: custom limit
				if i > 1000:
					printerr("i > 1000")
					break
				
		else:
			var ship_trade_def: TradeResourceDefinition = ship_c_faction.global_trades_as_dict.get(
				res_id
			)
			
			if ship_trade_def.sell_min_price > dock_trade_def.buy_max_price:
				print("sell_min_price %s > buy_max_price %s" % [
					ship_trade_def.sell_min_price,
					dock_trade_def.buy_max_price,
				])
				continue
			
			# TODO: implement ship_trade_def sell_min_quantity
			#if ship_trade_def.
			
			var space_weight_def: BuiltinResourceSpaceWeightRefDef = space_weight_red_def_dict.get(
				res_id
			)
			
			print("dock is buying %s %s" % [
				dock_c_faction.gold_count,
				ship_res_storage.quantity,
			])
			
			var i = 0
			while dock_c_faction.gold_count > 0 and ship_res_storage.quantity > 0:
				if dock_trade_def.buy_max_quantity > 0:
					if dock_faction_storage_def.quantity > dock_trade_def.buy_max_quantity:
						print("ship has too much of the resource")
						break
				
				# TODO: could mimic intelligence by reach buy price
				
				print("dock is buying the resource at %s" % [
					ship_trade_def.sell_min_price,
				])
				
				dock_c_faction.gold_count -= ship_trade_def.sell_min_price
				ship_c_storage.gold_count += ship_trade_def.sell_min_price
				
				ship_res_storage.quantity -= 1
				dock_faction_storage_def.quantity += 1
				
				# update the ship cargo weight and space
				ship_res_storage.space -= space_weight_def.space_per_quantity
				ship_res_storage.weight -= space_weight_def.weight_per_quantity
				
				ship_c_storage.space -= space_weight_def.space_per_quantity
				ship_c_storage.weight -= space_weight_def.weight_per_quantity
				
				dock_changes.gold_change -= ship_trade_def.sell_min_price
				dock_changes.add_resource(
					res_id,
					1
				)
				ship_changes.gold_change += ship_trade_def.sell_min_price
				ship_changes.remove_resource(
					res_id,
					-1
				)
				
				i += 1
				# TODO: custom limit
				if i > 1000:
					printerr("i > 1000")
					break
	
	# buy
	for res_id in dock_faction_storage2.storage.keys():
		print("dock attempting to sell %s" % [
			res_id,
		])
		var dock_trade_def: TradeResourceDefinition = dock_c_faction.global_trades_as_dict.get(
			res_id
		)
		if !dock_trade_def.enabled:
			print("!dock_trade_def.enabled")
			continue
			
		if dock_trade_def.sell_min_price <= 0:
			print("dock_trade_def.sell_min_price <= 0")
			continue
		
		#var dock_faction_storage_def: ResourceStorageDef = dock_faction_storage.get_storage_def_or_init(
			#res_id
		#)
		var dock_faction_storage_def = dock_faction_storage2.get_storage(
			res_id
		)
		
		if dock_faction_storage_def.quantity <= 0:
			continue
		
		# FIXME: would be nice if we could encapsulate this
		# It's 2 classes for now though
		if dock_trade_def.sell_min_quantity > 0:
			if dock_faction_storage_def.quantity < dock_trade_def.sell_min_quantity:
				continue
		
		
		# can be null
		var ship_res_storage: CargoResourceStorageDef = ship_c_storage.storage.get(
			res_id
		)
		
		if ship_c_custom_trade:
			var ship_trade: BuiltinDefaultResourceTradePrice = ship_c_custom_trade.global_trades_as_dict.get(
				res_id
			)
			if !ship_trade:
				print("!ship_trade")
				continue
			
			if ship_trade.initial_sell_price > dock_trade_def.buy_max_price:
				continue
			
			# TODO: could optimize by doing some arithmetic
			
			var space_weight_def: BuiltinResourceSpaceWeightRefDef = space_weight_red_def_dict.get(
				res_id
			)
			
			# FIXME: if we have the min sell price 
			# then we can early return
			# Info: buy as much as possible
			var i = 0
			while ship_c_storage.gold_count > 0 and dock_faction_storage_def.quantity > 0:
				if dock_trade_def.sell_min_quantity > 0:
					if dock_faction_storage_def.quantity <= dock_trade_def.sell_min_quantity:
						break
				
				# TODO: could mimic intelligence by reach buy price
				print("dock selling resource to ship")
				
				# check cargo space and weight
				if ship_res_storage.space + space_weight_def.space_per_quantity > \
					ship_c_storage.max_space:
						break
				
				if ship_res_storage.weight + space_weight_def.weight_per_quantity > \
					ship_c_storage.max_weight:
						break
				
				if ship_res_storage == null:
					ship_res_storage = CargoResourceStorageDef.new()
					ship_res_storage.quantity += 1
					ship_c_storage.storage.set(
						res_id,
						ship_res_storage,
					)
					
				dock_faction_storage_def.quantity -= 1
				ship_res_storage.quantity += 1
				
				# exchange gold
				dock_c_faction.gold_count += ship_trade.initial_buy_price
				ship_c_storage.gold_count -= ship_trade.initial_buy_price
				
				# update the ship cargo weight and space
				ship_res_storage.space += space_weight_def.space_per_quantity
				ship_res_storage.weight += space_weight_def.weight_per_quantity
				
				ship_c_storage.space += space_weight_def.space_per_quantity
				ship_c_storage.weight += space_weight_def.weight_per_quantity
				
				dock_changes.gold_change += ship_trade.initial_buy_price
				dock_changes.remove_resource(
					res_id,
					-1
				)
				ship_changes.gold_change -= ship_trade.initial_buy_price
				ship_changes.add_resource(
					res_id,
					1
				)
				
				i += 1
				# TODO: custom limit
				if i > 1000:
					printerr("i > 1000")
					break
				
		else:
			var ship_trade_def: TradeResourceDefinition = ship_c_faction.global_trades_as_dict.get(
				res_id
			)
			if ship_trade_def.sell_min_price > dock_trade_def.buy_max_price:
				continue
			
			# TODO: implement ship_trade_def sell_min_quantity
			#if ship_trade_def.
			
			var space_weight_def: BuiltinResourceSpaceWeightRefDef = space_weight_red_def_dict.get(
				res_id
			)
			
			var i = 0
			while dock_c_faction.gold_count > 0 and ship_res_storage.quantity > 0:
				if dock_trade_def.buy_max_quantity > 0:
					if dock_faction_storage_def.quantity > dock_trade_def.buy_max_quantity:
						break
				
				# TODO: could mimic intelligence by reach buy price
				print("dock selling resource to ship")
				
				# check cargo space and weight
				if ship_res_storage.space + space_weight_def.space_per_quantity > \
					ship_c_storage.max_space:
						break
				
				if ship_res_storage.weight + space_weight_def.weight_per_quantity > \
					ship_c_storage.max_weight:
						break
				
				if ship_res_storage == null:
					ship_res_storage = CargoResourceStorageDef.new()
					ship_res_storage.quantity += 1
					ship_c_storage.storage.set(
						res_id,
						ship_res_storage,
					)
				
				dock_faction_storage_def.quantity -= 1
				ship_res_storage.quantity += 1
				
				# exchange gold
				dock_c_faction.gold_count += ship_trade_def.buy_max_price
				ship_c_storage.gold_count -= ship_trade_def.buy_max_price
				
				# update the ship cargo weight and space
				ship_res_storage.space += space_weight_def.space_per_quantity
				ship_res_storage.weight += space_weight_def.weight_per_quantity
				
				ship_c_storage.space += space_weight_def.space_per_quantity
				ship_c_storage.weight += space_weight_def.weight_per_quantity
				
				dock_changes.gold_change += ship_trade_def.buy_max_price
				dock_changes.remove_resource(
					res_id,
					-1
				)
				ship_changes.gold_change -= ship_trade_def.buy_max_price
				ship_changes.add_resource(
					res_id,
					1
				)
				
				i += 1
				# TODO: custom limit
				if i > 1000:
					printerr("i > 1000")
					break

	if dock_changes.gold_change != 0 or ship_changes.gold_change != 0 \
		or !dock_changes.resources_changes.is_empty() \
		or !ship_changes.resources_changes.is_empty():
			exchange_realized.emit(
				dock_changes,
				ship_changes,
				data.dock,
				ship,
			)

func set_default_builtin_resources_space_weight_ref_def(
	default_builtin_resources_space_weight_ref_def_: BuiltinResourcesSpaceWeightRefList
):
	default_builtin_resources_space_weight_ref_def = default_builtin_resources_space_weight_ref_def_
	space_weight_red_def_dict.clear()
	for space_weight_ref in default_builtin_resources_space_weight_ref_def.list:
		space_weight_red_def_dict.set(
			space_weight_ref.res_id,
			space_weight_ref
		)
