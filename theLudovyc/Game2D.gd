extends Node
class_name Game2D

@onready var rtl := $CanvasLayer/RichTextLabel

@onready var tm := %TileMap

@onready var cam := $Camera2D

@onready var node_buildings := %Buildings

@onready var event_bus := $EventBus

@onready var the_storage := $TheStorage
@onready var the_bank := $TheBank
@onready var the_factory := $TheFactory
@onready var the_market := $TheMarket
@onready var the_builder := $TheBuilder
@onready var the_population := $ThePopulation
@onready var the_cursor: TheCursor = %TheCursor
@onready var the_nature: TheNature = $TheNature

@onready var ground_layer: TileMapLayer = $ZSorter/TileMap/GroundLayer

@onready var gui := $GUI
@onready var pause_menu := %PauseMenu

const Trees_Destroy_Cost = 1

var current_selected_building: Building2D = null


# Called when the node enters the scene tree for the first time.
func _ready():
	# tm.create_island("res://theLudovyc/singularity_40.json")
	tm.create_minimap_from_gaea_layers()
	tm.clear_overlay()
	
	# set camera limits
	var pos_limits = tm.get_pos_limits()

	cam.pos_limit_top_left = pos_limits[0]
	cam.pos_limit_bot_right = pos_limits[1]
	
	var warehouse_pos = Vector2.ZERO
	
	if SaveHelper.save_file_name_to_load.is_empty():
		# the_builder.build_warehouse(Vector2(704, 320))

		# add some initial resources
		the_bank.money = 500

		the_storage.add_resource(Resources.Types.Wood, 20)
		the_storage.add_resource(Resources.Types.Textile, 20)
		the_storage.add_resource(Resources.Types.Plank, 20)
		the_storage.add_resource(Resources.Types.Potato, 800)
		the_storage.add_resource(Resources.Types.Meat, 400)
	
	elif SaveHelper.load_saved_file_name() == OK:
		if SaveHelper.last_loaded_data.is_empty():
			return
			
		var game_data:Dictionary = SaveHelper.last_loaded_data.get("Game", {})
		
		if game_data.is_empty():
			return
		
		the_population.load_population_save()
		the_storage.load_storage_save()
		the_bank.load_bank_save()
		the_factory.load_factory_save()
		the_market.load_market_save()
		the_builder.load_buildings_save()
	else:
		# save cannot be loaded
		# TODO show popup and return to main menu
		return
	
	# force camera initial pos on warehouse
	if the_builder.warehouse:
		cam.position = the_builder.warehouse.global_position
	else:
		var rect = ground_layer.get_used_rect()
		var center = ground_layer.to_global(ground_layer.map_to_local(rect.get_center()))
		cam.position = center
	cam.reset_smoothing()
	
	pause_menu.visibility_changed.connect(_on_PauseMenu_visibility_changed)

	pass  # Replace with function body.

