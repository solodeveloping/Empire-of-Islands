@tool
extends Node2D

# FIXME: ended up not using it

@export_tool_button("save")
var save_action = save

#@onready var sub_viewport: SubViewport = $CanvasLayer/SubViewportContainer/SubViewport
@onready var sub_viewport: SubViewport = $CanvasLayer/SubViewport

# This is what I used to generate the mask attempts

func save():
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await RenderingServer.frame_post_draw
	
	var image = sub_viewport.get_texture().get_image()
	var texture = ImageTexture.create_from_image(image)
	
	var filename = "user://mask_%s_2d.png" % [
		7,
	]
	image.save_png(filename)
	var global_path = ProjectSettings.globalize_path(
		filename
	)
	print("path %s" % [
		global_path,
	])
	print("minimap image saved")
