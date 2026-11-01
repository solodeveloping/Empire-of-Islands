extends System
class_name AggroUsingSpatialBinningSystem

# FIXME?
# Info: not using it currently

@export
var spatial_binning_system: SpatialBinningSystem

var update_aggros_time: float = 0
var update_aggros_time_limit: float = 0.5

func _ready() -> void:
	update_aggros_time = 0

# FIXME: won't scale?
# Because if there are a bunch of trees, they are all in the search

# TODO: maybe try to use the Godot Physics Server otherwise

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_IsInSpatialBin,
				C_Movement,
			])\
			#.enabled()\
			.iterate([
				C_IsInSpatialBin,
				C_Movement,
			])\
			,
			verify_aggro
		],
	]	

func verify_aggro(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	update_aggros_time -= delta
	if update_aggros_time > 0:
		return
	update_aggros_time = update_aggros_time_limit
	
	# FIXME: not implemented
	for i in entities.size():
		pass
