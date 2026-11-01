extends Node3D
class_name MinimapEntityDisplayHandler

@export
var white_icon: MeshInstance3D

func update_display(
	entity: Entity
):
	var r_faction = entity.get_relationship(
		Rels.belongs_to_faction
	)
	if !r_faction:
		# FIXME: is this an error?
		#print("no faction")k
		white_icon.set_instance_shader_parameter(
			"Color",
			Color.WHITE,
		)
		return
	
	var c_faction: C_Faction = r_faction.target.get_component(
		C_Faction
	)
	
	if c_faction.faction_id == StaticFactions.local_player_faction_id:
		#print("minimap: assigning blue")
		white_icon.set_instance_shader_parameter(
			"Color",
			Color.BLUE,
		)
	else:
		#print("minimap: assigning white")
		# TODO: godot does not notify if this is not working
		white_icon.set_instance_shader_parameter(
			"Color",
			Color.WHITE,
		)
		
	
