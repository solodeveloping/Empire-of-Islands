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

static func location_to_string(location_: LOCATION) -> String:
	match location_:
		LOCATION.NOWHERE:
			return "nowhere"
		LOCATION.IN_SHIP:
			return "in a ship"
		LOCATION.IDLE_ON_LAND:
			return "idle on land"
		LOCATION.MOVING_ON_LAND:
			return "moving on land"
		LOCATION.WORKPLACE:
			return "inside workplace"
		LOCATION.HOUSING:
			return "inside housing"
		LOCATION.DOCK:
			return "inside dock"
		_:
			printerr("location %s is not managed" % [
				location_
			])
			return "unknown"
