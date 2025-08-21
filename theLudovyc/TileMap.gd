extends TileMap
class_name MyTileMap

@onready var game:Game2D = get_tree().current_scene
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var trees_layer: TileMapLayer = $TreesLayer
@onready var ground_overlay_layer: TileMapLayer = %GroundOverlayLayer
@onready var the_builder = $"../../TheBuilder"

var map_size:Vector2i

var minimap:PackedByteArray

enum Minimap_Cell_Type{Deep, Shallow, Sand, Ground, Tree, Building}

var allowed_polygons: Array[Array] = []

# FIXME : could do one tile and a modulate but seem more complicated
enum OverlayTileset {
	White = 0,
	Green = 1,
	Red = 2,
	DarkerGreen = 3,
	Yellow = 4,
}

# FIXME : we can remove this if we repack the tiles
const tile_overlay_pos = Vector2i(0, 1)

func minimap_set_cell(x:int, y:int, type:Minimap_Cell_Type):
	minimap[y * map_size.x + x] = type

func minimap_set_cell_vec(vec:Vector2i, type:Minimap_Cell_Type):
	minimap_set_cell(vec.x, vec.y, type)

func minimap_get_cell(vec:Vector2i) -> Minimap_Cell_Type:
	if vec.x < 0 or vec.y < 0 or vec.x >= map_size.x or vec.y >= map_size.y:
		return Minimap_Cell_Type.Deep
	
	return minimap[vec.y * map_size.x + vec.x]
	
func minimap_get_pos(index:int) -> Vector2i:
	return Vector2i(index % map_size.x, index / map_size.x)
	
func is_constructible(tile_pos:Vector2i) -> int:
	match minimap_get_cell(tile_pos):
		Minimap_Cell_Type.Ground:
			return 1
		Minimap_Cell_Type.Tree:
			return 2
	return 0

func entityStatic_get_top_left_tile(entity:EntityStatic, tile_center:Vector2i) -> Vector2i:
	if entity.height % 2 == 0:
		return Vector2i(tile_center.x, tile_center.y - entity.height / 2)
	else:
		return Vector2i(tile_center.x - ceil(entity.width / 2), tile_center.y - ceil(entity.height / 2))

# 0 or >0 == OK
# -1 == KO
# >0 numbers of trees
func is_entityStatic_constructible(entity:EntityStatic, tile_center:Vector2i) -> int:
	var top_left_tile = entityStatic_get_top_left_tile(entity, tile_center)
	
	var trees = 0
	
	var require_building = Buildings.get_require_building(entity.building_id)
	
	for x in entity.width:
		for y in entity.height:
			match is_constructible(top_left_tile + Vector2i(x, y)):
				2:
					trees += 1
				0:
					return -1
	
	if require_building != -1:
		var has_correct_required_building = false
		for polygon in allowed_polygons:
			var is_polygon_invalid = false
			for x in entity.width:
				if is_polygon_invalid:
					break
				for y in entity.height:
					var pos = top_left_tile + Vector2i(x, y)
					if !Geometry2D.is_point_in_polygon(pos, polygon):
						# FIXME : we could display in red the tiles outside
						# the region
						is_polygon_invalid = true
						break
			if !is_polygon_invalid:
				has_correct_required_building = true
		if !has_correct_required_building:
			return -1
	
	return trees

func build_entityStatic(entity:EntityStatic, tile_center:Vector2i):
	var top_left_tile = entityStatic_get_top_left_tile(entity, tile_center)
	
	for x in entity.width:
		for y in entity.height:
			var tile_coord = top_left_tile + Vector2i(x, y)
			
			if minimap_get_cell(tile_coord) == Minimap_Cell_Type.Tree:
				trees_layer.erase_cell(tile_coord)
			
			minimap_set_cell_vec(tile_coord, Minimap_Cell_Type.Building)
			
func conclude_building_construction(building:Building2D):
	build_entityStatic(building, ground_layer.local_to_map(building.position))

func demolish_building(building:Building2D):
	var top_left_tile = entityStatic_get_top_left_tile(building,
		ground_layer.local_to_map(ground_layer.to_local(building.global_position)))

	for x in building.width:
		for y in building.height:
			var tile_coord = top_left_tile + Vector2i(x, y)
			
			minimap_set_cell_vec(tile_coord, Minimap_Cell_Type.Ground)

func clear_overlay():
	ground_overlay_layer.clear()
	allowed_polygons.clear()

