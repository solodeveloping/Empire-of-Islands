extends MarginContainer
class_name TradeExchangeSummaryFloatingUI

@onready var label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Label
@onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/TextureRect

func set_content(
	texture: Texture2D,
	text: String
):
	label.text = text
	texture_rect.texture = texture
