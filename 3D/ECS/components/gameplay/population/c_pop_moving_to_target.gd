extends Component
class_name C_PopMovingToTarget

enum MOVE_TARGET_TYPE {
	WORKPLACE,
	HOUSING,
	DOCK,
	IDLING,
}

@export
var move_target_type: MOVE_TARGET_TYPE = MOVE_TARGET_TYPE.WORKPLACE

func _init(
	move_target_type_: MOVE_TARGET_TYPE = MOVE_TARGET_TYPE.WORKPLACE,
):
	move_target_type = move_target_type_
