extends Component
class_name C_AttackInCoolDown

## this one is substracted
## so it need to be initialized with the attack cooldown time
@export
var time: float = 0

# TODO: open issue for this type of things?
func _init(
	time_: float = 0,
) -> void:
	time = time_
