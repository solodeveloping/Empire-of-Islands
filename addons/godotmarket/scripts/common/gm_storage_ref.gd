extends RefCounted
class_name GMStorageRef

var item_id: int = 0
var quantity: int = 0
var max_quantity: int = -1

func _init(
	item_id_: int = 0,
	quantity_: int = 0,
	max_quantity_: int = -1
) -> void:
	item_id = item_id_
	quantity = quantity_
	max_quantity = max_quantity_
