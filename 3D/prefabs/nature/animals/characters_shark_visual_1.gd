extends Node3D
class_name CharacterSharkVisual_1

@onready var animation_tree: AnimationTree = $AnimationTree

func play_swim():
	#animation_tree.set("")
	push_error("not implemented")
	pass

func play_attack():
	# Info: this is like a one shot
	animation_tree.set("parameters/conditions/attack", true)
	animation_tree.set_deferred("parameters/conditions/attack", false)
	#var state_machine = animation_tree["parameters/playback"]
	#state_machine.travel("Swim_Bite")

func play_death():
	push_error("not implemented")
	pass
