extends Camera2D

const SPEED = 500

const Edge_Limit = 10

@export
var zoom_step := 0.1
@export
var min_zoom := 0.5
@export
var max_zoom := 3.0
@export
var is_movement_disabled: bool = false
@export
var is_changing_zoom_enabled: bool = true

var pos_limit_top_left: Vector2
var pos_limit_bot_right: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	
	var viewport_rect = get_viewport_rect()
	
	var dir: Vector2
	if mouse_pos.x < Edge_Limit:
		dir.x = -1
	
	if mouse_pos.x > viewport_rect.size.x - Edge_Limit:
		dir.x = 1
	
	if mouse_pos.y < Edge_Limit:
		dir.y = -1
	
	if mouse_pos.y > viewport_rect.size.y - Edge_Limit:
		dir.y = 1
	
	dir = dir.normalized()
	
	# FIXME: should have the same ones as for 3D
	if dir.length() == 0:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
	position += dir * SPEED * delta
	
	position.x = clamp(position.x, pos_limit_top_left.x, pos_limit_bot_right.x)
	position.y = clamp(position.y, pos_limit_top_left.y, pos_limit_bot_right.y)

func _unhandled_input(event: InputEvent) -> void:
	if is_movement_disabled:
		return
	if event is InputEventMouseButton:
		if is_changing_zoom_enabled:
			# TODO: replace with Input (input map)
			if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom += Vector2.ONE * zoom_step
			elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom -= Vector2.ONE * zoom_step
			
			zoom = zoom.clamp(
				Vector2.ONE * min_zoom,
				Vector2.ONE * max_zoom
			)
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("move_drag"):
			# TODO: 0.8 should be a variable
			global_position -= (event.relative / zoom) * 0.8
