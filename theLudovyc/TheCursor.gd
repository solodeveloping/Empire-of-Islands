extends Node
class_name TheCursor

# if not null follow the cursor
var cursor_entity: Building2D
# avoid create building on first clic
var cursor_entity_wait_release: bool = false
