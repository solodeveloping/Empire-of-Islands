extends MarginContainer
class_name TradeExchangeSummaryFloatingUI

@onready var label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Label
@onready var texture_rect: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/TextureRect

func set_content(
	texture: Texture2D,
	text: String
):
	label.text = text
	texture_rect.texture = texture
