extends RichTextLabel

# FIXME: what is this, what does it do?

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = get_global_mouse_position() - Vector2(size.x / 2, size.y * 1.5)

func _on_visibility_changed():
	# to avoid teleport effect
	if visible:
		position = get_global_mouse_position() - Vector2(size.x / 2, size.y * 1.5)

	set_process(visible)
