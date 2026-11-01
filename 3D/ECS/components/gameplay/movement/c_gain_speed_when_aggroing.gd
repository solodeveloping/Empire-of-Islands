extends Component
class_name C_GainSpeedWhenAggroing

@export
var speed_gain: float = 5

func _init(
	speed_gain_: float = 5
) -> void:
	speed_gain = speed_gain_
