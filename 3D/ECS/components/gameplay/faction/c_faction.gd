extends Component
class_name C_Faction

@export
var def: FactionDef = null

@export
var faction_id: int = 0

# FIXME: maybe we should use C_Storage
@export
var gold_count: int = 0

# FIXME: use custom_trade instead?

# FIXME: should it be here?
@export
var global_trades: Array[TradeResourceDefinition] = []

var global_trades_as_dict: Dictionary[int, TradeResourceDefinition] = {}

func _init(def_: FactionDef = null, faction_id_: int = 0) -> void:
	def = def_
	faction_id = faction_id_
	
func set_global_trades(
	global_trades_: Array[TradeResourceDefinition]
):
	global_trades = global_trades_
	global_trades_as_dict.clear()
	for trade in global_trades:
		global_trades_as_dict.set(
			trade.resource_id,
			trade
		)
