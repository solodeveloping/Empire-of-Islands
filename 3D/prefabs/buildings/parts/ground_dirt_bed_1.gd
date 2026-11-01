extends Node3D
class_name GroundDirtBed_1

@onready var plant_locations: Node3D = $PlantLocations

var current_resource_id: int = 0

func update_current_resource_id(resource_id: int):
	current_resource_id = resource_id

func update_visuals(
	packed_scene: PackedScene
):
	for child in plant_locations.get_children():
		NodeUtils.remove_all_children(child)
		var instance = packed_scene.instantiate()
		child.add_child(
			instance
		)
