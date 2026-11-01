extends Node3D
class_name SimpleCharacterVisual1

# FIXME: this is terrible
# What would be a "proper way"?
# If we use vertex animation, maybe nothing
# Could switch to vertex animation only if far-away though

#@onready var animation_tree: AnimationTree = $AnimationTree

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	pass
	# I needed this to debug an animation issue
	#animation_player.animation_changed.connect(
		#func test(old_name: StringName, new_name: StringName):
			#print("animation_changed %s %s" % [
				#old_name,
				#new_name,
			#])
	#)
	
	#print("SimpleCharacterVisual1:_ready")
	#animation_tree.set("parameters/conditions/walk_run", true)
	#animation_tree.set("parameters/WalkRun/blend_position", 1.0)

#func _process(delta: float) -> void:
	#print("curret anim %s" % [
		#animation_player.an
	#])

func play_walk():
	animation_player.play("animation_library_standard/Walk")

func play_idle():
	animation_player.play("animation_library_standard/Idle")

func play_swim_idle():
	#print("play_swim_idle")
	animation_player.play("animation_library_standard/Swim_Idle")

func play_death():
	animation_player.play("animation_library_standard/Death01")

#func play_walk():
	##print("play_walk")
	#if animation_tree.get("parameters/conditions/walk_run") == true:
		#return
	#animation_tree.set("parameters/conditions/stop_walk_run", false)
	#animation_tree.set("parameters/conditions/walk_run", true)
	#
#func play_idle():
	##print("play_idle")
	#if animation_tree.get("parameters/conditions/walk_run") == false:
		#return
	#animation_tree.set("parameters/conditions/walk_run", false)
	#animation_tree.set("parameters/conditions/stop_walk_run", true)
#
## FIXME: so bad
#func play_water_idle():
	#animation_tree.set("parameters/conditions/walk_run", false)
	#animation_tree.set("parameters/conditions/stop_walk_run", false)
	#animation_tree.set("parameters/conditions/swim_idle", true)
	#animation_tree.set("parameters/conditions/stop_swim_idle", false)
#
#func play_death():
	#animation_tree.set("parameters/conditions/is_dead", true)

func _on_AnimationPlayer_animation_changed(
	old_name: StringName,
	new_name: StringName
) -> void:
	print("_on_AnimationPlayer_animation_changed %s %s" % [
		old_name,
		new_name,
	])

func _on_AnimationPlayer_current_animation_changed(
	anim_name: StringName
) -> void:
	print("_on_AnimationPlayer_current_animation_changed %s" % [
		anim_name,
	])

func _on_AnimationPlayer_animation_finished(
	anim_name: StringName
) -> void:
	print("_on_AnimationPlayer_animation_finished %s" % [
		anim_name,
	])
