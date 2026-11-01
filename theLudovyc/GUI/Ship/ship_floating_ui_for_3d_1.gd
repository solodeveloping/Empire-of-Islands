@tool
extends MarginContainer
class_name ShipFloatingUIFor3D_1

# FIXME: I think it's used for the 2D too

@export_tool_button("change_text_font_sizes")
var change_text_font_sizes = _change_text_font_sizes

@export
var text_font_size: int = 250

@onready var name_label: Label = $MarginContainer/VBoxContainer/CenterContainer/HBoxContainer/NameLabel

@onready var faction_flag_texture_rect: TextureRect = $MarginContainer/VBoxContainer/CenterContainer2/HBoxContainer/FactionFlagTextureRect

@onready var faction_name_label: Label = $MarginContainer/VBoxContainer/CenterContainer2/HBoxContainer/FactionNameLabel

@onready var health_progress_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthProgressBar

@onready var gold_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/GoldLabel

@onready var current_storage_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/CurrentStorageLabel

@onready var passenger_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PassengerLabel

@onready var cannon_count_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/CannonCountLabel

func _ready() -> void:
	print("ShipFloatingUI_1:_ready %s %s" % [
		name_label.get_theme_font_size("font_size"),
		get_path(),
	])

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
		push_error("ship does not have a faction")
		return
	
	var c_faction: C_Faction = r_faction.target.get_component(
		C_Faction
	)
	
	# TODO: handle no name?
	faction_name_label.text = c_faction.def.faction_name
	
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
	faction_name_label.add_theme_color_override(
		"font_color",
		color
	)
	
	var c_health: C_Health = entity.get_component(
		C_Health
	)
	if c_health:
		# TODO: coult precompute this in C_Health
		var progress = c_health.current / c_health.maximum * 100
		health_progress_bar.value = progress
	else:
		health_progress_bar.value = 100
	
	var c_pop: C_ShipPopulation = entity.get_component(
		C_ShipPopulation
	)
	if c_pop:
		passenger_label.text = "%s" % [
			c_pop.current
		]
	else:
		passenger_label.text = "0"
	
	# TODO: handle space and weight
	
	var c_storage: C_CargoStorage = entity.get_component(
		C_CargoStorage
	)
	if c_storage:
		current_storage_label.text = "%s" % [
			#c_storage.storage.size(),
			c_storage.weight,
		]
		gold_label.text = "%s" % [
			c_storage.gold_count,
		]
	else:
		current_storage_label.text = "0"
		gold_label.text = "0"
	
	# TODO: cannons
	cannon_count_label.text = "0"
	

func _change_text_font_sizes():
	name_label.add_theme_font_size_override(
		"font_size",
		text_font_size,
	)
	faction_name_label.add_theme_font_size_override(
		"font_size",
		text_font_size,
	)
	
	gold_label.add_theme_font_size_override(
		"font_size",
		text_font_size,
	)
	current_storage_label.add_theme_font_size_override(
		"font_size",
		text_font_size,
	)
	passenger_label.add_theme_font_size_override(
		"font_size",
		text_font_size,
	)
	cannon_count_label.add_theme_font_size_override(
		"font_size",
		text_font_size,
	)
