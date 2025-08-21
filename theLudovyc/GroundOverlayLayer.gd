extends TileMapLayer

var allowed_polygons: Array[Array] = []

func _draw() -> void:
	for rect in allowed_polygons:
		for i in range(rect.size()):
			draw_line(rect[i-1] , rect[i], Color.RED , 10)

func add_debug_polygon(top_left_tile: Vector2i, building: Building2D, range: int):
	var polygon = []
	# visually left
	polygon.push_back(
		to_global(map_to_local(top_left_tile))
	)
	# visually top
	polygon.push_back(
		to_global(
			map_to_local(
				top_left_tile + Vector2i(building.width + range * 2 - 1, 0)
			)
		)
	)
	# visually right
	polygon.push_back(
		to_global(
			map_to_local(
				top_left_tile + Vector2i(building.width + range * 2 - 1, building.height + range * 2 - 1)
			)
		)
	)
	# visually bottom
	polygon.push_back(
		to_global(
			map_to_local(
				top_left_tile + Vector2i(0, building.height + range * 2 - 1)
			)
		)
	)
	allowed_polygons.push_back(polygon)
