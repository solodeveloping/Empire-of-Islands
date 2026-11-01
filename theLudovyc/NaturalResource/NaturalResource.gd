@tool
extends EntityStatic
class_name NaturalResource

signal selected(type)

enum Datas {Texture, Width, Height}

const datas = {
	# TODO : pick one of them randomly
	NaturalResources.Ids.ClayDeposit: {
		Datas.Texture: preload("res://theLudovyc/NaturalResource/atlas_textures/clay_deposit_atlas_texture.tres"),
		Datas.Width: 3,
		Datas.Height: 3,
	},
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
#@onready var event_bus: EventBus = %EventBus

# FIXME : accessing %TheCursor is returning null
var the_cursor: TheCursor
#@onready var the_cursor: TheCursor = %TheCursor

var is_selected := false

func _ready() -> void:
	var current_scene = get_tree().current_scene
	if current_scene.has_node("EventBus"):
		event_bus = current_scene.get_node("EventBus")
		event_bus.send_selection_changed.connect(_on_event_bus_send_selection_changed)
	if current_scene.has_node("%TheCursor"):
		the_cursor = current_scene.get_node("%TheCursor")
	else:
		push_error("%TheCursor not found")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if is_selected:
				deselect()

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
	
	event_bus.send_natural_resource_deselected.emit(self)

func _on_Area2d_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if not is_selected and event.is_action_pressed("left_click"):
		select()
		if event_bus != null and the_cursor.cursor_entity == null:
			event_bus.send_natural_resource_selected.emit(self)

func _on_Area2d_mouse_entered() -> void:
	if not is_selected:
		modulate = Color.YELLOW

func _on_Area2d_mouse_exited() -> void:
	if not is_selected:
		modulate = Color.WHITE