# return [money_cost, [[Resources.Types, cost], ...]]
func get_building_total_cost(building_id, trees_to_destroy) -> Array:
	var trees_to_destroy_final_cost := 0
	
	if trees_to_destroy > 0:
		trees_to_destroy_final_cost = trees_to_destroy * Trees_Destroy_Cost
	
	var building_cost = Buildings.get_building_cost(building_id).duplicate(true)
	
	if building_cost.is_empty():
		return [-trees_to_destroy_final_cost, []]
		
	for i in range(building_cost.size()):
		var cost = building_cost[i]
			
		cost[1] *= -1
			
		if trees_to_destroy > 0 and (cost[0] == Resources.Types.Wood):
			cost[1] += trees_to_destroy
	
	return [-trees_to_destroy_final_cost, building_cost]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if pause_menu.visible == false and Input.is_action_just_pressed("ui_cancel"):
		pause_menu.show()
		pause_menu.set_process(true)
		get_tree().paused = true

	var mouse_pos = get_viewport().get_mouse_position()
	
	rtl.text = ""

	rtl.text += str(mouse_pos) + "\n"

	rtl.text += str(cam.get_screen_center_position()) + "\n"

	# may be optimized
	mouse_pos += cam.get_screen_center_position() - get_viewport().get_visible_rect().size / 2

	rtl.text += str(mouse_pos) + "\n"

	var tile_pos = tm.ground_layer.local_to_map(mouse_pos)

	rtl.text += str(tile_pos) + "\n"
	
	var cell_type = tm.minimap_get_cell(tile_pos)
	var cell_name = MyMap.get_cell_type_name(cell_type)
	rtl.text += str(cell_type) + " " + cell_name + "\n"

	rtl.text += str(tm.is_constructible(tile_pos)) + "\n"

	var tile_data = tm.get_cell_tile_data(0, tile_pos)

	if tile_data != null:
		rtl.text += str(tile_data.terrain_set) + " / " + str(tile_data.terrain) + "\n"

		rtl.text += str(tm.get_cell_atlas_coords(0, tile_pos))

	#spawn entity
	if the_cursor.cursor_entity:
		the_cursor.cursor_entity.position = tm.ground_layer.map_to_local(tile_pos)

		var building_id = the_cursor.cursor_entity.building_id
		var is_coastal = Buildings.get_is_coastal(building_id)
		var trees_to_destroy = 0
		if is_coastal:
			trees_to_destroy = handle_coastal_building(tile_pos)
		else:
			# FIXME : this probably uses a lot of performances
			# -1 can not build, 0 yes and 0 tree, 1+ yes and 1+ tree to destroy
			trees_to_destroy = tm.is_entityStatic_constructible(the_cursor.cursor_entity, tile_pos)
		
		var range = Buildings.get_dependency_max_range(the_cursor.cursor_entity.building_id)
		if range != -1:
			tm.show_affected_area_of_building(the_cursor.cursor_entity, range)
		else:
			tm.show_area_of_building(the_cursor.cursor_entity)
		
		if (trees_to_destroy < 0):
			the_cursor.cursor_entity.modulate = Color(Color.RED, 0.6)
			
			gui.set_rtl_visibility(false)
		else:
			var building_total_cost = get_building_total_cost(building_id, trees_to_destroy)

			if (
				(building_total_cost[0] >= 0 or
				(building_total_cost[0] < 0 and abs(building_total_cost[0]) < the_bank.money))
				and the_storage.has_resources_to_construct_building(building_total_cost[1])
			):
				gui.set_rtl_info_buiding_info(building_total_cost)
				gui.set_rtl_visibility(true)
				
				if trees_to_destroy > 0:
					the_cursor.cursor_entity.modulate = Color(Color.ORANGE, 0.6)
				else:
					the_cursor.cursor_entity.modulate = Color(Color.GREEN, 0.6)

				if (
					not the_cursor.cursor_entity_wait_release
					and Input.is_action_just_pressed("alt_command")
				):
					match Buildings.get_building_type(building_id):
						Buildings.Types.Residential:
							var amount := Buildings.get_max_workers(building_id)
							var population_type := Buildings.get_population_type((building_id))
							
							the_population.population_increase(population_type, amount)

							the_factory.population_increase(population_type, amount)

						Buildings.Types.Producing:
							the_factory.add_workers(
								Buildings.get_population_type(building_id),
								Buildings.get_produce_resource(building_id),
								Buildings.get_max_workers(building_id)
							)
					
					the_bank.money += building_total_cost[0]

					the_storage.conclude_building_construction(building_total_cost[1])
					the_builder.conclude_building_construction(the_cursor.cursor_entity)
					the_nature.conclude_building_construction(
						the_cursor.cursor_entity,
						tile_pos
					)

					event_bus.send_building_created.emit(building_id)

					tm.build_entityStatic(the_cursor.cursor_entity, tile_pos)

					gui.set_rtl_visibility(false)

					the_cursor.cursor_entity.modulate = Color.WHITE
					the_cursor.cursor_entity.build()
					the_cursor.cursor_entity = null
					
					tm.clear_overlay()

		if the_cursor.cursor_entity_wait_release and Input.is_action_just_released("alt_command"):
			the_cursor.cursor_entity_wait_release = false

		if the_cursor.cursor_entity and Input.is_action_just_pressed("main_command"):
			gui.set_rtl_visibility(false)

			event_bus.send_building_creation_aborted.emit(building_id)

			the_cursor.cursor_entity.call_deferred("queue_free")
			the_cursor.cursor_entity = null
			
			tm.clear_overlay()
		
func handle_coastal_building(tile_pos: Vector2i) -> int:
	# x is up right / north east
	# y is down right / south east
	var top_left_tile = tm.entityStatic_get_top_left_tile(the_cursor.cursor_entity, tile_pos)
	var cell_type = MyMap.Minimap_Cell_Type.Shallow
	#tm.color_red_at_pos(top_left_tile)
	if tm.minimap_get_cell(top_left_tile) == cell_type:
		# visually top
		var top_offset = Vector2i(the_cursor.cursor_entity.width - 1, 0)
		# visually bottom
		var bottom_offset = Vector2i(0, the_cursor.cursor_entity.height - 1)
		if tm.minimap_get_cell(top_left_tile + top_offset) == cell_type:
			# north west
			the_cursor.cursor_entity.switch_to_north_west_texture()
		elif tm.minimap_get_cell(top_left_tile + bottom_offset) == cell_type:
			# south west
			the_cursor.cursor_entity.switch_to_south_west_texture()
		else:
			return -1
	else:
		var offset = Vector2i(
			the_cursor.cursor_entity.width - 1,
			the_cursor.cursor_entity.height - 1
		)
		# visually right
		var right_tile = top_left_tile + offset
		if tm.minimap_get_cell(right_tile) == cell_type:
			# visually top
			var top_offset = Vector2i(the_cursor.cursor_entity.width - 1, 0)
			# visually bottom
			var bottom_offset = Vector2i(0, the_cursor.cursor_entity.height - 1)
			if tm.minimap_get_cell(top_left_tile + top_offset) == cell_type:
				# north east
				the_cursor.cursor_entity.switch_to_north_east_texture()
			elif tm.minimap_get_cell(top_left_tile + bottom_offset) == cell_type:
				# south east
				the_cursor.cursor_entity.switch_to_south_east_texture()
			else:
				return -1
		else:
			return -1
	
	var trees_to_destroy = tm.is_coastal_entity_constructible(
		the_cursor.cursor_entity,
		top_left_tile
	)
		
	return trees_to_destroy

