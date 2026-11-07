extends Node2D
class_name EntityStatic

@onready var sprite_2d: Sprite2D = $Sprite2D

var width := 0

var height := 0

var height_offset := 0

var width_offset := 0

func update_offset():
	if sprite_2d.texture == null:
		return
	if sprite_2d.centered:
		sprite_2d.centered = false
	var final_height = height
	if final_height % 2 == 0:
		final_height -= 1
	sprite_2d.offset = Vector2(0, -sprite_2d.texture.get_height()) + Vector2(-width * 32, final_height * 16)
