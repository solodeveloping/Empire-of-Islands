@tool
class_name SceneUtils
## Convenience utilities that manipulate scenes resources

static func get_or_create(parent: Node, name: String, type: Object) -> Node:
	if not parent:
		return null
	var result: Node = parent.find_child(name, false)
	if not result:
		result = create(parent, name, type)
	return result
	
	
static func create(parent: Node, name: String, type: Object) -> Node:
	if not parent:
		return null
	var owner = get_owner(parent)
	if not owner:
		return null
	var result = type.new()
	result.name = name
	add_child(parent, result)
	return result
	
	
static func add_child(parent: Node, child: Node, recursive: bool = true) -> Node:
	if not parent:
		return null
	parent.add_child(child)
	var owner = parent
	if Engine.is_editor_hint():
		var tree = parent.get_tree()
		if !tree:
			push_error("tree is null, parent %s must not be in the tree (child: %s)" % [
				parent.name,
				child.name,
			])
			return null
		owner = parent.get_tree().edited_scene_root
	set_owner(child, owner, recursive)
	return child
	
	
static func set_owner(node: Node, owner: Node, recursive: bool = true) -> void:
	node.set_owner(owner)
	if recursive:
		var all_children = node.get_children(true)
		for child in all_children:
			set_owner(child, owner)
		
		
static func get_owner(parent: Node):
	if Engine.is_editor_hint():
		var tree = parent.get_tree()
		if not tree:
			return null
		return tree.edited_scene_root
	return parent.get_scene()
		
		
static func remove(owner: Node, name: String) -> void:
	var node = owner.find_child(name, false)
	if node:
		owner.remove_child(node)

static func find_first_child_of_type_depth_first(parent: Node, type: Variant):
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child
		var inner_child = find_first_child_of_type_depth_first(child, type)
		if inner_child != null:
			return inner_child
	return null

static func find_first_parent_of_type(node: Node, type: Variant) -> Node:
	var parent_ = node.get_parent()
	while parent_:
		if is_instance_of(parent_, type):
			return parent_
		parent_ = parent_.get_parent()
	return null

static func find_all_child_of_type_depth_first(
	parent: Node,
	type: Variant,
	include_internal: bool = false,
) -> Array[Node]:
	var result: Array[Node] = []
	for child in parent.get_children(include_internal):
		if is_instance_of(child, type):
			result.push_back(child)
		var children = find_all_child_of_type_depth_first(child, type)
		result.append_array(children)
	return result

#static func get_edited_scene_root() -> Node:
#	if not Engine.is_editor_hint():
#		return null
#	return EditorScript.new().get_editor_interface().get_edited_scene_root()
