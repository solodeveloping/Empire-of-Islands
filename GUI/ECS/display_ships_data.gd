## This is the class that displays the ship's data above them
extends Control
class_name DisplayShipsData

# TODO: update the data

const SIMPLE_SHIP_FLOATING_UI_1 = preload("uid://sx5ahboa8iuh")
const SHIP_FLOATING_UI_1 = preload("uid://c3qw45jy0uvau")

var event_bus: EventBus

var is_3D = true
var ships: Array[Entity]
var ships_dict: Dictionary[int, Entity] = {}

var simple_uis: Dictionary[int, SimpleShipFloatingUI_1] = {}
var uis: Dictionary[int, ShipFloatingUI_1] = {}

# TODO: handle faction != local faction

func _ready() -> void:
	print("DisplayShipsData:_ready")
	var current_scene = get_tree().current_scene
	if current_scene.has_node("EventBus"):
		print("TestDisplayShipsData: has EventBus")
		event_bus = current_scene.get_node("EventBus")
		
		event_bus.send_all_ecs_ships_updated.connect(
			_on_event_bus_send_all_ecs_ships_updated
		)
		event_bus.send_ecs_ship_appeared.connect(
			_on_event_bus_send_ecs_ship_appeared
		)
		# 2 of them because we want to hide he UI when the ship is destroyed
		event_bus.send_ecs_ship_destroyed.connect(
			_on_event_bus_send_ecs_ship_destroyed
		)
		event_bus.send_ecs_ship_disappeared.connect(
			_on_event_bus_send_ecs_ship_destroyed
		)
		
	var scene_root = get_tree().current_scene
	is_3D = (scene_root is Node3D)
	
	NodeUtils.remove_all_children(self)


# TODO: settings
# far away
# top down
# nearby top down

func _process(_delta: float) -> void:
	if !ships or ships.is_empty():
		#print("no ships")
		return
	
	if is_3D:
		process_3D()
	else:
		process_2D()
	
func process_3D():
	# TODO: could store it and update it only if it changes
	var cam = get_viewport().get_camera_3d()
	
	# WARN: can't do this
	#var to_remove_ships: Array[Entity] = []
	
	for ship: Entity in ships:
		
		if is_instance_valid(ship) == false:
			push_error("ship is not valid(3D): !is_instance_valid(ship)")
			# WARN: can't do this
			#to_remove_ships.push_back(ship)
			#simple_uis.erase(ship.ecs_id)
			#uis.erase(ship.ecs_id)
			continue
		
		var is_behind = cam.is_position_behind(
			ship.global_position
		)
		
		#cam.is_position_in_frustum()
		
		var simple_ui: SimpleShipFloatingUI_1 = simple_uis.get(
			ship.ecs_id,
		)
		#simple_ui.visible = !is_behind
		simple_ui.visible = false
		
		var ui: ShipFloatingUI_1 = uis.get(
			ship.ecs_id,
		)
		ui.visible = !is_behind
		
		if is_behind:
			#print("ship is_behind %s" % [
				#ship.get_path(),
			#])
			continue
		
		var ship_to_cam_dist = cam.global_position.distance_to(
			ship.global_position
		)
		ship_to_cam_dist = clampf(ship_to_cam_dist, 0, 250)
		# FIXME: angles also influence it
		var ui_y_offset = remap(
			ship_to_cam_dist,
			0,
			250,
			5,
			30,
		)
		var simple_ui_y_offset = remap(
			ship_to_cam_dist,
			0,
			250,
			5,
			9,
		)
		var ui_offset: Vector3 = Vector3(
			0,
			ui_y_offset,
			0,
		)
		var simple_ui_offset: Vector3 = Vector3(
			0,
			simple_ui_y_offset,
			0,
		)
		
		var simple_ui_target_pos: Vector3 = ship.global_position + simple_ui_offset
		var ui_target_pos: Vector3 = ship.global_position + ui_offset
		
		var ui_pos: Vector2 =  cam.unproject_position(
			ui_target_pos
		)
		var simple_ui_pos: Vector2 = cam.unproject_position(
			simple_ui_target_pos
		)
		
		#print("ship position %s %s %s %s %s" % [
			#ship.get_path(),
			#ship.ecs_id,
			#ship.global_position,
			#ui_pos,
			#is_behind,
		#])
		
		simple_ui.set_content(
			ship,
			StaticFactions.local_player_faction_id,
		)
		ui.set_content(
			ship,
			StaticFactions.local_player_faction_id,
		)
		
		#var size_ = ui.size
		
		simple_ui.position = simple_ui_pos# + Vector2(size_.x / 2, size_.y / 2)
		ui.position = ui_pos# + Vector2(size_.x / 2, size_.y / 2)
		
		if ship.has_meta("is_visible"):
			var _is_visible = ship.get_meta("is_visible")
			if !_is_visible:
				ui.visible = false
	
	#for ship in to_remove_ships:
		#ships.erase(ship)

