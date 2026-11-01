extends Node3D
class_name BasicFloatingTextIndicator_1

@onready var label_3d: Label3D = $Label3D

func start_tween():
	#await get_tree().create_timer(2.0).timeout
	var tween = create_tween()
	tween.tween_property(
		self,
		#"global_position",
		"position",
		position + Vector3(
			#randf_range(-1, 1),
			0,
			3,
			0,
			#randf_range(-1, 1)
		),
		#2,
		1.5,
	)#\
	#.from_current()
	#.as_relative().from_current()
	#.from_current().as_relative()
	tween.tween_callback(self.queue_free)

func set_text(text: String):
	print("set_text %s" % [
		text,
	])
	label_3d.text = text

func do_queue_free():
	print("do_queue_free %s" % [
		self.global_position,
	])
	#queue_free()
