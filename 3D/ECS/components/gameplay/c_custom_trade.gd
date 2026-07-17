extends Component
class_name C_CustomTrade

# FIXME: should it be here?
@export
var global_trades: Array[BuiltinDefaultResourceTradePrice] = []

var global_trades_as_dict: Dictionary[int, BuiltinDefaultResourceTradePrice] = {}

func set_global_trades(
	global_trades_: Array[BuiltinDefaultResourceTradePrice]
):
	global_trades = global_trades_
	global_trades_as_dict.clear()
	for trade in global_trades:
		global_trades_as_dict.set(
			trade.builtin_resource_id,
			trade
		)