func show_constructible_area_on_overlay(building_id: Buildings.Ids):
	ground_overlay_layer.clear()
	var require_building = Buildings.get_require_building(building_id)
	if require_building == -1:
		# This is useful to debug for now
		show_all_constructible_tiles()
		return
	
	var range = Buildings.get_dependency_max_range(require_building)
	var buildings = the_builder.get_buildings_of_id(require_building)
	for building in buildings:
		var center = ground_layer.local_to_map(ground_layer.to_local(building.global_position))
		var top_left_building = entityStatic_get_top_left_tile(
			building,
			center
		)
		var top_left_tile = top_left_building - Vector2i(range, range)
		for x in building.width + range * 2:
			for y in building.height + range * 2:
				var tile_coord = top_left_tile + Vector2i(x, y)
				#var dist = Vector2(center).distance_to(Vector2(tile_coord))
				#if dist <= building.height / 2 + range:
				var type = minimap_get_cell(tile_coord)
				color_overlay_at_pos(tile_coord, type)
		
		var polygon = []
		# x is top-right
		# y is left-bottom
		var right_offset = building.height + range * 2 - 1
		var top_right_offset = building.width + range * 2 - 1
		# visually left
		polygon.push_back(top_left_tile + Vector2i(0 , 0))
		# visually top
		polygon.push_back(top_left_tile + Vector2i(top_right_offset, 0))
		# visually right
		polygon.push_back(top_left_tile + Vector2i(top_right_offset, right_offset))
		# visually bottom
		polygon.push_back(top_left_tile + Vector2i(0, right_offset))
		allowed_polygons.push_back(polygon)
		
		# Use this to debug the farms limit visually in global coordinates
		#ground_overlay_layer.add_debug_polygon(
			#top_left_tile,
			#building,
			#range
		#)
		
	
	ground_overlay_layer.queue_redraw()

# FIXME : could use this and no alpha too
func show_all_constructible_tiles():
	for i in range(minimap.size()):
		if minimap[i] == MyTileMap.Minimap_Cell_Type.Ground \
			or minimap[i] == Minimap_Cell_Type.Tree:
				var pos = minimap_get_pos(i)
				match minimap[i]:
					Minimap_Cell_Type.Ground:
						ground_overlay_layer.set_cell(pos, OverlayTileset.Green, tile_overlay_pos)
					Minimap_Cell_Type.Tree:
						ground_overlay_layer.set_cell(pos, OverlayTileset.Yellow, tile_overlay_pos)

func color_overlay_at_pos(pos: Vector2i, tile_type: Minimap_Cell_Type):
	match tile_type:
		Minimap_Cell_Type.Ground:
			ground_overlay_layer.set_cell(pos, OverlayTileset.Green, tile_overlay_pos)
		Minimap_Cell_Type.Tree:
			ground_overlay_layer.set_cell(pos, OverlayTileset.Yellow, tile_overlay_pos)

func create_island(map_file:String) -> int:
	var file = FileAccess.open(map_file, FileAccess.READ)
	
	if file == null:
		push_error("Error: can't open file")
		return FAILED
	
	var json = JSON.new()
	
	if json.parse(file.get_as_text()) != OK:
		push_error("Error: can't parse json")
		return FAILED
	
	var json_map_size = json.data["size"]
	
	map_size = Vector2i(json_map_size[0], json_map_size[1])
	
	minimap.resize(map_size.x * map_size.y)
	
	ground_layer.create_terrain(
		json.data["deep_tiles"],
		json.data["shallow_tiles"],
		json.data["sand_tiles"],
		json.data["ground_tiles"]
	)
	
	trees_layer.create_trees()
	
	return OK

func get_pos_limits() -> PackedVector2Array:
	var used_rect = ground_layer.get_used_rect()
	
	var pre_array:PackedVector2Array = [
		ground_layer.map_to_local(used_rect.position),
		ground_layer.map_to_local(used_rect.position + Vector2i(used_rect.size.x, 0)),
		ground_layer.map_to_local(used_rect.position + Vector2i(0, used_rect.size.y)),
		ground_layer.map_to_local(used_rect.position + Vector2i(used_rect.size.x, used_rect.size.y))
	]
	
	var return_array:PackedVector2Array = [
		pre_array[0], pre_array[1]
	]
	
	for vec in pre_array:
		if vec.x < return_array[0].x:
			return_array[0].x = vec.x
			
		if vec.y < return_array[0].y:
			return_array[0].y = vec.y
			
		if vec.x > return_array[1].x:
			return_array[1].x = vec.x
			
		if vec.y > return_array[1].y:
			return_array[1].y = vec.y
	
	return return_array

func local_to_map_to_local(position:Vector2) -> Vector2:
	return map_to_local(local_to_map(position))
