extends Node
class_name GMSimpleMarket

var prices: Dictionary = {}

var print_error_if_item_is_missing: bool = false

func set_sell_buy_price(
	item_id: int,
	buy_price: float,
	sell_price: float
):
	var ref = GMSellBuyRef.new()
	ref.item_id = item_id
	ref.buy_price = buy_price
	ref.sell_price = sell_price
	set_sell_buy_price_of_ref(
		ref
	)

func set_sell_buy_price_of_ref(
	ref: GMSellBuyRef
):
	prices.set(ref.item_id, ref)

func sell_to_market(item_id: int, quantity: int) -> GMSellResult:
	var result = GMSellResult.new()
	result.item_id = item_id
	var ref = prices.get(item_id) as GMSellBuyRef
	if ref == null:
		result.quantity_sold = 0
		result.total_money_made = 0
		if print_error_if_item_is_missing:
			printerr("could not find item %s" % item_id)
		return result
	result.quantity_sold = quantity
	result.total_money_made = quantity * ref.sell_price
	return result

func buy_from_market(item_id: int, quantity: int) -> GMBuyResult:
	var result = GMBuyResult.new()
	result.item_id = item_id
	var ref = prices.get(item_id) as GMSellBuyRef
	if ref == null:
		result.quantity_bought = 0
		result.total_money_spend = 0
		if print_error_if_item_is_missing:
			printerr("could not find item %s" % item_id)
		return result
	result.quantity_bought = quantity
	result.total_money_spend = quantity * ref.buy_price
	return result
