extends CenterContainer
class_name PlantBedRoundButtonUI

signal clicked_on(
	ui: PlantBedRoundButtonUI,
	resource_id: int
)

@export
var builtin_resource_id: Resources.Types = Resources.Types.Tomato

@export
var is_not_selected_modulate: Color

@onready var object_snap_texture_button: TextureButton = $PanelContainer/MarginContainer/ObjectSnapTextureButton

var is_selected: bool = false

func _ready() -> void:
	var icon = Resources.get_resource_icon(builtin_resource_id)
	object_snap_texture_button.texture_normal = icon

func update_selected(
	is_selected_: bool
):
	is_selected = is_selected_
	update_selected_display()

func update_selected_display():
	if !is_selected:
		self.modulate = is_not_selected_modulate
	else:
		self.modulate = Color.WHITE

func _on_ObjectSnapTextureButton_button_up() -> void:
	if is_selected:
		return
	
	is_selected = !is_selected
	update_selected_display()
	
	clicked_on.emit(
		self,
		builtin_resource_id
	)