func _on_EventBus_ask_create_building(building_id: Buildings.Ids):
	the_cursor.cursor_entity = the_builder.instantiate_building(building_id)
	the_cursor.cursor_entity_wait_release = true
	the_cursor.cursor_entity.modulate = Color(Color.RED, 0.6)
	
	tm.show_constructible_area_on_overlay(building_id)

func _on_EventBus_send_building_selected(building_node):
	current_selected_building = building_node


func _on_EventBus_ask_deselect_building():
	if current_selected_building != null:
		current_selected_building.deselect()
		current_selected_building = null

func _on_EventBus_ask_select_warehouse():
	if the_builder.warehouse:
		current_selected_building = the_builder.warehouse
		
		the_builder.warehouse.select()


func _on_EventBus_ask_demolish_current_building():
	tm.demolish_building(current_selected_building)

	var building_id = current_selected_building.building_id
	var tile_pos = tm.ground_layer.local_to_map(
		tm.ground_layer.to_local(current_selected_building.global_position)
	)

	the_storage.recover_building_construction(building_id)
	
	the_builder.conclude_building_destruction(building_id)
	
	the_nature.conclude_building_destruction(
		current_selected_building, tile_pos
	)
	
	var dependencies: Array[Building2D] = []
	var max_range = Buildings.get_dependency_max_range(building_id)

	match Buildings.get_building_type(building_id):
		Buildings.Types.Residential:
			var amount := Buildings.get_max_workers(building_id)
			var population_type := Buildings.get_population_type(building_id)

			the_population.population_decrease(population_type,amount)

			the_factory.population_decrease(population_type,amount)

		Buildings.Types.Producing:
			the_factory.rem_workers(
				Buildings.get_population_type(building_id),
				Buildings.get_produce_resource(building_id),
				Buildings.get_max_workers(building_id)
			)
			
			if max_range != -1:
				var deps = Buildings.get_building_dependencies(building_id)
				dependencies = the_builder.get_building_dependencies(
					current_selected_building,
					max_range,
					deps
				)
		_:
			pass

	node_buildings.remove_child(current_selected_building)
	current_selected_building.queue_free()
	current_selected_building = null
	
	# FIXME : maybe this should be done elsewhere
	# But, the building needs to have been removed first
	if dependencies.size() > 0:
		var existing_buildings = the_builder.get_buildings_of_id(building_id)
		if existing_buildings.size() == 0:
			for dep in dependencies:
				the_factory.rem_workers(
					Buildings.get_population_type(dep.building_id),
					Buildings.get_produce_resource(dep.building_id),
					Buildings.get_max_workers(dep.building_id)
				)
				dep.show_production_stoppped_indicator()
		else:
			var polygons: Array[Array] = []
			for _building in existing_buildings:
				var polygon = tm.get_polygon_range_of_building(_building, max_range)
				polygons.push_back(polygon)
			for dep in dependencies:
				var tile_center = tm.ground_layer.local_to_map(tm.ground_layer.to_local(dep.global_position))
				var top_left_tile = tm.entityStatic_get_top_left_tile(dep, tile_center)
				var is_in_range = tm.is_in_range_of_allowed_polygons(
					dep, polygons, top_left_tile
				)
				if !is_in_range:
					the_factory.rem_workers(
						Buildings.get_population_type(dep.building_id),
						Buildings.get_produce_resource(dep.building_id),
						Buildings.get_max_workers(dep.building_id)
					)
					dep.show_production_stoppped_indicator()

	event_bus.send_current_building_demolished.emit()

func _on_PauseMenu_ask_to_save() -> void:
	var dicoToSave := {
		"Game": {}
	}
	
	dicoToSave.merge(the_population.get_population_save())
	dicoToSave.merge(the_storage.get_storage_save())
	dicoToSave.merge(the_bank.get_bank_save())
	dicoToSave.merge(the_factory.get_factory_save())
	dicoToSave.merge(the_market.get_market_save())
	dicoToSave.merge(the_builder.get_buildings_save())
	
	pause_menu.save_this_please(dicoToSave)

func _on_PauseMenu_visibility_changed():
	if pause_menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
