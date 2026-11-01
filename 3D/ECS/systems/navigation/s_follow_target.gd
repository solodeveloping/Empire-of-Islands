extends System
class_name FollowTargetSystem

var update_time: float = 0
var update_time_limit: float = 0.5

var assign_dest_time: float = 0
var assign_dest_limit: float = 0.5

func _ready() -> void:
	update_time = 0
	assign_dest_time = 0

func sub_systems():
	return [
		[
			# Info: the C_NavigationDestination is cleared on reach
			# some units won't have a reassign without this
			ECS.world.query.with_all([
				C_HasAggro,
				C_Movement,
			])\
			.with_none([
				C_NavigationDestination
			])
			#.iterate([
				##C_HasAggro,
				##C_Movement,
				#C_NavigationDestination,
			#])
			,
			assign_target_destinations
		],
		[
			ECS.world.query.with_all([
				C_HasAggro,
				C_Movement,
				C_NavigationDestination,
			])\
			.iterate([
				#C_HasAggro,
				#C_Movement,
				C_NavigationDestination,
			])
			,
			update_target_positions
		],
	]

func assign_target_destinations(
	entities: Array[Entity],
	_components: Array,
	delta: float
):
	assign_dest_time -= delta
	if assign_dest_time > 0:
		return
	assign_dest_time = assign_dest_limit
	
	#print("update_target_positions %s" % [
		#entities.size(),
	#])
	
	for i in entities.size():
		var entity: Entity = entities[i]
		if !entity.has_meta("aggro_target"):
			printerr("!entity.has_meta('aggro_target')")
			continue
		
		var dest = entity.get_meta("aggro_target")
		
		cmd.add_component(
			entity,
			C_NavigationDestination.new(dest.global_position)
		)
		

func update_target_positions(
	entities: Array[Entity],
	components: Array,
	delta: float
):
	update_time -= delta
	if update_time > 0:
		return
	update_time = update_time_limit
	
	#print("update_target_positions %s" % [
		#entities.size(),
	#])
	
	var C_NavigationDestination_Index: int = 0
	
	for i in entities.size():
		var entity: Entity = entities[i]
		var c_dest: C_NavigationDestination = components[C_NavigationDestination_Index][i]
		if !entity.has_meta("aggro_target"):
			printerr("!entity.has_meta('aggro_target')")
			continue
		
		var dest = entity.get_meta("aggro_target")
		c_dest.target = dest.global_position
