extends Control

const _002 = preload("uid://3mmetdaeiip0")

# FIXME: is it still used?

@onready var simple_one_item_loot_ui: SimpleOneItemLootUI = $SimpleOneItemLootUi

var event_bus: EventBus

var current_entity: Entity

func _ready() -> void:
	var current_scene = get_tree().current_scene
	if current_scene.has_node("EventBus"):
		event_bus = current_scene.get_node("EventBus")
		
		event_bus.send_mouse_over_loot_updated.connect(
			_on_event_bus_send_mouse_over_loot_updated
		)
		event_bus.send_mouse_not_over_loot_updated.connect(
			_on_event_bus_send_mouse_not_over_loot_updated
		)
	
	simple_one_item_loot_ui.hide()
	

func _on_event_bus_send_mouse_not_over_loot_updated(
):
	print("_on_event_bus_send_mouse_not_over_loot_updated")
	current_entity = null
	simple_one_item_loot_ui.hide()

func _on_event_bus_send_mouse_over_loot_updated(
	entity: Entity,
):
	print("_on_event_bus_send_mouse_over_loot_updated")
	var cam = get_viewport().get_camera_3d()
	
	#var is_behind = cam.is_position_behind(
		#entity.global_position
	#)
	var for_ui_offset: Vector3 = Vector3(
		0,
		0,
		0,
	)
	
	var for_ui_target_pos: Vector3 = entity.global_position + for_ui_offset
	
	var ui_pos: Vector2 =  cam.unproject_position(
		for_ui_target_pos
	)
	simple_one_item_loot_ui.position = ui_pos
	
	var c_cargo_storage: C_CargoStorage = entity.get_component(
		C_CargoStorage
	)
	if !c_cargo_storage:
		printerr("C_CargoStorage not present in loot")
		return
	
	var texture: Texture2D
	var text: String = "0"
	if c_cargo_storage.gold_count > 0:
		texture = Resources.get_resource_icon(
			Resources.Types.Gold,
		)
		text = str(c_cargo_storage.gold_count)
	elif c_cargo_storage.storage.size() > 0:
		var item: CargoResourceStorageDef = c_cargo_storage.storage.values()[0]
		texture = Resources.get_resource_icon(
			item.item_id,
		)
		text = str(item.quantity)
	else:
		printerr("loot c_cargo_storage is empty")
		texture = _002
	
	if texture == null:
		printerr("_on_event_bus_send_mouse_over_loot_updated texture is null")
	
	simple_one_item_loot_ui.set_content(
		texture,
		text
	)
	
	print("show loot ui %s" % [
		simple_one_item_loot_ui.position,
	])
	simple_one_item_loot_ui.show()
