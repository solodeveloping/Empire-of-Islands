class_name C_NeededResources
extends Component

# Info: this is the resources needed for the current production

@export var needs: Array[Resource_Requirement] = []

func _init(
	needs_: Array[Resource_Requirement],
):
	needs = needs_
