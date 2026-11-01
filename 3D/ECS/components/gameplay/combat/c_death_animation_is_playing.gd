extends Component
class_name C_DeathAnimationIsPlaying

# TODO: convention the name
# related to [C_IsDoingAnimationAttack]

## This has to be initialized to the correct value
## The value is decremented
@export
var time: float = 0

func _init(
	time_: float = 0
) -> void:
	time = time_
