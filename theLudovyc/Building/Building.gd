@tool

extends EntityStatic
class_name Building2D

# Info : this is the script used to display all buildings
# the other scenes are not used

signal selected(type)

@onready var starving_sprite_2d: Sprite2D = $StarvingSprite2D
@onready var production_stopped_sprite_2d: Sprite2D = $ProductionStoppedSprite2D

enum Datas {Texture, Width, Height}

# We are using 1 frame atlas_texture for now
# When we have the appropriate buildings (sawmill)
# We can either replace the source of the AtlasTexture
# Or we can delete them and replace the placeholder texture with the right one
# In this case, we need to modify the number of VFrames in Building2D.tscn

const datas = {
	Buildings.Ids.Warehouse: {
		#Datas.Texture: preload("res://theLudovyc/Building/warehouse.png"),
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/warehouse_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
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
	Buildings.Ids.StonePit: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/stone_pit_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
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
	Buildings.Ids.WheatField: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/wheat_field_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
	Buildings.Ids.Pasture: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/pasture_atlas_texture.tres"),
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
	Buildings.Ids.Stonemason: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/stonemason_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.Windmill: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/windmill_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	# Level 3
	Buildings.Ids.House: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/stone_house_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.Bakery: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/stonemason_atlas_texture.tres"),
		Datas.Width: 2,
		Datas.Height: 2,
	},
	Buildings.Ids.Weaver: {
		Datas.Texture: preload("res://theLudovyc/Building/atlas_textures/weaver_atlas_texture.tres"),
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
				push_error("Cannot find datas for this id: " + str(building_id))
				return
			
			width = building_data[Datas.Width]
			height = building_data[Datas.Height]
			texture = building_data[Datas.Texture]
			
			update_offset()

var event_bus: EventBus

var is_selected := false

# FIXME : I'm not sure if the class should contain such a state
# It seem wrong, on the other hand, I could not find another 'good' solution
var is_starving := false
var is_active := true

func build():
	var current_scene = get_tree().current_scene
	if current_scene.has_node("EventBus"):
		event_bus = current_scene.get_node("EventBus")
		event_bus.send_building_selected.connect(_on_building_selected)
		event_bus.send_natural_resource_selected.connect(_on_building_selected)
		
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


func _on_Area2d_input_event(viewport, event, shape_idx):
	if not is_selected and event.is_action_pressed("alt_command"):
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


func _on_building_selected(building_node: Building2D):
	if is_selected and building_node != self:
		is_selected = false
		modulate = Color.WHITE

func _on_natural_resource_selected(_natural_resource):
	if is_selected:
		is_selected = false
		modulate = Color.WHITE

func select():
	is_selected = true
	modulate = Color.YELLOW


func deselect():
	is_selected = false
	modulate = Color.WHITE
	
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
