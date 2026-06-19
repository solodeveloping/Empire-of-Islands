extends Node
class_name TimeUtils

static func call_at_interval(node: Node, time_seconds: float, callable: Callable):
	# TODO : call on physics time?
	var timer = Timer.new()
	timer.wait_time = time_seconds
	timer.timeout.connect(callable)
	timer.autostart = true
	node.add_child(timer)
