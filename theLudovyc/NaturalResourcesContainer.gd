extends Node2D

@onready var tile_map: MyTileMap = %TileMap

@onready var ground_layer: TileMapLayer = $"../TileMap/GroundLayer"

const NATURAL_RESOURCE = preload("res://theLudovyc/NaturalResource/NaturalResource.tscn")

const max_count := 10

func create_natural_resources():
	create_natural_resources_based_on_ground_tiles()
	
func create_natural_resources_based_on_random_minimap_pos():
	# Info: not working very well because not many tiles are ground tiles I think
	for i in range(max_count):
		if get_child_count() >= max_count:
			break
		attempt_to_spawn(30)

func attempt_to_spawn(max_attempt_count: int) -> bool:
	for i in max_attempt_count:
		var loc = randi_range(0, tile_map.minimap.size() - 1)

		if tile_map.minimap[i] == MyMap.Minimap_Cell_Type.Ground \
			or tile_map.minimap[loc] == MyMap.Minimap_Cell_Type.Tree:
			
			var pos = tile_map.minimap_get_pos(loc)
			
			var res_key = NaturalResources.datas.keys().pick_random()
			var data = NaturalResource.datas[res_key]
			var is_constructible = tile_map.is_entity_constructible(
				pos,
				data[NaturalResource.Datas.Width],
				data[NaturalResource.Datas.Height]
			)
			if is_constructible == -1:
				continue
			
			var instance = NATURAL_RESOURCE.instantiate()
			
			instance.natural_resource_id = res_key
			
			instance.position = tile_map.ground_layer.map_to_local(pos)
			
			var cell_type = NaturalResources.get_natural_resource_tile_type(
				res_key
			)
		
			tile_map.build_entityStatic(
				instance, pos, cell_type
			)
			
			add_child(instance)
			
			return true
	return false

func create_natural_resources_based_on_ground_tiles():
	var cell_type: MyMap.Minimap_Cell_Type = MyMap.Minimap_Cell_Type.Ground
	var source_id = MyMap.get_source_id(cell_type)
	var atlas_coords = MyMap.get_atlas_coords(cell_type)
	
	var all_cells: Array[Vector2i] = []
	
	for coord in atlas_coords:
		var cells = ground_layer.get_used_cells_by_id(
			source_id, coord
		)
		all_cells.append_array(cells)
		
	for i in range(max_count):
		if get_child_count() >= max_count:
			break
		attempt_to_spawn_in_tiles(30, all_cells)

func attempt_to_spawn_in_tiles(max_attempt_count: int, tiles: Array[Vector2i]) -> bool:
	for i in max_attempt_count:
		var pos = tiles.pick_random()
			
		var res_key = NaturalResources.datas.keys().pick_random()
		var data = NaturalResource.datas[res_key]
		var is_constructible = tile_map.is_entity_constructible(
			pos,
			data[NaturalResource.Datas.Width],
			data[NaturalResource.Datas.Height]
		)
		if is_constructible == -1:
			continue
		
		var instance = NATURAL_RESOURCE.instantiate()
		
		instance.natural_resource_id = res_key
		
		instance.position = tile_map.ground_layer.map_to_local(pos)
		
		var cell_type = NaturalResources.get_natural_resource_tile_type(
			res_key
		)
	
		tile_map.build_entityStatic(
			instance, pos, cell_type
		)
		
		add_child(instance)
		
		return true
	return false
