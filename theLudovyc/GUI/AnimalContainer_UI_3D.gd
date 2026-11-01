extends VBoxContainer
class_name AnimalContainerUI3D

@onready var faction_texture_rect: TextureRect = $CenterContainer/HBoxContainer2/FactionTextureRect
@onready var faction_name_label: Label = $CenterContainer/HBoxContainer2/FactionNameLabel

@onready var relationship_label: Label = $RelationshipLabel

# FIXME: maybe use richtext instead
@onready var name_label = $HBoxContainer/NameLabel
@onready var flag_texture_rect: TextureRect = $HBoxContainer/FlagTextureRect

@onready var health_label: Label = $UnitInfoContainer/UnitDefaultContainer/HealthLabel

@onready var event_bus: EventBus

# FIXME: could be an option eventually
const confirmation_text = "Are you sure you want to kill this unit?"

func _ready():
	event_bus = get_tree().current_scene.get_node_or_null("EventBus")

func update_infos(
	unit: Entity,
	local_player_faction_id: int,
):
	var c_name: C_Name = unit.get_component(C_Name)

	name_label.text = c_name.name_
	
	var r_faction = unit.get_relationship(Rels.belongs_to_faction)
	if !r_faction:
		printerr("animal does not have a faction")
		return
	
	# TODO: check nationality assigned to entity?
	
	var c_faction: C_Faction = r_faction.target.get_component(C_Faction)
	if c_faction.def.custom_flag:
		faction_texture_rect.show()
		faction_texture_rect.texture = c_faction.def.custom_flag
		
		flag_texture_rect.hide()
	else:
		# TODO: faction flag color
		flag_texture_rect.show()
		flag_texture_rect.texture = c_faction.def.nationalities[0].flag_texture
		flag_texture_rect.tooltip_text = c_faction.def.nationalities[0].name
	
	# TODO: handle own
	
	var rel = c_faction.get_relationship(
		local_player_faction_id
	)
	relationship_label.text = rel.get_relation_type_as_string()
	
	# TODO: mutualize and have a setting
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
	relationship_label.add_theme_color_override(
		"font_color",
		color
	)
	
	var c_health: C_Health = unit.get_component(C_Health)
	health_label.text = "Health: %s/%s" % [
		c_health.current,
		c_health.maximum,
	]
	
	#gold_label.text = "Gold: %s" % [
		#c_storage.gold_count,
	#]
