extends VBoxContainer
class_name UnitContainerUI3D

@onready var name_label = $HBoxContainer/NameLabel
@onready var flag_texture_rect: TextureRect = $HBoxContainer/FlagTextureRect

@onready var confirmation_dialog := %ConfirmationDialog

@onready var type_label: Label = $UnitInfoContainer/UnitDefaultContainer/TypeLabel
@onready var health_label: Label = $UnitInfoContainer/UnitDefaultContainer/HealthLabel
@onready var location_label: Label = $UnitInfoContainer/UnitDefaultContainer/LocationLabel
@onready var work_label: Label = $UnitInfoContainer/UnitDefaultContainer/WorkLabel
@onready var housing_label: Label = $UnitInfoContainer/UnitDefaultContainer/HousingLabel
@onready var eating_label: Label = $UnitInfoContainer/UnitDefaultContainer/EatingLabel
@onready var pay_label: Label = $UnitInfoContainer/UnitDefaultContainer/PayLabel
@onready var moving_label: Label = $UnitInfoContainer/UnitDefaultContainer/MovingLabel
@onready var dead_label: Label = $UnitInfoContainer/UnitDefaultContainer/DeadLabel
@onready var leaving_island_label: Label = $UnitInfoContainer/UnitDefaultContainer/LeavingIslandLabel
@onready var gold_label: Label = $UnitInfoContainer/UnitDefaultContainer/GoldLabel

@onready var event_bus: EventBus

# FIXME: could be an option eventually
const confirmation_text = "Are you sure you want to kill this unit?"

func _ready():
	event_bus = get_tree().current_scene.get_node_or_null("EventBus")

func update_infos(unit: Entity):
	var c_name: C_Name = unit.get_component(C_Name)
	# FIXME: if we remove c_name
	# Will need this
	#var c_person_name: C_PersonName = unit.get_component(C_PersonName)
	
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

	var c_pop_unit: C_PopUnit = unit.get_component(C_PopUnit)
	type_label.text = "Type: %s" % [
		Populations.get_population_name(
			c_pop_unit.pop_type
		)
	]
	
	var c_health: C_Health = unit.get_component(C_Health)
	health_label.text = "Health: %s/%s" % [
		c_health.current,
		c_health.maximum,
	]
	
	var c_loc: C_PopUnitLocation = unit.get_component(C_PopUnitLocation)
	location_label.text = "Location: %s" % [
		C_PopUnitLocation.location_to_string(c_loc.location),
	]
	
	var c_jobless: C_JobLess = unit.get_component(C_JobLess)
	if c_jobless:
		work_label.text = "no work"
	else:
		work_label.text = "has work"
	
	var c_looking_for_housing: C_LookingForHousing = unit.get_component(C_LookingForHousing)
	if c_looking_for_housing:
		housing_label.text = "no house"
	else:
		housing_label.text = "living in a house"
	
	var c_not_getting_paid: C_NotGettingPaid = unit.get_component(
		C_NotGettingPaid
	)
	if c_not_getting_paid:
		pay_label.show()
		var stopped_working = ""
		if c_not_getting_paid.stopped_working:
			stopped_working = " (stopped working)"
		pay_label.text = "Is not getting paid (for %s)%s" % [
			c_not_getting_paid.time,
			stopped_working,
		]
	else:
		pay_label.hide()
	
	var c_starving: C_IsStarving = unit.get_component(
		C_LookingForHousing
	)
	if c_starving:
		eating_label.show()
		eating_label.text = "Is starving (hasn't eaten for %s)" % [
			c_starving.starving_time,
		]
	else:
		eating_label.hide()
	
	var c_moving: C_PopMovingToTarget = unit.get_component(C_PopMovingToTarget)
	if c_moving:
		moving_label.show()
		match c_moving.move_target_type:
			C_PopMovingToTarget.MOVE_TARGET_TYPE.WORKPLACE:
				moving_label.text = "Moving to workplace"
			C_PopMovingToTarget.MOVE_TARGET_TYPE.HOUSING:
				moving_label.text = "Moving to housing"
			C_PopMovingToTarget.MOVE_TARGET_TYPE.DOCK:
				moving_label.text = "moving to dock"
			C_PopMovingToTarget.MOVE_TARGET_TYPE.IDLING:
				moving_label.text = "idling"
			_:
				printerr("c_moving.move_target_type %s not managed" % [
					c_moving.move_target_type,
				])
	else:
		moving_label.hide()
		
	var c_is_dead: C_IsDead = unit.get_component(
		C_IsDead
	)
	if c_is_dead:
		dead_label.show()
	
	var c_leaving: C_LookingToLeaveIsland = unit.get_component(C_LookingToLeaveIsland)
	if c_leaving:
		leaving_island_label.show()
	else:
		leaving_island_label.hide()
		
	# TODO: move it elsewhere
	var c_storage: C_Storage = unit.get_component(
		C_Storage
	)
	if c_storage:
		gold_label.text = "Gold: %s" % [
			c_storage.gold_count,
		]
	else:
		gold_label.text = "storage is not present"

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
