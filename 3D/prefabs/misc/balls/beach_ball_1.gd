extends RigidBody3D
class_name BeachBall1

@export
var ocean_impulse_force: float = 0.25

# FIXME: this is terrible
@onready var ripples_gpu_particles_3d: GPUParticles3D = $RipplesGPUParticles3D
#@onready var remote_transform_3d: RemoteTransform3D = $RipplesGPUParticles3D/RemoteTransform3D

# TODO: more than 1 sound
@onready var splash_audio_stream_player_3d: AudioStreamPlayer3D = $SplashAudioStreamPlayer3D

var is_inside_ocean: bool = false

var ocean_node: Node3D

func _physics_process(_delta: float) -> void:
	if !is_inside_ocean:
		return
	
	#print("apply_impulse")
	self.apply_impulse(
		Vector3.UP * ocean_impulse_force
	)

func _on_body_entered(_body: Node) -> void:
	#print("BeachBall1:_on_body_entered %s" % [
		#_body.get_path(),
	#])
	pass

func _on_body_exited(_body: Node) -> void:
	#print("BeachBall1:_on_body_exited %s" % [
		#_body.get_path(),
	#])
	pass


func _on_Area3d_area_entered(area: Area3D) -> void:
	#print("BeachBall1:_on_Area3d_area_entered %s" % [
		#area.get_path(),
	#])
	if area.has_meta("is_ocean"):
		is_inside_ocean = true
		ocean_node = area
		
		splash_audio_stream_player_3d.play()
		
		#ripples_gpu_particles_3d.rotation = -owner.rotation
		#remote_transform_3d.remote_path = area.get_path()
		#ripples_gpu_particles_3d.rotation = -get_parent().rotation
		#ripples_gpu_particles_3d.emitting = true
		
		return
	var parent = area.get_parent()
	if parent.has_meta("is_ocean"):
		is_inside_ocean = true
		ocean_node = parent
		
		splash_audio_stream_player_3d.play()
		
		#ripples_gpu_particles_3d.rotation = -owner.rotation
		#remote_transform_3d.remote_path = parent.get_path()
		#ripples_gpu_particles_3d.rotation = -get_parent().rotation
		#ripples_gpu_particles_3d.emitting = true

func _on_Area3d_area_exited(area: Area3D) -> void:
	#print("BeachBall1:_on_Area3d_area_exited %s" % [
		#area.get_path(),
	#])
	if area.has_meta("is_ocean"):
		is_inside_ocean = false
		ocean_node = null
		
		#ripples_gpu_particles_3d.rotation = -owner.rotation
		#remote_transform_3d.remote_path = area.get_path()
		#ripples_gpu_particles_3d.rotation = -get_parent().rotation
		#ripples_gpu_particles_3d.emitting = true
		
		return
	var parent = area.get_parent()
	if parent.has_meta("is_ocean"):
		is_inside_ocean = false
		ocean_node = null
		
		#ripples_gpu_particles_3d.rotation = -owner.rotation
		#remote_transform_3d.remote_path = parent.get_path()
		#ripples_gpu_particles_3d.rotation = -get_parent().rotation
		#ripples_gpu_particles_3d.emitting = true
