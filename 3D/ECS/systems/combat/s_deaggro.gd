extends System
class_name DeAggroSystem

var update_time: float = 0
var update_time_limit: float = 0.5

func _ready() -> void:
	update_time = 0

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_HasAggro,
				C_CanDeAggro,
				C_ComputeDeAggro,
			])\
			.with_none([
				C_IsDeAggroing,
			])
			#.enabled()\
			.iterate([
				C_CanDeAggro,
				C_ComputeDeAggro,
			])\
			,
			compute_deaggro
		],
	]	

# TODO: something perf
	#update_time -= delta
	#if update_time > 0:
		#return
	#update_time = update_time_limit
	
	#print("compute_deaggro")

func compute_deaggro(
	entities: Array[Entity],
	components: Array,
	delta: float,
):
	#print("compute_deaggro %s" % [
		#Engine.get_physics_frames(),
	#])
	var C_CanDeAggro_Index: int = 0
	var C_ComputeDeAggro_Index: int = 1
	
	for i in entities.size():
		var entity: Entity = entities[i]
		var c_can_aggro: C_CanDeAggro = components[C_CanDeAggro_Index][i]
		var c_compute: C_ComputeDeAggro = components[C_ComputeDeAggro_Index][i]

		var start_deaggro: bool = false

		if c_can_aggro.can_deaggro_by_time:
			c_compute.time_travelled += delta
			if c_compute.time_travelled > c_can_aggro.max_aggro_time:
				#print("deaggro time_travelled %s %s" % [
					#c_compute.time_travelled,
					#c_can_aggro.max_aggro_time,
				#])
				start_deaggro = true
		
		if c_can_aggro.can_deaggro_by_distance_travelled:
			var last_dist: float = c_compute.last_position.distance_to(
				entity.global_position
			)
			c_compute.distance_travelled += last_dist
			c_compute.last_position = entity.global_position
			if c_compute.distance_travelled > c_can_aggro.max_distance_travelled:
				print("deaggro can_deaggro_by_distance_travelled %s" % [
					c_compute.distance_travelled,
					c_can_aggro.max_distance_travelled,
				])
				start_deaggro = true
		
		if c_can_aggro.can_deaggro_by_distance_to_starting_point:
			var dist: float = c_compute.original_position.distance_to(
				entity.global_position
			)
			if dist > c_can_aggro.max_distance_to_starting_point:
				print("deaggro max_distance_to_starting_point %s %s" % [
					dist,
					c_can_aggro.max_distance_to_starting_point,
				])
				start_deaggro = true
		
		if start_deaggro == false:
			continue
		
		print("is deaggroing %s" % [
			entity.get_path(),
		])
		
		# FIXME: feels duplicated with combat
		# TODO: something to join back paths
		if entity.has_component(C_NavigationDestination):
			var c_dest: C_NavigationDestination = entity.get_component(
				C_NavigationDestination
			)
			c_dest.target = c_compute.original_position
		else:
			cmd.add_component(
				entity,
				C_NavigationDestination.new(c_compute.original_position)
			)
		
		entity.remove_meta("aggro_target")
		
		cmd.remove_component(
			entity,
			C_ComputeDeAggro,
		)
		#if entity.has_component(C_IsDeAggroing):
			#print("entity has C_IsDeAggroing %s" % [
				#entity.get_path(),
			#])
		#print("adding C_IsDeAggroing %s %s %s" % [
			#entity.get_path(),
			#Engine.get_physics_frames(),
			#c_compute.original_position,
		#])
		cmd.add_component(
			entity,
			C_IsDeAggroing.new()
		)
		cmd.remove_component(
			entity,
			C_HasAggro,
		)
		# TODO: way of removing it when is back
		if entity.has_component(C_GainSpeedWhenAggroing):
			#print("diminish speed")
			var c_gain: C_GainSpeedWhenAggroing = entity.get_component(
				C_GainSpeedWhenAggroing
			)
			var c_movement: C_Movement = entity.get_component(
				C_Movement
			)
			c_movement.speed -= c_gain.speed_gain
		
		
