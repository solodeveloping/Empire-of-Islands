extends VBoxContainer
class_name ShipContainerUI3D

const SHIP_STORAGE_ITEM_UI = preload("uid://c4ff10n77vegm")

# FIXME: maybe use richtext instead
@onready var name_label = $HBoxContainer/NameLabel
@onready var flag_texture_rect: TextureRect = $HBoxContainer/FlagTextureRect

@onready var confirmation_dialog := %ConfirmationDialog

@onready var health_label: Label = $UnitInfoContainer/UnitDefaultContainer/HealthLabel
@onready var population_label: Label = $UnitInfoContainer/UnitDefaultContainer/PopulationLabel
@onready var weight_label: Label = $UnitInfoContainer/UnitDefaultContainer/WeightLabel
@onready var space_label: Label = $UnitInfoContainer/UnitDefaultContainer/SpaceLabel

@onready var gold_label: Label = $VBoxContainer/GoldLabel

@onready var cargo_grid_container: GridContainer = $VBoxContainer/CargoGridContainer

@onready var event_bus: EventBus

# FIXME: could be an option eventually
const confirmation_text = "Are you sure you want to kill this unit?"

func _ready():
	event_bus = get_tree().current_scene.get_node_or_null("EventBus")

func update_infos(unit: Entity):
	var c_name: C_Name = unit.get_component(C_Name)

	name_label.text = c_name.name_
	
	var r_faction = unit.get_relationship(Rels.belongs_to_faction)
	var c_nationality: C_Nationality = unit.get_component(C_Nationality)
	if c_nationality:
		flag_texture_rect.show()
		flag_texture_rect.texture = c_nationality.nationality.flag_texture
		flag_texture_rect.tooltip_text = c_nationality.nationality.name
	else:
		if r_faction:
			var c_faction: C_Faction = r_faction.target.get_component(C_Faction)
			flag_texture_rect.show()
			# TODO: faction flag
			#flag_texture_rect.texture = c_faction.def.nationality.flag_texture
			flag_texture_rect.tooltip_text = c_faction.def.nationality.name
		else:
			flag_texture_rect.hide()
	
	var c_health: C_Health = unit.get_component(C_Health)
	health_label.text = "Health: %s/%s" % [
		c_health.current,
		c_health.maximum,
	]
	
	# TODO: better display
	var c_loc: C_ShipPopulation = unit.get_component(C_ShipPopulation)
	if c_loc:
		population_label.show()
		population_label.text = "Passengers: %s/%s" % [
			c_loc.current,
			c_loc.maximum,
		]
	else:
		population_label.hide()
	
	var c_storage: C_CargoStorage = unit.get_component(
		C_CargoStorage
	)
	if !c_storage:
		printerr("C_CargoStorage is not present")
	
	# TODO: better UI with icons
	weight_label.text = "Weight: %s/%s" % [
		c_storage.weight,
		c_storage.max_weight,
	]
	space_label.text = "Space: %s/%s" % [
		c_storage.space,
		c_storage.max_space,
	]
	
	gold_label.text = "Gold: %s" % [
		c_storage.gold_count,
	]
	
	NodeUtils.remove_all_children(cargo_grid_container)
	
	if c_storage.storage.is_empty():
		print("ship storage is empty")
	
	# TODO: tool to sell/buy price
	for item: CargoResourceStorageDef in c_storage.storage.values():
		var instance: ShipStorageItemUI = SHIP_STORAGE_ITEM_UI.instantiate()
		cargo_grid_container.add_child(
			instance
		)
		instance.set_quantity(
			item.quantity,
		)
		# FIXME: should stop using this
		var res_icon = Resources.get_resource_icon(
			item.item_id,
		)
		var res_name = Resources.get_resource_name(
			item.item_id,
		)
		instance.set_icon(
			res_icon,
		)
		instance.set_tooltip(
			res_name,
		)
		
		
	# TODO : dest
	
	# TODO : leaving map
	

#region "Kill unit"

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

	#if event_bus != null:
		#event_bus.ask_demolish_current_building.emit()

#endregion
