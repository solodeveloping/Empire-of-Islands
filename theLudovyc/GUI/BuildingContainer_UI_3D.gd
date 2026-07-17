extends VBoxContainer

@onready var faction_texture_rect: TextureRect = $CenterContainer/HBoxContainer2/FactionTextureRect
@onready var faction_name_label: Label = $CenterContainer/HBoxContainer2/FactionNameLabel

@onready var name_label = $HBoxContainer/NameLabel

@onready var building_info_container = $BuildingInfoContainer

@onready var event_bus: EventBus

@onready var confirmation_dialog := %ConfirmationDialog

const confirmation_text = "Are you sure you want to demolish this building?"

func _ready():
	event_bus = get_tree().current_scene.get_node_or_null("EventBus")

func update_infos(building: Entity):
	var c_building: C_Building = building.get_component(
		C_Building
	)
	var building_id = c_building.building_type
	
	var r_faction = building.get_relationship(Rels.belongs_to_faction)
	var c_faction: C_Faction = r_faction.target.get_component(
		C_Faction
	)
	if c_faction.def.custom_flag:
		faction_texture_rect.texture = c_faction.def.custom_flag
	else:
		faction_texture_rect.texture = c_faction.def.nationalities[0].flag_texture
	if c_faction.def.faction_name:
		faction_name_label.text = c_faction.def.faction_name
	else:
		faction_name_label.text = c_faction.def.nationalities[0].name + " (default)"
	
	name_label.text = Buildings.get_building_name(building_id)

	building_info_container.update_infos(building_id, building)

func _on_DeleteButton_pressed():
	confirmation_dialog.canceled.connect(_on_ConfirmationDialog_canceled)
	confirmation_dialog.confirmed.connect(_on_ConfirmationDialog_confirmed)
	confirmation_dialog.dialog_text = confirmation_text
	confirmation_dialog.popup_centered()

func _on_ConfirmationDialog_canceled():
	confirmation_dialog.canceled.disconnect(_on_ConfirmationDialog_canceled)
	confirmation_dialog.confirmed.disconnect(_on_ConfirmationDialog_confirmed)

func _on_ConfirmationDialog_confirmed():
	confirmation_dialog.canceled.disconnect(_on_ConfirmationDialog_canceled)
	confirmation_dialog.confirmed.disconnect(_on_ConfirmationDialog_confirmed)

	if event_bus != null:
		event_bus.ask_demolish_current_building.emit()
