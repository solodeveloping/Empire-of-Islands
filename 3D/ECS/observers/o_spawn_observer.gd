extends Observer
class_name O_SpawnObserver

# FIXME: could use an event system to obtain them?
var faction_entities: Array[Entity] = []
var faction_entities_dict: Dictionary[int, Entity] = {}

# TODO: maybe we could make a collection system
@export
var spawn_list_by_tag_list: Array[SpawnListByTag] = []
var spawn_list_by_tag_dict: Dictionary[String, SpawnListByTag] = {}

func sub_observers() -> Array[Array]:
	return [
		[
			q.with_any([C_ForECSEvents])
			.on_event(ECSEvents.SPAWN_ENTITIES_REQUESTED),
			_on_spawn_entities_requested
		],
	]

func _ready() -> void:
	print("O_SpawnObserver:_ready")
	spawn_list_by_tag_dict.clear()
	for spawn in spawn_list_by_tag_list:
		if spawn.list.is_empty():
			printerr("spawn.list is_empty")
		
		var spawn_list_by_tag: SpawnListByTag
		if spawn_list_by_tag_dict.has(spawn.tag):
			spawn_list_by_tag = spawn_list_by_tag_dict.get(
				spawn.tag
			)
		else:
			spawn_list_by_tag = SpawnListByTag.new()
			spawn_list_by_tag_dict.set(
				spawn.tag,
				spawn_list_by_tag,
			)
		
		spawn_list_by_tag.tag = spawn.tag
		spawn_list_by_tag.list.append_array(
			spawn.list
		)
	
func set_faction_entities(
	faction_entities_: Array[Entity]
):
	faction_entities = faction_entities_
	faction_entities_dict.clear()
	for entity in faction_entities:
		var c_faction: C_Faction = entity.get_component(
			C_Faction
		)
		faction_entities_dict.set(
			c_faction.faction_id,
			entity
		)

func get_scene_by_tag(tag: String) -> PackedScene:
	if !spawn_list_by_tag_dict.has(tag):
		printerr("could not find tag %s" % [
			tag,
		])
		return null
	var spawn_list_by_tag: SpawnListByTag = spawn_list_by_tag_dict.get(
		tag
	)
	return spawn_list_by_tag.list.pick_random()

func _on_spawn_entities_requested(
	_event: Variant,
	_entity: Entity,
	_data: Variant
) -> void:
	# FIXME : IDK how to handle respawns but I don't have the use case yet
	var entities = Queries.find_spawns()
	for spawn: Entity in entities:
		var c_spawn_by_tag: C_SpawnByTag = spawn.get_component(
			C_SpawnByTag
		)
		if c_spawn_by_tag:
			var scene = get_scene_by_tag(c_spawn_by_tag.tag)
			var instance: Entity = scene.instantiate()
			instance.hide()
			ECS.world.add_entity(instance)
			
			var faction = faction_entities_dict.get(
				c_spawn_by_tag.faction_id
			)
			if !faction:
				printerr("C_SpawnByTag faction not found %s" % [
					c_spawn_by_tag.faction_id,
				])
				continue
			
			#var rel = Rels.create_belongs_to_faction(
				#faction,
			#)
			#var lambda = func my_lambda():
				#instance.add_relationship(
					#rel
				#)
			#cmd.add_custom(lambda)
			
			cmd.add_relationship(
				instance,
				Rels.create_belongs_to_faction(
					faction,
				)
			)
			
			var _spawn = spawn as Variant as Path3D
			if _spawn:
				#print("spawn is Path3D")
				var point_index = randi_range(
					0,
					_spawn.curve.point_count - 1,
				)
				var point = _spawn.curve.get_point_position(
					point_index
				)
				
				var y_offset: float = 0
				if instance.has_node("NavigationAgent3D"):
					#print("has NavigationAgent3D")
					var nav_agent: NavigationAgent3D = instance.get_node("NavigationAgent3D")
					y_offset = -nav_agent.path_height_offset
				
				instance.global_position = point
				instance.global_position.y += y_offset
				
				#print("spawning %s at %s - %s %s" % [
					#instance.get_path(),
					#instance.global_position,
					#point,
					#_spawn.global_position,
				#])
				
				instance.show()
				
				#print("instance.global_position %s %s" % [
					#instance.global_position,
					#point,
				#])
				
				point_index += 1
				if point_index >= _spawn.curve.point_count:
					point_index = 0
				
				var target = _spawn.curve.get_point_position(
					point_index
				)
				
				instance.set_meta("path_3d_node", _spawn)
				
				cmd.add_component(
					instance,
					C_FollowPath.new(
						point_index
					)
				)
				
				cmd.add_component(
					instance,
					C_NavigationDestination.new(
						target,
					)
				)
				
			
			# TODO: pop_unit stuff if it's appropriate (maybe)
			
