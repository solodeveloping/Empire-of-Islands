@tool
extends Entity

@onready var sphere_puff_vfx_1: StartOneShotParticleVFX = $SpherePuffVfx1
@onready var loot_sparks_vfx_1: Node3D = $LootSparksVfx1

@onready var area_3d: Area3D = $Area3D

@onready var barrel_2: Node3D = $Barrel2

@onready var sphere_outline_fresnel_vfx_1: Node3D = $SphereOutlineFresnelVfx1

# TODO: could have different depending on quantity
@onready var gold_looted_audio_stream_player_3d: AudioStreamPlayer3D = $GoldLootedAudioStreamPlayer3D
@onready var default_looted_audio_stream_player_3d_2: AudioStreamPlayer3D = $DefaultLootedAudioStreamPlayer3D2

func _ready() -> void:
	#sphere_outline_fresnel_vfx_1.hide()
	pass

func play_looted():
	#print("play_looted")
	sphere_puff_vfx_1.start()
	loot_sparks_vfx_1.hide()
	await get_tree().create_timer(0.7).timeout
	barrel_2.hide()

func play_gold_looted_sfx():
	gold_looted_audio_stream_player_3d.play()

func play_default_looted_sfx():
	default_looted_audio_stream_player_3d_2.play()

func disable_physics():
	#print("disable_physics")
	area_3d.monitorable = false
	area_3d.monitoring = false
	self.collision_layer = 0

func show_mouse_over():
	#print("show_mouse_over")
	sphere_outline_fresnel_vfx_1.show()

func hide_mouse_over():
	#print("hide_mouse_over")
	sphere_outline_fresnel_vfx_1.hide()
