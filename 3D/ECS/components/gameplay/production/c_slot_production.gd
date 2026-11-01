extends Component
class_name C_SlotProduction

@export
var slot_count: int

@export
var slots: Array[SlotProduction] = []

func _init(
	production_time_: float = 0,
	slot_count_: int = 0,
	original_slot_resource_id_: int = 0,
	slots_: Array[SlotProduction] = [],
) -> void:
	slot_count = slot_count_
	slots = slots_
	
	if slots.is_empty():
		for i in slot_count_:
			slots.push_back(
				SlotProduction.new(
					production_time_,
					original_slot_resource_id_
				)
			)
	
	if slots.size() != slot_count_:
		push_error("%s slots.size() %s != slot_count_ %s" % [
			parent.get_path(),
			slots.size(),
			slot_count_,
		])
	
