extends MarginContainer
class_name ResourceTradingItemUI

signal trade_changed(
	id: int,
	item: TradeResourceDefinition
)

@onready var sell_min_quantity_text_edit: LineEdit = $HBoxContainer/SellMinQuantityTextEdit
@onready var sell_min_price_text_edit: LineEdit = $HBoxContainer/SellMinPriceTextEdit
@onready var buy_max_quantity_text_edit: LineEdit = $HBoxContainer/BuyMaxQuantityTextEdit
@onready var buy_max_price_text_edit: LineEdit = $HBoxContainer/BuyMaxPriceTextEdit

@onready var resource_icon_texture_button: TextureButton = $HBoxContainer/ResourceIconTextureButton

@onready var warn_label: Label = $HBoxContainer/ResourceIconTextureButton/WarnLabel

var id: int = 0
var item: TradeResourceDefinition

var quantity_change: int = 1

func update_item(
	id_: int,
	item_: TradeResourceDefinition
):
	id = id_
	item = item_

	sell_min_quantity_text_edit.text = "%s" % [
		item.sell_min_quantity,
	]
	sell_min_price_text_edit.text = "%s" % [
		item.sell_min_price,
	]
	
	buy_max_quantity_text_edit.text = "%s" % [
		item.buy_max_quantity,
	]
	buy_max_price_text_edit.text = "%s" % [
		item.buy_max_price,
	]
	
	
	update_resource_icon()
	
	resource_icon_texture_button.tooltip_text = item.item_name
	
	assess_prices()

func assess_prices():
	if item.buy_max_price > 0 and item.sell_min_price > 0:
		if item.buy_max_price > item.sell_min_price:
			warn_label.show()
		else:
			warn_label.hide()
	else:
		warn_label.hide()

func update_resource_icon():
	# Info: can't use resource_icon_texture_button.disabled
	if item.enabled:
		resource_icon_texture_button.texture_normal = item.res_icon_normal
	else:
		resource_icon_texture_button.texture_normal = item.res_icon_disabled

func _on_SellMinQuantityTextEdit_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		item.sell_min_quantity = new_text.to_int()
	trade_changed.emit(
		id,
		item,
	)

func _on_SellMinQuantityButtons_UpTextureButton_button_up() -> void:
	item.sell_min_quantity += quantity_change
	sell_min_quantity_text_edit.text = "%s" % [
		item.sell_min_quantity,
	]
	trade_changed.emit(
		id,
		item,
	)

func _on_SellMinQuantityButtons_DownTextureButton_button_up() -> void:
	item.sell_min_quantity -= quantity_change
	sell_min_quantity_text_edit.text = "%s" % [
		item.sell_min_quantity,
	]
	trade_changed.emit(
		id,
		item,
	)



func _on_SellMinPriceTextEdit_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		item.sell_min_price = new_text.to_int()
	trade_changed.emit(
		id,
		item,
	)

func _on_SellMinPriceButtons_UpTextureButton_button_up() -> void:
	item.sell_min_price += quantity_change
	sell_min_price_text_edit.text = "%s" % [
		item.sell_min_price,
	]
	trade_changed.emit(
		id,
		item,
	)

func _on_SellMinPriceButtons_DownTextureButton_button_up() -> void:
	item.sell_min_price -= quantity_change
	sell_min_price_text_edit.text = "%s" % [
		item.sell_min_price,
	]
	trade_changed.emit(
		id,
		item,
	)



func _on_BuyMaxQuantityTextEdit_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		item.buy_max_quantity = new_text.to_int()
	trade_changed.emit(
		id,
		item,
	)

func _on_BuyMaxQuantityButtons_UpTextureButton_button_up() -> void:
	item.buy_max_quantity += quantity_change
	buy_max_quantity_text_edit.text = "%s" % [
		item.buy_max_quantity,
	]
	trade_changed.emit(
		id,
		item,
	)

func _on_BuyMaxQuantityButtons_DownTextureButton_button_up() -> void:
	item.buy_max_quantity -= quantity_change
	buy_max_quantity_text_edit.text = "%s" % [
		item.buy_max_quantity,
	]
	trade_changed.emit(
		id,
		item,
	)



func _on_BuyMaxPriceTextEdit_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		item.buy_max_price = new_text.to_int()
	trade_changed.emit(
		id,
		item,
	)

func _on_BuyMaxPriceButtons_UpTextureButton_button_up() -> void:
	item.buy_max_price += quantity_change
	buy_max_price_text_edit.text = "%s" % [
		item.buy_max_price,
	]
	trade_changed.emit(
		id,
		item,
	)

func _on_BuyMaxPriceButtons_DownTextureButton_button_up() -> void:
	item.buy_max_price -= quantity_change
	buy_max_price_text_edit.text = "%s" % [
		item.buy_max_price,
	]
	trade_changed.emit(
		id,
		item,
	)



func _on_ResourceIconTextureButton_button_up() -> void:
	print("_on_ResourceIconTextureButton_button_up")
	item.enabled = !item.enabled
	update_resource_icon()
	trade_changed.emit(
		id,
		item,
	)
