extends PanelContainer
class_name MarketUI

# TODO: find a way to actually hide consistently
# when clicking elsewher

const RESOURCE_TRADING_ITEM_UI = preload("uid://caesee1t2e4as")

@onready var trade_list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/TradeListContainer

var trade_list: Array[TradeResourceDefinition] = []

func update_trades(
	trade_list_: Array[TradeResourceDefinition]
):
	trade_list = trade_list_
	NodeUtils.remove_all_children(trade_list_container)
	
	var id: int = 0
	for item in trade_list:
		var instance: ResourceTradingItemUI =RESOURCE_TRADING_ITEM_UI.instantiate()
		trade_list_container.add_child(instance)
		
		instance.update_item(
			id,
			item,
		)
		instance.trade_changed.connect(
			_on_resource_trade_changed
		)
		
		id += 1

func _on_resource_trade_changed(
	id: int,
	item: TradeResourceDefinition
):
	pass
