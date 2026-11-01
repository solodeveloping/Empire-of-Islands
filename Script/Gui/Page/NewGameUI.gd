extends BookMenu
class_name NewGameUI

@onready var player_name: LineEditEx = $Pages/FreePlay/TextureRect/MarginContainer/VBoxContainer/HBoxContainer/LeftPage/VBoxContainer/PlayerName
@onready var map_list: ItemList = $Pages/FreePlay/TextureRect/MarginContainer/VBoxContainer/HBoxContainer/RightPage/MapList

# FIXME: comment

func _ready() -> void:
	super()
	
	print("NewGameUI:_ready %s" % [
		get_path(),
	])

	# Deactivate everything irrelevant for the time being
	var nodes = {
		"Scenario": null,
		"RandomMap": null,
		"ResourceDensitySlider": null,
		"Disasters": null,
	}

	find_nodes(get_tree().get_root(), nodes)
	nodes["Scenario"].disabled = true
	nodes["RandomMap"].disabled = true
	nodes["ResourceDensitySlider"].editable = false
	nodes["Disasters"].disabled = true

	if Engine.is_editor_hint():
		return

	player_name.text = Config.player_name

	# Just disable all tooltips.
	for item in map_list.item_count:
		map_list.set_item_tooltip_enabled(item, false)

func find_nodes(root_node: Node, nodes_to_be_found: Dictionary) -> void:
	for n in root_node.get_children():
		if n.get_child_count() > 0:
			find_nodes(n, nodes_to_be_found)

		if n.name in nodes_to_be_found:
			nodes_to_be_found[n.name] = n

#func _on_CancelButton_pressed() -> void:
	#super()

func _on_OKButton_pressed() -> void:
	print("_on_OKButton_pressed")
	if Global.map:
		queue_free()
		get_tree().change_scene_to_packed(Global.map)
	#else:
		#Audio.play_snd_fail()
