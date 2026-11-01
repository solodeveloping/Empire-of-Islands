extends Node3D
class_name  StartOneShotParticleVFX

# FIXME: HitVFX_1 is not that good

@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

func start():
	gpu_particles_3d.restart()
