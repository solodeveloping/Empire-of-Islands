extends Node
class_name LogMonitor

#static var monitored_ids: Set = Set.new()
static var monitored_ids: Dictionary[String, int]

static func add(id: String):
	#monitored_ids.add(id)
	monitored_ids.set(id, 0)

static func info(id: String, text: String, _data: Variant = null):
	if monitored_ids.has(id):
		#_data._print_all()
		Loggie.msg("Monitor: %s: %s" % [
			id,
			text,
		]).color(Color.LIGHT_SKY_BLUE).info()
