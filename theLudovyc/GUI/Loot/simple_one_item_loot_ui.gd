extends MarginContainer
class_name SimpleOneItemLootUI

# TODO: not satisfied with the UI

@onready var resource_texture_rect: TextureRect = $Panel/MarginContainer/ResourceTextureRect
@onready var quantity_label: Label = $Panel/MarginContainer/ResourceTextureRect/QuantityLabel

func set_content(
	texture: Texture2D,
	text: String,
):
	resource_texture_rect.texture = texture
	quantity_label.text = text
