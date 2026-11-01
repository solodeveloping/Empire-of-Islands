extends CenterContainer
class_name SimpleShipFloatingUI_1

@onready var faction_flag_texture_rect: TextureRect = $VBoxContainer/HBoxContainer/FactionFlagTextureRect

@onready var name_label: Label = $VBoxContainer/HBoxContainer/NameLabel

@onready var health_progress_bar: ProgressBar = $VBoxContainer/HealthProgressBar

func set_content(
	entity: Entity,
	local_player_faction_id: int,
):
	var c_name: C_Name = entity.get_component(
		C_Name
	)
	if c_name:
		name_label.text = c_name.name_
	
	# FIXME: a lot is duplicated
	
	var r_faction = entity.get_relationship(
		Rels.belongs_to_faction
	)
	if !r_faction:
		push_error("ship does not have a faction %s" % [
			entity.get_path(),
		])
		return
	
	var c_faction: C_Faction = r_faction.target.get_component(
		C_Faction
	)
	
	# TODO: handle no name?
	#faction_name_label.text = c_faction.def.faction_name
	
	if c_faction.def.custom_flag:
		faction_flag_texture_rect.show()
		faction_flag_texture_rect.texture = c_faction.def.custom_flag
		
		#flag_texture_rect.hide()
	else:
		# TODO: faction flag color
		faction_flag_texture_rect.show()
		faction_flag_texture_rect.texture = c_faction.def.nationalities[0].flag_texture
		faction_flag_texture_rect.tooltip_text = c_faction.def.nationalities[0].name
	
	var rel = c_faction.get_relationship(
		local_player_faction_id
	)
	
	# TODO: handle own ships
	
	#relationship_label.text = rel.get_relation_type_as_string()
	var color: Color = Color.WHITE
	var rel_type = rel.get_relation_type()
	match rel_type:
		FactionRelationDef.RelationType.Hostile:
			color = Color.RED
		FactionRelationDef.RelationType.Unfriendly:
			color = Color.ORANGE
		FactionRelationDef.RelationType.Neutral:
			color = Color.WHITE
		FactionRelationDef.RelationType.Friendly:
			color = Color.GREEN
		FactionRelationDef.RelationType.Honored:
			color = Color.PURPLE
	
	name_label.add_theme_color_override(
		"font_color",
		color
	)
	#faction_name_label.add_theme_color_override(
		#"font_color",
		#color
	#)
	
	var c_health: C_Health = entity.get_component(
		C_Health
	)
	if c_health:
		# TODO: coult precompute this in C_Health
		var progress = c_health.current / c_health.maximum * 100
		health_progress_bar.value = progress
	else:
		health_progress_bar.value = 100
