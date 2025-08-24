@tool
extends EntityStatic
class_name NaturalResource

signal selected(type)

enum Datas {Texture, Width, Height}

const datas = {
	NaturalResources.Ids.StoneDeposit: {
		Datas.Texture: preload("res://theLudovyc/NaturalResource/atlas_textures/stone_deposit_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
}

var natural_resource_id: NaturalResources.Ids = -1:
	set(p_natural_resource_id):
		if p_natural_resource_id != natural_resource_id:
			natural_resource_id = p_natural_resource_id
			
			var data = datas.get(natural_resource_id)
			
			if data == null:
				push_error("Cannot find datas for this id: " + str(natural_resource_id))
				return
			
			width = data[Datas.Width]
			height = data[Datas.Height]
			texture = data[Datas.Texture]
			
			update_offset()

var event_bus: EventBus

# FIXME : accessing %TheCursor is returning null
var the_cursor: TheCursor

var is_selected := false

func _ready() -> void:
	var current_scene = get_tree().current_scene
	if current_scene.has_node("EventBus"):
		event_bus = current_scene.get_node("EventBus")
		event_bus.send_natural_resource_selected.connect(_on_natural_resource_selected)
		event_bus.send_building_selected.connect(_on_building_selected)
	if current_scene.has_node("TheCursor"):
		the_cursor = current_scene.get_node("TheCursor")

func _on_natural_resource_selected(natural_resource: NaturalResource):
	if is_selected and natural_resource != self:
		is_selected = false
		modulate = Color.WHITE
		
func _on_building_selected(_building):
	if is_selected:
		is_selected = false
		modulate = Color.WHITE

func select():
	is_selected = true
	modulate = Color.YELLOW

func deselect():
	is_selected = false
	modulate = Color.WHITE

func _on_Area2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not is_selected and event.is_action_pressed("alt_command"):
		is_selected = true
		modulate = Color.YELLOW
		if event_bus != null and the_cursor.cursor_entity == null:
			event_bus.send_natural_resource_selected.emit(self)

func _on_Area2d_mouse_entered() -> void:
	if not is_selected:
		modulate = Color.YELLOW

func _on_Area2d_mouse_exited() -> void:
	if not is_selected:
		modulate = Color.WHITE
