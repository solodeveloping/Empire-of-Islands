extends Node
class_name NodeUtils

static func remove_all_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)

static func hide_other_children(
	parent_: Node,
	node: Node,
):
	for child in parent_.get_children():
		if child == node:
			continue
		child.hide()
