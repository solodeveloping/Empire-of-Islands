@tool
extends Control

var plugins: Array[String] = []
var first_init: bool = true
var notify: bool = true

func _on_visibility_changed() -> void:
	if ProjectSettings.get_setting("addons/One_Click_Plugin_Reloader/Output panel notifications"):
		notify = true
	else:
		notify = false
	if visible and not first_init:
		plugins.clear()
		var dir = DirAccess.open("res://addons")
		if dir:
			dir.list_dir_begin()
			var p_name = dir.get_next()
			while p_name != "":
				if p_name == "." or p_name == "..":
					p_name = dir.get_next()
					continue
				if dir.current_is_dir() and FileAccess.file_exists("res://addons/%s/plugin.cfg" % p_name):
					var is_enabled = EditorInterface.is_plugin_enabled(p_name) ##plugin_interface.is_plugin_enabled(name)
					if is_enabled and not p_name == "o_c_p_r":
						if notify:
							print("[O.C.P.R]: Reloading plugin: " + p_name)
						EditorInterface.set_plugin_enabled(p_name, false)
						plugins.append(p_name)
						EditorInterface.set_plugin_enabled(p_name, true)
				p_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("[O.C.P.R]: An error occurred when trying to access the path")
			
		if plugins.is_empty():
			print("[O.C.P.R]: There are no plugins that can be restarted")
		if notify:
			print("[O.C.P.R]: Returning to " + ProjectSettings.get_setting("addons/One_Click_Plugin_Reloader/Default Window") + " workspace")
		EditorInterface.set_main_screen_editor(ProjectSettings.get_setting("addons/One_Click_Plugin_Reloader/Default Window"))
	else:
		first_init = false
