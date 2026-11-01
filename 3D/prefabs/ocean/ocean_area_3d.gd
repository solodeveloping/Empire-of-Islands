extends Area3D
class_name OceanArea3D

const RIPPLES_GPU_PARTICLES_3D = preload("uid://bpbicfti7i3ar")

@onready var ripples_gpu_particles_3d: GPUParticles3D = $RipplesGPUParticles3D

func _on_area_entered(area: Area3D) -> void:
	print("OceanArea3D:_on_area_entered %s" % [
		area.get_path(),
	])
	var target_node: BeachBall1
	#if area is BeachBall1:
		#target_node = area
	if area.get_parent() is BeachBall1:
		target_node = area.get_parent()
	if !target_node:
		return
	
	#print("spawn ripples")
	# WARN: this was not working, idk why
	#ripples_gpu_particles_3d.global_position = Vector3(
		#target_node.global_position.x,
		#self.global_position.y + 1,
		#target_node.global_position.z,
	#)
	#print("pos %s %s" % [
		#ripples_gpu_particles_3d.global_position,
		#target_node.global_position,
	#])
	#ripples_gpu_particles_3d.emitting = true
	
	var instance: GPUParticles3D = RIPPLES_GPU_PARTICLES_3D.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = Vector3(
		target_node.global_position.x,
		self.global_position.y + 0.01,
		target_node.global_position.z,
	)
	instance.emitting = true
	
	await get_tree().create_timer(3).timeout
	
	instance.queue_free()
	

func _on_area_exited(area: Area3D) -> void:
	print("OceanArea3D:_on_area_exited %s" % [
		area.get_path(),
	])
	#if area is BeachBall1:
		#pass
	var target_node: BeachBall1
	if area.get_parent() is BeachBall1:
		target_node = area.get_parent()
	
	if !target_node:
		return
	
	#print("spawn ripples")
	#ripples_gpu_particles_3d.global_position = Vector3(
		#target_node.global_position.x,
		#self.global_position.y + 1,
		#target_node.global_position.z,
	#)
	#print("pos %s %s" % [
		#ripples_gpu_particles_3d.global_position,
		#target_node.global_position,
	#])
	#ripples_gpu_particles_3d.emitting = true
	
	if !get_tree().current_scene.is_node_ready():
		print("!get_tree().current_scene.is_node_ready()")
		return
	
	# TODO: some problem here
	print("splash %s" % [
		Engine.get_physics_frames(),
	])
	var instance: GPUParticles3D = RIPPLES_GPU_PARTICLES_3D.instantiate()
	#get_tree().current_scene.add_child.call_deferred(instance)
	
	get_tree().current_scene.add_child(instance)
	instance.global_position = Vector3(
		target_node.global_position.x,
		self.global_position.y + 0.01,
		target_node.global_position.z,
	)
	instance.emitting = true
	
	await get_tree().create_timer(3).timeout
	
	instance.queue_free()
	
