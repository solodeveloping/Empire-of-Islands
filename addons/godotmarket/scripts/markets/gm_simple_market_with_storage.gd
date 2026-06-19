extends Node
class_name GMSimpleMarketWithStorage

enum SetStorageExcessBehavior {
	DO_NOT_ADD,
	FILL_TO_MAX,
}

enum SellExcessBehavior {
	DO_NOT_BUY,
	FILL_TO_MAX,
}

enum BuyShortageBehavior {
	DO_NOT_SELL,
	SELL_TO_ZERO,
}

@export
var gm_simple_market: GMSimpleMarket

var storage: Dictionary[int, GMStorageRef] = {}

var current_quantity: int = 0
var global_max_quantity: int = -1
var enforce_global_max_quantity_when_setting_ref: bool = false
var set_storage_excess_behavior: SetStorageExcessBehavior = SetStorageExcessBehavior.DO_NOT_ADD

var sell_excess_behavior: SellExcessBehavior = SellExcessBehavior.FILL_TO_MAX
var buy_shortage_behavior: BuyShortageBehavior = BuyShortageBehavior.SELL_TO_ZERO

func set_storage(
	item_id: int,
	quantity: int,
	max_quantity: int
) -> GMSetStorageResult:
	var ref := GMStorageRef.new()
	ref.item_id = item_id
	ref.quantity = quantity
	ref.max_quantity = max_quantity
	return set_storage_ref(ref)

func set_storage_ref(ref: GMStorageRef) -> GMSetStorageResult:
	var result := GMSetStorageResult.new()
	result.item_id = ref.item_id
	if enforce_global_max_quantity_when_setting_ref and global_max_quantity != -1:
		var new_quantity = current_quantity + ref.quantity
		if new_quantity > global_max_quantity:
			match set_storage_excess_behavior:
				SetStorageExcessBehavior.DO_NOT_ADD:
					ref.quantity = 0
					
					storage.set(ref.item_id, ref)
					
					result.stored_quantity = 0
					
					return result
				SetStorageExcessBehavior.FILL_TO_MAX:
					var excess = new_quantity - global_max_quantity
					ref.quantity -= excess
					
					storage.set(ref.item_id, ref)
					
					result.stored_quantity = ref.quantity
					
					current_quantity += ref.quantity
					
					return result
				_:
					printerr("unknown SetStorageExcessBehavior %s" % set_storage_excess_behavior)
					result.stored_quantity = 0
					
					return result
	
	current_quantity += ref.quantity
	
	storage.set(ref.item_id, ref)

	result.stored_quantity = ref.quantity
	
	return result

func sell_to_market(item_id: int, quantity: int) -> GMSellResult:
	var result := GMSellResult.new()
	result.item_id = item_id
	
	var current_storage = storage.get(item_id) as GMStorageRef
	if !current_storage:
		var storage_ref := GMStorageRef.new()
		storage_ref.item_id = item_id
		storage_ref.max_quantity = -1
		
		storage.set(item_id, storage_ref)
		
		current_storage = storage_ref
	
	if global_max_quantity != -1:
		var new_quantity = current_quantity + quantity
		if new_quantity > global_max_quantity:
			match sell_excess_behavior:
				SellExcessBehavior.DO_NOT_BUY:
					result.quantity_sold = 0
					result.total_money_made = 0
					return result
				SellExcessBehavior.FILL_TO_MAX:
					var diff = new_quantity - global_max_quantity
					quantity -= diff
				_:
					printerr("unknown SellExcessBehavior %s" % sell_excess_behavior)
					result.quantity_sold = 0
					result.total_money_made = 0
					return result

	# Info: quantity will have been adjusted if > global_max_quantity
	if current_storage.max_quantity != -1:
		var new_quantity = current_storage.quantity + quantity
		if new_quantity > current_storage.max_quantity:
			match sell_excess_behavior:
				SellExcessBehavior.DO_NOT_BUY:
					result.quantity_sold = 0
					result.total_money_made = 0
					return result
				SellExcessBehavior.FILL_TO_MAX:
					var diff = new_quantity - current_storage.max_quantity
					quantity -= diff
					
					# We continue the operation below
				_:
					printerr("unknown SellExcessBehavior %s" % sell_excess_behavior)
					result.quantity_sold = 0
					result.total_money_made = 0
					return result
	
	# Info: quantity will have been adjusted if > current_storage.max_quantity
	result = gm_simple_market.sell_to_market(item_id, quantity)
	
	current_storage.quantity += result.quantity_sold
	
	return result

func buy_from_market(item_id: int, quantity: int) -> GMBuyResult:
	var result := GMBuyResult.new()
	result.item_id = item_id
	
	var current_storage = storage.get(item_id) as GMStorageRef
	if !current_storage:
		result.quantity_bought = 0
		result.total_money_spend = 0
		return result
		
	var new_quantity = current_storage.quantity - quantity
	if new_quantity < 0:
		match buy_shortage_behavior:
			BuyShortageBehavior.DO_NOT_SELL:
				result.quantity_bought = 0
				result.total_money_spend = 0
				return result
			BuyShortageBehavior.SELL_TO_ZERO:
				# new_quantity i< < 0 so we can add it
				quantity += new_quantity
				
				# We continue the operation below
			_:
				printerr("unknown BuyShortageBehavior %s" % sell_excess_behavior)
				result.quantity_sold = 0
				result.total_money_made = 0
				return result
	
	result = gm_simple_market.buy_from_market(item_id, quantity)
	
	current_storage.quantity -= result.quantity_bought
	
	return result
