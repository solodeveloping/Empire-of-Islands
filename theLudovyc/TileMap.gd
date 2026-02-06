extends TileMap
class_name MyTileMap

@onready var game:Game2D = get_tree().current_scene
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var trees_layer: TileMapLayer = $TreesLayer
@onready var ground_overlay_layer: TileMapLayer = %GroundOverlayLayer
@onready var building_ground_overlay_layer: TileMapLayer = $BuildingGroundOverlayLayer
@onready var the_builder = $"../../TheBuilder"
@onready var natural_resources = %NaturalResources
@onready var gaea_generator: GaeaGenerator = %GaeaGenerator


var map_size:Vector2i

var minimap:PackedByteArray

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

func minimap_set_cell(x:int, y:int, type:MyMap.Minimap_Cell_Type):
	minimap[y * map_size.x + x] = type

func minimap_set_cell_vec(vec:Vector2i, type:MyMap.Minimap_Cell_Type):
	minimap_set_cell(vec.x, vec.y, type)

func minimap_get_cell(vec:Vector2i) -> MyMap.Minimap_Cell_Type:
	if vec.x < 0 or vec.y < 0 or vec.x >= map_size.x or vec.y >= map_size.y:
		return MyMap.Minimap_Cell_Type.Deep
	
	return minimap[vec.y * map_size.x + vec.x]
	
func minimap_get_pos(index:int) -> Vector2i:
	return Vector2i(index % map_size.x, index / map_size.x)

func minimap_get_index(vec: Vector2i):
	return vec.y * map_size.x + vec.x

func is_constructible(tile_pos:Vector2i) -> int:
	match minimap_get_cell(tile_pos):
		MyMap.Minimap_Cell_Type.Ground:
			return 1
		MyMap.Minimap_Cell_Type.Tree:
			return 2
	return 0

## Visually left tile
func entityStatic_get_top_left_tile(entity:EntityStatic, tile_center:Vector2i) -> Vector2i:
	return entity_get_top_left_tile(
		tile_center,
		entity.width,
		entity.height,
		entity.height_offset
	)

## Visually left tile
func entity_get_top_left_tile(
	tile_center:Vector2i,
	width: int,
	height: int,
	height_offset: int = 0
) -> Vector2i:
	if height % 2 == 0:
		return Vector2i(tile_center.x, tile_center.y - height / 2 + height_offset)
	else:
		return Vector2i(tile_center.x - ceil(width / 2), tile_center.y - ceil(height / 2) + height_offset)

# 0 or >0 == OK
# -1 == KO
# >0 numbers of trees
func is_entityStatic_constructible(entity:EntityStatic, tile_center:Vector2i) -> int:
	var top_left_tile = entityStatic_get_top_left_tile(entity, tile_center)
	
	var require_cell_type = Buildings.get_require_map_cell_type(entity.building_id)
	if require_cell_type != -1:
		var trees = are_tiles_constructible_on_cell_type(
			entity, top_left_tile, require_cell_type
		)
		return trees
	
	var trees = are_tiles_constructible(
		entity, top_left_tile
	)
	if trees == -1:
		return trees
	
	var require_building = Buildings.get_require_building(entity.building_id)
	
	if require_building != -1:
		var is_in_range = is_in_range_of_allowed_polygons(
			entity, allowed_polygons, top_left_tile
		)
		if !is_in_range:
			return -1
	
	return trees

func are_tiles_constructible(
	entity: EntityStatic,
	top_left_tile: Vector2i
) -> int:
	var trees = 0
	for x in entity.width:
		for y in entity.height:
			match is_constructible(top_left_tile + Vector2i(x, y)):
				2:
					trees += 1
				0:
					return -1
	return trees
	
func are_tiles_constructible_on_cell_type(
	entity: EntityStatic,
	top_left_tile: Vector2i,
	cell_type: MyMap.Minimap_Cell_Type
) -> int:
	for x in entity.width:
		for y in entity.height:
			if minimap_get_cell(top_left_tile + Vector2i(x, y)) != cell_type:
				return -1
	return 0

## The result only matter if you have checked other rules before
func is_coastal_entity_constructible(
	entity: EntityStatic,
	top_left_tile: Vector2i,
) -> int:
	var trees = 0
	for x in entity.width:
		for y in entity.height:
			var cell_type = minimap_get_cell(top_left_tile + Vector2i(x, y))
			match cell_type:
				MyMap.Minimap_Cell_Type.Ground, MyMap.Minimap_Cell_Type.Sand, MyMap.Minimap_Cell_Type.Shallow:
					pass
				MyMap.Minimap_Cell_Type.Tree:
					trees += 1
				_:
					return -1
	return trees

