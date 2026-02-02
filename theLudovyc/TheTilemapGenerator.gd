@tool
extends Node
class_name TheTilemapGenerator

@export
var gaea_generator: GaeaGenerator

@onready var ground_layer: TileMapLayer = $"../ZSorter/TileMap/GroundLayer"
@onready var trees_layer: TileMapLayer = $"../ZSorter/TileMap/TreesLayer"

@onready var tile_map: MyTileMap = %TileMap

func _ready() -> void:
	gaea_generator.generation_finished.connect(_on_gaea_generator_generation_finished)

func _on_gaea_generator_generation_finished(grid: GaeaGrid):
	# FIXME : maybe we should not do the Godot terrain here?
	# Or not in the Editor
	# Or redo it during gameplay
	var ground = ground_layer.get_used_cells_by_id(1, Vector2i(7, 6))
	var sand_tiles = ground_layer.get_used_cells_by_id(1, Vector2i(7, 2))
	var shallow_tiles = ground_layer.get_used_cells_by_id(1, Vector2i(4, 2))
	
	ground_layer.set_cells_terrain_connect(ground, 0, 3)
	ground_layer.set_cells_terrain_connect(sand_tiles, 0, 2)
	ground_layer.set_cells_terrain_connect(shallow_tiles, 0, 1)
	
	#var trees = trees_layer.get_used_cells()
	#for tree_pos in trees:
		#tile_map.minimap_set_cell_vec(tree_pos, MyMap.Minimap_Cell_Type.Tree)
