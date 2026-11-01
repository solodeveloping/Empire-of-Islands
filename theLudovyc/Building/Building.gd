@tool

extends EntityStatic
class_name Building2D

# Info : this is the script used to display all buildings
# the other scenes are not used

@onready var starving_sprite_2d: Sprite2D = $StarvingSprite2D
@onready var production_stopped_sprite_2d: Sprite2D = $ProductionStoppedSprite2D

enum Datas {
	Texture,
	Width,
	Height,
	HeightOffset,
	WidthOffset,
	TextureNorthWest,
	TextureNorthEast,
	TextureSouthEast,
	TextureSouthWest,
}

# We are using 1 frame atlas_texture for now
# When we have the appropriate buildings (sawmill)
# We can either replace the source of the AtlasTexture
# Or we can delete them and replace the placeholder texture with the right one
# In this case, we need to modify the number of VFrames in Building2D.tscn

# TOIMPROVE: replace these by uids

const datas = {
	Buildings.Ids.Warehouse: {
		#Datas.Texture: preload("res://theLudovyc/Building/warehouse.png"),
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/warehouse_atlas_texture.tres"),
		Datas.TextureNorthWest: preload("res://theLudovyc/Building/atlas_textures/warehouse_north_west_atlas_texture.tres"),
		Datas.TextureNorthEast: preload("res://theLudovyc/Building/atlas_textures/warehouse_north_east_atlas_texture.tres"),
		Datas.TextureSouthEast: preload("res://theLudovyc/Building/atlas_textures/warehouse_south_east_atlas_texture.tres"),
		Datas.TextureSouthWest: preload("res://theLudovyc/Building/atlas_textures/warehouse_south_west_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
	Buildings.Ids.MainSquare: {
		Datas.Texture: preload("uid://vw6fdakry6tx"),
		Datas.TextureNorthWest: preload("uid://vw6fdakry6tx"),
		Datas.TextureNorthEast: preload("uid://bkxc38w8uo67u"),
		Datas.TextureSouthEast: preload("uid://7kv3o4mkiv5e"),
		Datas.TextureSouthWest: preload("uid://bbxap58py7q56"),
		Datas.Width: 5,
		Datas.Height: 5,
		Datas.HeightOffset: 0,
		Datas.WidthOffset: 1,
	},
	
	# Level 1
	Buildings.Ids.Tent: {
		#Datas.Texture: preload("res://theLudovyc/Building/residential.png"),
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/tent_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.Lumberjack: {
		#Datas.Texture: preload("res://theLudovyc/Building/lumberjack.png"),
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/lumberjack_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.HunterTent: {
		#Datas.Texture: preload("res://theLudovyc/Building/lumberjack.png"),
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/hunter_tent_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.Fishery: {
		Datas.TextureNorthWest: preload("res://theLudovyc/Building/atlas_textures/fishery_north_west_atlas_texture.tres"),
		Datas.TextureNorthEast: preload("res://theLudovyc/Building/atlas_textures/fishery_north_east_atlas_texture.tres"),
		Datas.TextureSouthEast: preload("res://theLudovyc/Building/atlas_textures/fishery_south_east_atlas_texture.tres"),
		Datas.TextureSouthWest: preload("res://theLudovyc/Building/atlas_textures/fishery_south_west_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	# Level 2
	Buildings.Ids.Hut: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/hut_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.Sawmill: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/sawmill_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.Farm: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/farm_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
	Buildings.Ids.PotatoField: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/potato_field_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
	Buildings.Ids.Pigsty: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/pigsty_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
	Buildings.Ids.Butchery: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/butchery_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.ClayPit: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/clay_pit_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
	Buildings.Ids.Brickyard: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/brickyard_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 4,
		Datas.HeightOffset: 1,
	},
	# Level 3
	Buildings.Ids.House: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/timber_frame_house_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.WheatField: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/wheat_field_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
	Buildings.Ids.Windmill: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/windmill_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.Bakery: {
		Datas.Texture: preload("uid://dhbpe31urgkfc"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.Pasture: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/pasture_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
	Buildings.Ids.Weaver: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/weaver_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.StonePit: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/stone_pit_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
	Buildings.Ids.Stonemason: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/stonemason_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	# Level 4
	Buildings.Ids.StoneHouse: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/stone_house_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
}

var building_id: Buildings.Ids = -1:
	set(p_building_id):
		if p_building_id != building_id:
			building_id = p_building_id
			
			var building_data = datas.get(building_id)
			
			if building_data == null:
				var building_name = Buildings.get_building_name(building_id)
				push_error(
					"Cannot find datas for this id: %s %s" % [
						building_id,
						building_name,
					]
				)
				return
			
			width = building_data[Datas.Width]
			height = building_data[Datas.Height]
			height_offset = get_height_offset()
			width_offset = get_width_offset()
			
			var is_coastal = Buildings.get_is_coastal(building_id)
			if !is_coastal:
				texture = building_data[Datas.Texture]
			else:
				texture = building_data[Datas.TextureNorthWest]
			
			update_offset()

var event_bus: EventBus

var is_selected := false

# FIXME : I'm not sure if the class should contain such a state
# It seem wrong, on the other hand, I could not find another 'good' solution
var is_starving := false
var is_active := true
var is_build := false

enum FaceDirection {
	NorthWest,
	NorthEast,
	SouthEast,
	SouthWest,
}

var face_direction: FaceDirection = FaceDirection.SouthEast

func build():
	var current_scene = get_tree().current_scene
	if current_scene.has_node("EventBus"):
		event_bus = current_scene.get_node("EventBus")
		event_bus.send_selection_changed.connect(_on_event_bus_send_selection_changed)
		
	var area2d := $Area2D
	area2d.input_event.connect(_on_Area2d_input_event)
	area2d.mouse_entered.connect(_on_Area2d_mouse_entered)
	area2d.mouse_exited.connect(_on_Area2d_mouse_exited)
	
	var collisionPolygon := $"Area2D/CollisionPolygon2D"
	
	# 0N 1W 2S 3E
	var col_points = collisionPolygon.polygon
	
	col_points[0] *= height
	col_points[2] *= height
	
	col_points[1] *= width
	col_points[3] *= width
	
	collisionPolygon.polygon = col_points
	
	if height % 2 == 0:
		collisionPolygon.position.y -= 16 * height / 2
		
	is_build = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if is_build and is_selected:
				deselect()

func _on_Area2d_input_event(
	_viewport,
	event,
	_shape_idx
):
	if not is_selected and event.is_action_pressed("left_click"):
		print("selecting building")
		is_selected = true
		modulate = Color.YELLOW
		if event_bus != null:
			event_bus.send_building_selected.emit(self)

func _on_Area2d_mouse_entered():
	if not is_selected:
		modulate = Color.YELLOW

func _on_Area2d_mouse_exited():
	if not is_selected:
		modulate = Color.WHITE

func _on_event_bus_send_selection_changed(node):
	if !is_selected:
		return
	if node == self:
		return
	deselect()

func select():
	is_selected = true
	modulate = Color.YELLOW

func deselect():
	is_selected = false
	modulate = Color.WHITE
	
	event_bus.send_building_deselected.emit(self)
	
func show_starving_indicator():
	is_starving = true
	starving_sprite_2d.show()
	
func hide_starving_indicator():
	is_starving = false
	starving_sprite_2d.hide()
	
func show_production_stoppped_indicator():
	production_stopped_sprite_2d.show()
	is_active = false
	
func hide_production_stoppped_indicator():
	production_stopped_sprite_2d.hide()
	is_active = true

func switch_to_north_west_texture():
	#print("switch_to_north_west_texture")
	var building_data = datas.get(building_id)
	texture = building_data[Datas.TextureNorthWest]
	face_direction = FaceDirection.NorthWest
	
func switch_to_north_east_texture():
	#print("switch_to_north_east_texture")
	var building_data = datas.get(building_id)
	texture = building_data[Datas.TextureNorthEast]
	face_direction = FaceDirection.NorthEast
	
func switch_to_south_east_texture():
	#print("switch_to_south_east_texture")
	var building_data = datas.get(building_id)
	texture = building_data[Datas.TextureSouthEast]
	face_direction = FaceDirection.SouthEast
	
func switch_to_south_west_texture():
	#print("switch_to_south_west_texture")
	var building_data = datas.get(building_id)
	texture = building_data[Datas.TextureSouthWest]
	face_direction = FaceDirection.SouthWest

func get_height_offset() -> int:
	var building_data = datas.get(building_id)
	if building_data.has(Datas.HeightOffset):
		return building_data[Datas.HeightOffset]
	return 0

func get_width_offset() -> int:
	var building_data = datas.get(building_id)
	if building_data.has(Datas.WidthOffset):
		return building_data[Datas.WidthOffset]
	return 0

# This is for ECS
# FIXME: I'm not sure if this is the best
# The other node also keeps a reference
# But this way, we don't have to code a fetch method
var entity_node: Node
func set_entity_node(node: Node):
	entity_node = node
func get_entity_node() -> Node:
	return entity_node
