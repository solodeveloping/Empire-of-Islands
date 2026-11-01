extends Component
class_name C_IsDoingAnimationAttack

# If we init with damage: its the current damages
# otherwise, maybe we don't iterate over C_Attack
# Not sure what's best

@export
var animation_time: float = 0

@export
var apply_attack_time: float = 0

@export
var has_applied_attack: bool = false

func _init(
	animation_time_: float = 0,
	apply_attack_time_: float = 0,
) -> void:
	animation_time = animation_time_
	apply_attack_time = apply_attack_time_
