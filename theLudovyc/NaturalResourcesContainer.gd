extends Node2D

@onready var tile_map: MyTileMap = %TileMap

const NATURAL_RESOURCE = preload("res://theLudovyc/NaturalResource/NaturalResource.tscn")

const max_count := 3

func create_natural_resources():
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
			var res = NaturalResources.datas[res_key]
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
