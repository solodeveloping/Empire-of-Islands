extends Component
class_name C_Attack

# FIXME: best class_name?

@export
var attack_range: float = 0

@export
var base_damage: float = 0

@export
var apply_attack_delay_time: float = 0

@export
var attack_animation_time: float = 0

@export
var attack_cooldown: float = 0

func _init(
	attack_range_: float = 0,
	base_damage_: float = 0,
	apply_attack_delay_time_: float = 0,
	attack_animation_time_: float = 0,
	attack_cooldown_: float = 0,
) -> void:
	attack_range = attack_range_
	base_damage = base_damage_
	apply_attack_delay_time = apply_attack_delay_time_
	attack_animation_time = attack_animation_time_
	attack_cooldown = attack_cooldown_
