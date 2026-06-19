extends Node
class_name NodeUtils

static func remove_all_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
