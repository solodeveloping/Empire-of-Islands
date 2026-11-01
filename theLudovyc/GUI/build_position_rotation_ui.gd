extends PanelContainer
class_name BuildPositionRotationUI

@export
var enable_option_color: Color = Color.BLUE

@export
var disable_option_color: Color = Color.DARK_GRAY

@onready var object_snap_texture_button: TextureButton = $VBoxContainer/HBoxContainer/CenterContainer2/PanelContainer/MarginContainer/ObjectSnapTextureButton
@onready var rotation_h_slider: HSlider = $VBoxContainer/HBoxContainer/CenterContainer/RotationHSlider

var event_bus: EventBus

var is_snap_to_object_enabled: bool = true

var time: float = 0

var is_rotate_left_pressed = false
var is_rotate_right_pressed = false

var drag_time: float = 0
var is_slider_dragging: bool = false

func _ready() -> void:
	event_bus = get_tree().current_scene.get_node("EventBus")
	
	event_bus.send_show_build_position_rotation_ui.connect(
		_on_event_bus_send_show_build_position_rotation_ui
	)
	event_bus.send_hide_build_position_rotation_ui.connect(
		_on_event_bus_send_hide_build_position_rotation_ui
	)
	
	_handle_snap_to_object_state()

func _physics_process(delta: float) -> void:
	if is_rotate_left_pressed:
		time += delta
		if time >= 0.1:
			time = 0
			_rotate_left_by_unit()
	elif is_rotate_right_pressed:
		time += delta
		if time >= 0.1:
			time = 0
			_rotate_right_by_unit()
		
	if is_slider_dragging:
		drag_time += delta
		if drag_time >= 0.1:
			drag_time = 0
			_handle_slider_value_changed()

func _on_RotateLeftTextureButton_button_down() -> void:
	is_rotate_left_pressed = true
	_rotate_left_by_unit()

func _on_RotateLeftTextureButton_button_up() -> void:
	#rotation_h_slider.value -= 1
	is_rotate_left_pressed = false
	time = 0

func _rotate_left_by_unit():
	rotation_h_slider.value += 1
	event_bus.ask_rotate_building.emit(
		rotation_h_slider.value
	)
	rotation_h_slider.tooltip_text = "%s" % [
		rotation_h_slider.value
	]

func _on_RotateRightTextureButton_button_down() -> void:
	is_rotate_right_pressed = true
	_rotate_right_by_unit()

func _on_RotateRightTextureButton_button_up() -> void:
	is_rotate_right_pressed = false
	time = 0

func _rotate_right_by_unit():
	rotation_h_slider.value -= 1
	event_bus.ask_rotate_building.emit(
		rotation_h_slider.value
	)
	rotation_h_slider.tooltip_text = "%s" % [
		rotation_h_slider.value
	]

# Info: called every frame
# So, not using it
func _on_RotationHSlider_value_changed(_value: float) -> void:
	pass
	#_handle_slider_value_changed()

func _on_RotationHSlider_drag_started() -> void:
	is_slider_dragging = true
	drag_time = 0

func _on_RotationHSlider_drag_ended(value_changed: bool) -> void:
	is_slider_dragging = false
	drag_time = 0
	if value_changed:
		_handle_slider_value_changed()

func _handle_slider_value_changed():
	event_bus.ask_rotate_building.emit(
		rotation_h_slider.value
	)
	rotation_h_slider.tooltip_text = "%s" % [
		rotation_h_slider.value
	]

func _on_ObjectSnapTextureButton_button_up() -> void:
	is_snap_to_object_enabled = !is_snap_to_object_enabled
	if is_snap_to_object_enabled:
		event_bus.ask_enable_snap_to_objects.emit()
	else:
		event_bus.ask_disable_snap_to_objects.emit()
	_handle_snap_to_object_state()

func _handle_snap_to_object_state():
	if is_snap_to_object_enabled == true:
		object_snap_texture_button.modulate = enable_option_color
	else:
		object_snap_texture_button.modulate = disable_option_color

func _on_event_bus_send_show_build_position_rotation_ui():
	self.show()
	
func _on_event_bus_send_hide_build_position_rotation_ui():
	self.hide()
