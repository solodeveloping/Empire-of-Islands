extends HBoxContainer

@onready var resident_label = $ValueLabel

# Info : this is the script to display residential buildings information
# the ones on the map, when clicked on
# it does not display production buildings information

# This is for the ECS version of the code

func update_infos(
	_building_id: Buildings.Ids,
	building: Entity,
):
	var c_housing: C_HousingCapacity = building.get_component(C_HousingCapacity)
	if c_housing:
		resident_label.text = "%s / %s" % [
			c_housing.current,
			c_housing.maximum,
		]
