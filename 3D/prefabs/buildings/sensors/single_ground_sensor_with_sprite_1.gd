extends Node3D

@onready var sprite_3d: Sprite3D = $Sprite3D

func hide_sprite():
	sprite_3d.hide()
	
func show_sprite():
	sprite_3d.show()
	
func change_sprite_modulate_color(color: Color):
	sprite_3d.modulate = color
