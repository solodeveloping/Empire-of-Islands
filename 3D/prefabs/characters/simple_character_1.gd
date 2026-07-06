@tool
extends Entity
class_name SimpleCharacter1

@onready var character_visual: SimpleCharacterVisual1 = $CharacterVisualContainer/CharacterVisual

# FIXME : could be done in ECS
# should it be done in ECS?
var update_time: float = 0.1
var computed_time: float = 0
var last_position: Vector3 = Vector3.ZERO

func define_components() -> Array:
	return [
		# TODO : option to have simple name or dual name
		#C_Name.new("John"),
		C_Health.new(100.0),
		C_Movement.new(5.0),
		C_Transform.new(),
		C_NavigationAgent3D.new("NavigationAgent3D"),
		#C_PopUnitLocation.new(),
	]

func on_ready():
	var c_trans = get_component(C_Transform) as C_Transform
	if not c_trans:
		push_error("transform component not found")
		return
	c_trans.transform = self.global_transform

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	computed_time += delta
	if computed_time >= update_time:
		computed_time = 0
		if last_position.distance_to(self.global_position) >= 0.1:
			character_visual.play_walk()
		else:
			character_visual.play_idle()
		
		last_position = self.global_position

func _print_all():
	_print_all_components()

func _print_all_components():
	print("")
	for key in components.keys():
		print("_print_all_components: %s %s %s %s %s" % [
			self.name,
			key,
			components.get(key).get_class(),
			components.get(key).get_script().get_path(),
			components.get(key),
		])
