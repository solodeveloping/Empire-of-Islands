class_name C_Storage
extends Component

# TODO: make this an option
# could be a resource
@export
var gold_count: int = 0

@export
var storage: Dictionary[int, ResourceStorageDef] = {}

func _init(
	gold_count_: int = 0
) -> void:
	gold_count = gold_count_
	
func get_storage_def_or_init(res_id: int) -> ResourceStorageDef:
	var def = storage.get(res_id)
	if def:
		return def
	def = ResourceStorageDef.new()
	def.item_id = res_id
	storage.set(res_id, def)
	return def
