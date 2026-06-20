extends GM_I_StorageNode
class_name GMSimpleStorage

var storage: Dictionary[int, GMStorageRef] = {}

func get_storage(
	item_id: int,
) -> GMStorageRef:
	return storage.get(item_id, null)

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
	
	storage.set(ref.item_id, ref)
	
	result.stored_quantity = ref.quantity
	
	return result

func has_at_least(item_id: int, quantity: int) -> bool:
	if !storage.has(item_id):
		return false
		
	var storage_ref: GMStorageRef = storage.get(item_id)
	if !storage_ref:
		push_error("could not find storage when should have %s" % item_id)
		return false
	
	return storage_ref.quantity >= quantity

func take_at_least(item_id: int, quantity: int) -> GMTakeResult:
	var result := GMTakeResult.new()
	
	if !storage.has(item_id):
		result.successful = false
		return result
		
	var storage_ref: GMStorageRef = storage.get(item_id)
	if !storage_ref:
		push_error("could not find storage when should have %s" % item_id)
		result.successful = false
		return result
	
	if storage_ref.quantity < quantity:
		result.successful = false
		return result
		
	storage_ref.quantity -= quantity
	
	result.successful = true
	result.quantity_taken = quantity
	
	return result

func take_as_much_as_possible(item_id: int, quantity: int) -> GMTakeResult:
	var result := GMTakeResult.new()
	
	if !storage.has(item_id):
		result.successful = false
		return result
		
	var storage_ref: GMStorageRef = storage.get(item_id)
	if !storage_ref:
		push_error("could not find storage when should have %s" % item_id)
		result.successful = false
		return result
	
	if storage_ref.quantity <= 0:
		result.successful = false
		return result
	
	result.quantity_taken = storage_ref.quantity - quantity
	if result.quantity_taken < 0:
		result.quantity_taken = quantity + result.quantity_taken
	
	storage_ref.quantity -= result.quantity_taken
	
	result.successful = true
	
	return result

func take_all(item_id: int) -> GMTakeResult:
	var result := GMTakeResult.new()
	
	if !storage.has(item_id):
		result.successful = false
		return result
		
	var storage_ref: GMStorageRef = storage.get(item_id)
	if !storage_ref:
		push_error("could not find storage when should have %s" % item_id)
		result.successful = false
		return result
		
	if storage_ref.quantity <= 0:
		result.successful = false
		return result
		
	result.quantity_taken = storage_ref.quantity
	
	storage_ref.quantity = 0
	
	result.successful = true
	
	return result

func put_as_much_as_possible(item_id: int, quantity: int) -> GMPutResult:
	var result := GMPutResult.new()
	result.successful = true
	result.quantity_put = quantity
	result.item_id = item_id
	
	var storage_ref: GMStorageRef = storage.get(item_id)
	if !storage_ref:
		storage_ref = GMStorageRef.new()
		storage_ref.item_id = item_id
		storage_ref.quantity = quantity
		storage_ref.max_quantity = -1
		
		storage.set(item_id, storage_ref)
	else:
		storage_ref.quantity += quantity
	
	return result
