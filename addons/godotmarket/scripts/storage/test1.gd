extends Node
class_name MyToto

class toto:
	func set_storage(
		item_id: int,
		quantity: int,
		max_quantity: int
	) -> GMSetStorageResult:
		return null

	func set_storage_ref(ref: GMStorageRef) -> GMSetStorageResult:
		return null
		
	func take_at_least(item_id: int, quantity: int) -> GMTakeResult:
		return null

	func take_as_much_as_possible(item_id: int, quantity: int) -> GMTakeResult:
		return null

	func take_all(item_id: int) -> GMTakeResult:
		return null

	func put_as_much_as_possible(item_id: int, quantity: int) -> GMPutResult:
		return null

static func yo():
	var lo = toto.new()
	
	do(lo)

static func do(yo: GM_I_StorageNode):
	pass
