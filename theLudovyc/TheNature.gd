extends Node
class_name TheNature

@onready var natural_resources: Node2D = %NaturalResources
@onready var tile_map: MyTileMap = %TileMap

func conclude_building_construction(building: Building2D, tile_pos: Vector2i):
	var require_res = Buildings.get_require_natural_resource(building.building_id)
	if require_res == -1:
		return
		
	var res = find_natural_resource_at_pos(
		tile_pos
	)
	if res == null:
		push_error("could not find natural resource at pos %s" % str(tile_pos))
		return
		
	res.hide()
	
func conclude_building_destruction(building: Building2D, tile_pos: Vector2i):
	var require_res = Buildings.get_require_natural_resource(building.building_id)
	if require_res == -1:
		return
		
	var res = find_natural_resource_at_pos(
		tile_pos
	)
	if res == null:
		push_error("could not find natural resource at pos %s" % str(tile_pos))
		return
	
	var cell_type = NaturalResources.get_natural_resource_tile_type(
		res.natural_resource_id
	)
	tile_map.build_entityStatic(
		res, tile_pos, cell_type
	)
	
	res.show()

func find_natural_resource_at_pos(pos: Vector2i) -> NaturalResource:
	for child in natural_resources.get_children():
		var child_pos = tile_map.ground_layer.local_to_map(
			tile_map.ground_layer.to_local(
				child.global_position
			)
		)
		if child_pos == pos:
			return child
	return null