func is_in_range_of_allowed_polygons(
	entity:EntityStatic,
	polygons: Array[Array],
	top_left_tile: Vector2i
) -> bool:
	var has_correct_required_building = false
	for polygon in polygons:
		var is_in_range = is_in_range_of_polygon(entity, polygon, top_left_tile)
		if is_in_range:
			has_correct_required_building = true
			break
	if !has_correct_required_building:
		return false
	return true

func is_in_range_of_polygon(
	entity:EntityStatic,
	polygon: Array,
	top_left_tile: Vector2i
) -> bool:
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
	if is_polygon_invalid:
		return false
	else:
		return true

# 0 or >0 == OK
# -1 == KO
# >0 numbers of trees
func is_entity_constructible(
	tile_center: Vector2i,
	width: int,
	height: int,
	height_offset: int = 0
) -> int:
	var top_left_tile = entity_get_top_left_tile(
		tile_center,
		width,
		height,
		height_offset
	)
	
	var trees = 0
	
	for x in width:
		for y in height:
			match is_constructible(top_left_tile + Vector2i(x, y)):
				2:
					trees += 1
				0:
					return -1
	
	return trees

func build_entityStatic(
	entity:EntityStatic,
	tile_center:Vector2i,
	cell_type: MyMap.Minimap_Cell_Type = MyMap.Minimap_Cell_Type.Building
):
	var top_left_tile = entityStatic_get_top_left_tile(entity, tile_center)
	
	for x in entity.width:
		for y in entity.height:
			var tile_coord = top_left_tile + Vector2i(x, y)
			
			if minimap_get_cell(tile_coord) == MyMap.Minimap_Cell_Type.Tree:
				trees_layer.erase_cell(tile_coord)
			
			minimap_set_cell_vec(tile_coord, cell_type)

func conclude_building_construction(building:Building2D):
	build_entityStatic(building, ground_layer.local_to_map(building.position))

func demolish_building(building:Building2D):
	var top_left_tile = entityStatic_get_top_left_tile(building,
		ground_layer.local_to_map(ground_layer.to_local(building.global_position)))

	for x in building.width:
		for y in building.height:
			var tile_coord = top_left_tile + Vector2i(x, y)
			
			minimap_set_cell_vec(tile_coord, MyMap.Minimap_Cell_Type.Ground)

func clear_overlay():
	ground_overlay_layer.clear()
	building_ground_overlay_layer.clear()
	allowed_polygons.clear()

func show_constructible_area_on_overlay(building_id: Buildings.Ids):
	ground_overlay_layer.clear()
	
	var is_coastal = Buildings.get_is_coastal(building_id)
	if is_coastal:
		show_all_constructible_tiles_of_type(MyMap.Minimap_Cell_Type.Shallow)
		return
	
	var require_map_cell_tile = Buildings.get_require_map_cell_type(building_id)
	if require_map_cell_tile != -1:
		# FIXME : we could display the natural resources too
		# When there is one
		show_all_constructible_tiles_of_type(require_map_cell_tile)
		return
	
	var require_building = Buildings.get_require_building(building_id)
	if require_building == -1:
		show_all_constructible_tiles()
		var range = Buildings.get_dependency_max_range(building_id)
		if range != -1:
			var buildings = the_builder.get_buildings_of_id(building_id)
			# we show similar buildings range for better experience
			for building in buildings:
				show_affected_area_of_existing_building(building, range)
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
				var type = minimap_get_cell(tile_coord)
				color_overlay_at_pos(tile_coord, type)
		
		var polygon = get_polygon_range_of_building(building, range)
		allowed_polygons.push_back(polygon)
		
		# Use this to debug the farms limit visually in global coordinates
		#ground_overlay_layer.add_debug_polygon(
			#top_left_tile,
			#building,
			#range
		#)
		
	
	ground_overlay_layer.queue_redraw()

func get_polygon_range_of_building(
	building: Building2D,
	range: int,
) -> Array:
	var center = ground_layer.local_to_map(ground_layer.to_local(building.global_position))
	var top_left_building = entityStatic_get_top_left_tile(
		building,
		center
	)
	var top_left_tile = top_left_building - Vector2i(range, range)
	
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
	
	return polygon

func show_all_constructible_tiles():
	for i in range(minimap.size()):
		if minimap[i] == MyMap.Minimap_Cell_Type.Ground \
			or minimap[i] == MyMap.Minimap_Cell_Type.Tree:
				var pos = minimap_get_pos(i)
				match minimap[i]:
					MyMap.Minimap_Cell_Type.Ground:
						ground_overlay_layer.set_cell(pos, OverlayTileset.Green, tile_overlay_pos)
					MyMap.Minimap_Cell_Type.Tree:
						ground_overlay_layer.set_cell(pos, OverlayTileset.Yellow, tile_overlay_pos)