func process_2D():
	#var cam: Camera2D = get_viewport().get_camera_2d()
	
	for ship: Entity in ships:
		
		if is_instance_valid(ship) == false:
			printerr("ship is not valid (2D): !is_instance_valid(ship)")
			# WARN: can't do this
			#to_remove_ships.push_back(ship)
			#simple_uis.erase(ship.ecs_id)
			#uis.erase(ship.ecs_id)
			continue
		
		#print("iterating")
		
		var screen_pos: Vector2 = get_viewport()\
			.get_canvas_transform() * ship.global_position
		var visible_: bool = get_viewport()\
			.get_visible_rect().has_point(screen_pos)
		
		#cam.is_position_in_frustum()
		
		var simple_ui: SimpleShipFloatingUI_1 = simple_uis.get(
			ship.ecs_id,
		)
		#simple_ui.visible = !is_behind
		simple_ui.visible = false
		
		var ui: ShipFloatingUI_1 = uis.get(
			ship.ecs_id,
		)
		ui.visible = visible_
		
		if !visible_:
			#print("ship is_behind %s" % [
				#ship.get_path(),
			#])
			continue
		
		#var ship_to_cam_dist = cam.global_position.distance_to(
			#ship.global_position
		#)
		var ship_to_cam_dist = -150.0
		#ship_to_cam_dist = clampf(ship_to_cam_dist, 0, 250)
		# FIXME: angles also influence it
		#var ui_y_offset = remap(
			#ship_to_cam_dist,
			#0,
			#250,
			#5,
			#30,
		#)
		#var simple_ui_y_offset = remap(
			#ship_to_cam_dist,
			#0,
			#250,
			#5,
			#9,
		#)
		var ui_offset: Vector2 = Vector2(
			0,
			ship_to_cam_dist,
			#ui_y_offset,
		)
		var simple_ui_offset: Vector2 = Vector2(
			0,
			ship_to_cam_dist,
			#simple_ui_y_offset,
		)
		
		var simple_ui_target_pos: Vector2 = ship.global_position + simple_ui_offset
		var ui_target_pos: Vector2 = ship.global_position + ui_offset
		
		var ui_pos: Vector2 =  get_viewport().get_canvas_transform() * ui_target_pos
		var simple_ui_pos: Vector2 = get_viewport().get_canvas_transform() * simple_ui_target_pos
		
		#print("ship position %s %s %s %s %s %s" % [
			#ship.get_path(),
			#ship.ecs_id,
			#ship.global_position,
			#ui_pos,
			#ui_target_pos,
			#get_viewport().get_canvas_transform(),
		#])
		
		simple_ui.set_content(
			ship,
			StaticFactions.local_player_faction_id,
		)
		ui.set_content(
			ship,
			StaticFactions.local_player_faction_id,
		)
		
		#var size_ = ui.size
		
		simple_ui.position = simple_ui_pos# + Vector2(size_.x / 2, size_.y / 2)
		ui.position = ui_pos# + Vector2(size_.x / 2, size_.y / 2)
		
		if ship.has_meta("is_visible"):
			var _is_visible = ship.get_meta("is_visible")
			if !_is_visible:
				print("not visible")
				ui.visible = false
		else:
			push_error("does not have meta is_visible")
	
	#for ship in to_remove_ships:
		#ships.erase(ship)

func _on_event_bus_send_all_ecs_ships_updated(
	ships_: Array[Entity],
):
	print("_on_event_bus_send_all_ecs_ships_updated %s" % [
		ships_.size(),
	])
	if !ships.is_empty():
		for ship in ships:
			remove_ship_uis(ship)
	
	ships = ships_.duplicate()
	ships_dict = {}
	
	for ship in ships:
		ships_dict.set(
			ship.ecs_id,
			ship,
		)
		var simple_ui: SimpleShipFloatingUI_1 = SIMPLE_SHIP_FLOATING_UI_1.instantiate()
		simple_ui.hide()
		add_child(simple_ui)
		
		simple_ui.set_content(
			ship,
			StaticFactions.local_player_faction_id
		)
		simple_uis.set(
			ship.ecs_id,
			simple_ui,
		)
		
		var ui: ShipFloatingUI_1 = SHIP_FLOATING_UI_1.instantiate()
		ui.hide()
		add_child(ui)
		
		ui.set_content(
			ship,
			StaticFactions.local_player_faction_id
		)
		uis.set(
			ship.ecs_id,
			ui,
		)

	print("_on_event_bus_send_all_ecs_ships_updated:end %s %s %s %s %s" % [
		ships.size(),
		ships_dict.size(),
		uis.size(),
		simple_uis.size(),
		get_child_count(),
	])

func _on_event_bus_send_ecs_ship_destroyed(
	ship: Entity,
):
	print("_on_event_bus_send_ecs_ship_destroyed")
	if !ships_dict.has(ship.ecs_id):
		return
	ships_dict.erase(ship.ecs_id)
	ships.erase(ship)
	
	remove_ship_uis(ship)
	
func remove_ship_uis(
	ship: Entity,
):
	if uis.has(ship.ecs_id):
		var ui = uis.get(ship.ecs_id)
		ui.queue_free()
		uis.erase(ship.ecs_id)
	if simple_uis.has(ship.ecs_id):
		var ui = simple_uis.get(ship.ecs_id)
		ui.queue_free()
		simple_uis.erase(ship.ecs_id)

func _on_event_bus_send_ecs_ship_appeared(
	ship: Entity,
):
	print("_on_event_bus_send_ecs_ship_appeared %s %s %s %s %s" % [
		ship.get_path(),
		ship.ecs_id,
		ships.size(),
		ships_dict.size(),
		uis.size(),
	])
	if ships_dict.has(ship.ecs_id):
		return
	
	ships.push_back(ship)
	ships_dict.set(
		ship.ecs_id,
		ship,
	)
	
	var simple_ui: SimpleShipFloatingUI_1 = SIMPLE_SHIP_FLOATING_UI_1.instantiate()
	simple_ui.hide()
	add_child(simple_ui)
	
	simple_ui.set_content(
		ship,
		StaticFactions.local_player_faction_id
	)
	simple_uis.set(
		ship.ecs_id,
		simple_ui,
	)
	
	var ui: ShipFloatingUI_1 = SHIP_FLOATING_UI_1.instantiate()
	ui.hide()
	add_child(ui)
	
	ui.set_content(
		ship,
		StaticFactions.local_player_faction_id
	)
	uis.set(
		ship.ecs_id,
		ui,
	)
	
