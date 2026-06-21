extends PanelContainer

@onready var rtl := $VBoxContainer/PanelContainer/RichTextLabel

var the_storage: TheStorage

var building_id = -1

func _ready() -> void:
	var current_node = get_tree().current_scene

	if current_node.has_node("TheStorage"):
		the_storage = current_node.get_node("TheStorage")
	else:
		printerr("TheStorage is not present")

func set_building_info(p_building_id: Buildings.Ids):
	rtl.clear()
	
	building_id = p_building_id
	
	var building_name = Buildings.get_building_name(building_id)
	var building_cost = Buildings.get_building_cost(building_id)
	for cost in building_cost:
		var quantity = the_storage.get_resource_amount(cost[0])
		# Info: check if has enough
		if quantity < cost[1]:
			cost.push_back(false)
		else:
			cost.push_back(true)
	
	_set_building_info(
		p_building_id,
		building_name,
		building_cost,
	)

func _set_building_info(
	p_building_id: int,
	building_name: String,
	building_cost: Array,
):
	rtl.clear()
	
	building_id = p_building_id

	if building_cost.is_empty() \
		and (p_building_id != Buildings.Ids.Warehouse and p_building_id != Buildings.Ids.MainSquare):
		push_warning("building of id '%d' cost is null" % building_id)
		return

	rtl.add_text("%s\n" % building_name)
	
	if !building_cost.is_empty():
		rtl.add_text("Cost :\n")

		for i in range(building_cost.size()):
			var cost = building_cost[i]

			if i > 0:
				rtl.add_text(" / ")
			
			if cost[2] == false:
				rtl.append_text("[color=red]" + \
					str(cost[1]) + "[/color] ")
			else:
				rtl.add_text(str(cost[1]) + " ")
			rtl.add_image(Resources.Icons[cost[0]], 20)

func set_money_production_rate_info(production_rate: int = 0):
	rtl.clear()
	rtl.append_text("[center]")
	rtl.add_image(TheBank.money_icon, 20)

	var text_sign = "+" if production_rate >= 0 else ""

	rtl.append_text("(" + text_sign + str(production_rate) + ")")
	pass
