extends Component
class_name C_PopUnitLocation

enum LOCATION {
	NOWHERE,
	IN_SHIP,
	IDLE_ON_LAND,
	MOVING_ON_LAND,
	WORKPLACE,
	HOUSING,
	DOCK,
}

@export
var location: LOCATION = LOCATION.NOWHERE

func _init(location_: LOCATION = LOCATION.NOWHERE) -> void:
	location = location_