func show_all_constructible_tiles_of_type(cell_type: MyMap.Minimap_Cell_Type):
	for i in range(minimap.size()):
		if minimap[i] == cell_type:
			var pos = minimap_get_pos(i)
			ground_overlay_layer.set_cell(pos, OverlayTileset.Green, tile_overlay_pos)

func color_overlay_at_pos(pos: Vector2i, tile_type: MyMap.Minimap_Cell_Type):
	match tile_type:
		MyMap.Minimap_Cell_Type.Ground:
			ground_overlay_layer.set_cell(pos, OverlayTileset.Green, tile_overlay_pos)
		MyMap.Minimap_Cell_Type.Tree:
			ground_overlay_layer.set_cell(pos, OverlayTileset.Yellow, tile_overlay_pos)

func show_affected_area_of_building(building: Building2D, range: int):
	building_ground_overlay_layer.clear()
	var center = ground_layer.local_to_map(ground_layer.to_local(building.global_position))
	var top_left_building = entityStatic_get_top_left_tile(
		building,
		center
	)
	var top_left_tile = top_left_building - Vector2i(range, range)
	for x in building.width + range * 2:
		for y in building.height + range * 2:
			var tile_coord = top_left_tile + Vector2i(x, y)
			color_affected_area_at_pos(tile_coord)

func show_affected_area_of_existing_building(building: Building2D, range: int):
	building_ground_overlay_layer.clear()
	var center = ground_layer.local_to_map(ground_layer.to_local(building.global_position))
	var top_left_building = entityStatic_get_top_left_tile(
		building,
		center
	)
	var top_left_tile = top_left_building - Vector2i(range, range)
	for x in building.width + range * 2:
		for y in building.height + range * 2:
			var tile_coord = top_left_tile + Vector2i(x, y)
			# we color in appropriate color the affected tiles
			# we could color trees in yellow but I think it looks better
			# if it's uniform
			color_existing_building_affected_area_at_pos(tile_coord)

func show_area_of_building(building: Building2D):
	building_ground_overlay_layer.clear()
	var center = ground_layer.local_to_map(ground_layer.to_local(building.global_position))
	var top_left_building = entityStatic_get_top_left_tile(
		building,
		center
	)
	for x in building.width:
		for y in building.height :
			var tile_coord = top_left_building + Vector2i(x, y)
			color_affected_area_at_pos(tile_coord)

func color_affected_area_at_pos(tile_coord: Vector2i):
	building_ground_overlay_layer.set_cell(tile_coord, OverlayTileset.DarkerGreen, tile_overlay_pos)

func color_existing_building_affected_area_at_pos(pos: Vector2i):
	ground_overlay_layer.set_cell(pos, OverlayTileset.DarkerGreen, tile_overlay_pos)


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
	
	# FIXME : this should be loaded at some point
	trees_layer.create_trees()
	natural_resources.create_natural_resources()
	
	return OK

func create_minimap_from_gaea_layers():
	map_size = Vector2i(
		gaea_generator.world_size.x,
		gaea_generator.world_size.y,
	)
	
	minimap.resize(map_size.x * map_size.y)
	
	assign_cell_type_to_minimap_using_ground_layer(
		MyMap.Minimap_Cell_Type.Deep
	)
	assign_cell_type_to_minimap_using_ground_layer(
		MyMap.Minimap_Cell_Type.Shallow
	)
	assign_cell_type_to_minimap_using_ground_layer(
		MyMap.Minimap_Cell_Type.Sand
	)
	assign_cell_type_to_minimap_using_ground_layer(
		MyMap.Minimap_Cell_Type.Ground
	)
	assign_cell_type_to_minimap_using_tree_layer(
		MyMap.Minimap_Cell_Type.Tree
	)
	
	natural_resources.create_natural_resources()
	
func assign_cell_type_to_minimap_using_ground_layer(
	cell_type: MyMap.Minimap_Cell_Type
):
	var source_id = MyMap.get_source_id(cell_type)
	var atlas_coords = MyMap.get_atlas_coords(cell_type)
	
	for coord in atlas_coords:
		var cells = ground_layer.get_used_cells_by_id(
			source_id, coord
		)
		for cell in cells:
			minimap_set_cell_vec(cell, cell_type)
		
func assign_cell_type_to_minimap_using_tree_layer(
	cell_type: MyMap.Minimap_Cell_Type
):
	var source_id = MyMap.get_source_id(cell_type)
	var atlas_coords = MyMap.get_atlas_coords(cell_type)
	for coord in atlas_coords:
		var cells = trees_layer.get_used_cells_by_id(
			source_id, coord
		)
		for cell in cells:
			minimap_set_cell_vec(cell, cell_type)

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
