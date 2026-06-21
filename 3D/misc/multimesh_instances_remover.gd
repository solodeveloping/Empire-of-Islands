extends Node
class_name MultiMeshInstancesRemover

var mm_instance_areas: Array[MultiMeshInstanceArea] = []

# TODO : for now we do it like this
# Might want different implems
# Like tree growing back
# positions changings
# idk

# TODO : could emit event when building is being made
# and put this into another class?
func _on_multimesh_instance_area_entered_main_area(
	area: MultiMeshInstanceArea
):
	#print("MultiMeshInstancesRemover:_on_multimesh_instance_area_entered_main_area %s" % [
		#area.name,
	#])
	mm_instance_areas.push_back(area)
	var grid: GridMultiMesh = SceneUtils.find_first_parent_of_type(
		area,
		GridMultiMesh
	)
	
	if grid:
		grid.hide_instance(area)
	else:
		push_error("could not find parent when area entered")

func _on_multimesh_instance_area_exited_main_area(
	area: MultiMeshInstanceArea
):
	#print("MultiMeshInstancesRemover:_on_multimesh_instance_area_exited_main_area %s" % [
		#area.name,
	#])
	if area in mm_instance_areas:
		mm_instance_areas.erase(area)
		var grid: GridMultiMesh = SceneUtils.find_first_parent_of_type(
			area,
			GridMultiMesh
		)
		
		if grid:
			grid.show_instance(area)
		else:
			printerr("could not find parent when area exited")
	else:
		push_error("area is not in mm_instance_areas")

func _hide_area(
	area: MultiMeshInstanceArea
):
	#print("MultiMeshInstancesRemover:_hide_area %s" % [
		#area.name,
	#])
	if area in mm_instance_areas:
		return
	mm_instance_areas.push_back(area)
	var grid: GridMultiMesh = SceneUtils.find_first_parent_of_type(
		area,
		GridMultiMesh
	)
	
	if grid:
		grid.hide_instance(area)
	else:
		push_error("could not find parent when area entered")

func _show_area(
	area: MultiMeshInstanceArea
):
	#print("MultiMeshInstancesRemover:_show_area %s" % [
		#area.name,
	#])
	if area in mm_instance_areas:
		mm_instance_areas.erase(area)
		var grid: GridMultiMesh = SceneUtils.find_first_parent_of_type(
			area,
			GridMultiMesh
		)
		
		if grid:
			grid.show_instance(area)
		else:
			printerr("could not find parent when area exited")
	else:
		push_error("area is not in mm_instance_areas")

func show_all_instances():
	for area in mm_instance_areas:
		var grid: GridMultiMesh = SceneUtils.find_first_parent_of_type(
			area,
			GridMultiMesh
		)
		
		if grid:
			grid.show_instance(area)
			
		area.process_mode = Node.PROCESS_MODE_INHERIT

	mm_instance_areas = []

func get_instances() -> Array[MultiMeshInstanceArea]:
	return mm_instance_areas

func disable_instance_areas():
	for area in mm_instance_areas:
		#print("disabling %s" % [
			#area.name,
		#])
		area.process_mode = Node.PROCESS_MODE_DISABLED
