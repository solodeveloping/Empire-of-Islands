extends PanelContainer
class_name MarketUI

# TODO: find a way to actually hide consistently
# when clicking elsewhere

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
		var instance: ResourceTradingItemUI = RESOURCE_TRADING_ITEM_UI.instantiate()
		trade_list_container.add_child(instance)
		
		instance.update_item(
			id,
			item,
		)
		instance.trade_changed.connect(
			_on_resource_trade_changed
		)
		
		id += 1

# Info: we should not need to handle it because the system use it directly
# I think
func _on_resource_trade_changed(
	_id: int,
	_item: TradeResourceDefinition
):
	print("_on_resource_trade_changed")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		#and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
			var local_pos := make_canvas_position_local(event.position)
			if not Rect2(Vector2.ZERO, size).has_point(local_pos):
				#print("clicked outside")
				self.hide()
