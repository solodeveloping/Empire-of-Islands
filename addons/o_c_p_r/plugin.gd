@tool
extends EditorPlugin

var hidden_scene

func _enter_tree() -> void:
	ProjectSettings.set("addons/One_Click_Plugin_Reloader/Default Window", "Script")
	var property_info = {
		"name": "addons/One_Click_Plugin_Reloader/Default Window",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "2D,3D,Script"
	}
	ProjectSettings.add_property_info(property_info)
	ProjectSettings.set_setting("addons/One_Click_Plugin_Reloader/Output panel notifications", true)
	
	hidden_scene = preload("res://addons/o_c_p_r/scene.tscn").instantiate()
	get_editor_interface().get_editor_main_screen().add_child(hidden_scene)
	_make_visible(false)
	print("[O.C.P.R]: Plugin enabled")

func _has_main_screen():
	return true

func _make_visible(visible):
	if hidden_scene:
		hidden_scene.visible = visible

func _exit_tree() -> void:
	if hidden_scene:
		ProjectSettings.set_setting("addons/One_Click_Plugin_Reloader/Default Window", null)
		ProjectSettings.set_setting("addons/One_Click_Plugin_Reloader/Output panel notifications", null)
		print("[O.C.P.R]: Plugin disabled")
		hidden_scene.queue_free()

func _get_plugin_name():
	return "O.C.P.R."

func _get_plugin_icon():
	return preload("res://addons/o_c_p_r/icon.png")
