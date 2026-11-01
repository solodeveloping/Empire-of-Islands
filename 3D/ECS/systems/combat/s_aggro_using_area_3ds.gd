extends System
class_name AggroUsingArea3DsSystem

# Info: aggro using Area3Ds
# Because it's already relatively optimized

# Entities should be stored like this
# var entities_in_aggro_range: Dictionary[String, Entity]

var update_aggros_time: float = 0
var update_aggros_time_limit: float = 0.5

func _ready() -> void:
	update_aggros_time = 0

func sub_systems():
	return [
		[
			ECS.world.query.with_all([
				C_CanAggro,
			])\
			#.enabled()\
			.with_none([
				C_HasAggro,
				C_IsDeAggroing,
			])
			#.iterate([
				#C_CanAggro,
			#])\
			,
			verify_aggro
		],
	]	

func verify_aggro(
	entities: Array[Entity],
	_components: Array,
	delta: float,
):
	update_aggros_time -= delta
	if update_aggros_time > 0:
		return
	update_aggros_time = update_aggros_time_limit
	
	for i in entities.size():
		var entity: Entity = entities[i]
		if !("entities_in_aggro_range" in entity):
			printerr("!entities_in_aggro_range in entity")
			continue
		
		var entities_in_aggro_range: Dictionary[String, Entity] = entity.entities_in_aggro_range
		
		if entities_in_aggro_range.is_empty():
			print("no entities in aggro range")
			continue
		
		# FIXME: should we do the checks here?
		
		var r_faction = entity.get_relationship(
			Rels.belongs_to_faction
		)
		if r_faction == null:
			printerr("r_faction == null %s" % [
				entity.get_path(),
			])
			continue
		var c_faction: C_Faction = r_faction.target.get_component(
			C_Faction
		)
		
		# FIXME: check relationships here
		
		# TODO: aggro type
		# could take first
		
		var closest: Entity = null
		var closest_dist: float = 0
		for target_entity: Entity in entities_in_aggro_range.values():
			# FIXME: if C_IsDead or similar, maybe use that
			var c_health: C_Health = target_entity.get_component(
				C_Health
			)
			if c_health.current <= 0:
				continue
			
			var target_r_faction = target_entity.get_relationship(
				Rels.belongs_to_faction
			)
			if !target_r_faction:
				printerr("target has no faction %s" % [
					target_entity.name,
				])
				# TODO: check the time
				# could be at beginning
				continue
			
			var target_c_faction: C_Faction = target_r_faction.target.get_component(
				C_Faction
			)
			if target_c_faction.faction_id == c_faction.faction_id:
				# TODO: find a way to clear this
				#print("target is of the same faction %s %s %s %s" % [
					#entity.name,
					#target_entity.name,
					#c_faction.faction_id,
					#target_c_faction.faction_id,
				#])
				continue
			
			# TODO: aggressive units could have different stuff
			var relation: FactionRelationDef = c_faction.relationships[target_c_faction.faction_id]
			if relation.get_relation_type() != FactionRelationDef.RelationType.Hostile:
				print("relationship is not hostile %s %s %s" % [
					entity.name,
					target_entity.name,
					relation.relation_value,
				])
				continue
			
			if closest == null:
				closest = target_entity
				closest_dist = target_entity.global_position.distance_to(
					entity.global_position
				)
				continue
			
			var dist = target_entity.global_position.distance_to(
				entity.global_position
			)
			if dist < closest_dist:
				closest = target_entity
				closest_dist = dist
		
		if !closest:
			continue
			
		#print("%s aggroing %s" % [
			#entity.get_path(),
			#closest.get_path(),
		#])
		
		#entity.aggro_target = closest
		entity.set_meta("aggro_target", closest)
		#entity.set_meta("aggro_target", "test")
		if entity.has_method("display_has_aggro"):
			entity.display_has_aggro()
		
		cmd.add_component(
			entity,
			C_HasAggro.new(),
		)
		
		if entity.has_component(C_GainSpeedWhenAggroing):
			# TODO: something better
			# once we have slows
			var c_gain: C_GainSpeedWhenAggroing = entity.get_component(
				C_GainSpeedWhenAggroing
			)
			var c_movement: C_Movement = entity.get_component(
				C_Movement
			)
			c_movement.speed += c_gain.speed_gain
		
		
		# Info: this does not refresh
		# And it will continue to next path
		
		if entity.has_component(C_NavigationDestination):
			var c_dest: C_NavigationDestination = entity.get_component(
				C_NavigationDestination
			)
			c_dest.target = closest.global_position
		else:
			cmd.add_component(
				entity,
				C_NavigationDestination.new(closest.global_position)
			)
		
		if entity.has_component(C_CanDeAggro):
			#print("entity has C_CanDeAggro")
			#var c_deaggro: C_CanDeAggro = entity.get_component(
				#C_CanDeAggro
			#)
			# Reaggroing
			if entity.has_component(C_ComputeDeAggro):
				var c_compute: C_ComputeDeAggro = entity.get_component(
					C_ComputeDeAggro
				)
				c_compute.distance_travelled = 0
				c_compute.time_travelled = 0
				c_compute.original_position = entity.global_position
			else:
				cmd.add_component(
					entity,
					C_ComputeDeAggro.new(entity.global_position)
				)
		else:
			print("entity does not have deaggro")
		
