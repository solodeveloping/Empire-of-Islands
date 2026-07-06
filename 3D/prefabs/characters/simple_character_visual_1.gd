extends Node3D
class_name SimpleCharacterVisual1

@onready var animation_tree: AnimationTree = $AnimationTree

func _ready() -> void:
	print("SimpleCharacterVisual1:_ready")
	animation_tree.set("parameters/conditions/walk_run", true)
	animation_tree.set("parameters/WalkRun/blend_position", 1.0)

func play_walk():
	#print("play_walk")
	if animation_tree.get("parameters/conditions/walk_run") == true:
		return
	animation_tree.set("parameters/conditions/stop_walk_run", false)
	animation_tree.set("parameters/conditions/walk_run", true)
	
func play_idle():
	#print("play_idle")
	if animation_tree.get("parameters/conditions/walk_run") == false:
		return
	animation_tree.set("parameters/conditions/walk_run", false)
	animation_tree.set("parameters/conditions/stop_walk_run", true)
