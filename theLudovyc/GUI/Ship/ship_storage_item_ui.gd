extends MarginContainer
class_name ShipStorageItemUI

@onready var texture_rect: TextureRect = $TextureRect
@onready var quantity_label: Label = $QuantityLabel

func set_icon(texture: Texture2D):
	texture_rect.texture = texture

func set_quantity(quantity: int):
	quantity_label.text = "%s" % [
		quantity,
	]

func set_tooltip(text: String):
	texture_rect.tooltip_text = text
