extends VBoxContainer

@onready var resource_in = $GridContainer/ResourceIn

@onready var resource_out = $GridContainer/ResourceOut

@onready var ticks_label = $HBoxContainer/TicksContainer/ValueLabel

@onready var workers_label = $HBoxContainer/WorkerContainer/ValueLabel

# Info : this is the script to display the infos of a production building
# the ones on the map, when clicked on
# it does not display residential buildings information

# This is for the ECS version of the code

func update_infos(
	building_id: Buildings.Ids,
	building: Entity,
):
	var resource_type = Buildings.get_produce_resource(building_id)

	#resource_in.resource_type = Recipes.get_recipe_input_type(resource_type)

	var c_production: C_Production = building.get_component(C_Production)
	resource_out.resource_type = c_production.production_type
	#resource_out.resource_type = resource_type
	
	# TODO : show the right resources

	# TODO : correct display for this
	#ticks_label.text = str(Recipes.get_recipe_needed_ticks(resource_type))
	ticks_label.text = str(c_production.production_time)
	
	# FIXME: can have multiple type of workers
	# and there is capacity vs current count
	var c_workers: C_Workers = building.get_component(C_Workers)
	if c_workers:
		var c_worker_reqs: C_WorkerRequirement = building.get_component(
			C_WorkerRequirement
		)
		if c_worker_reqs:
			var req = c_worker_reqs.requirements.get(c_workers.workers[0].worker_type)
			workers_label.text = "%s / %s" % [
				c_workers.workers[0].worker_count,
				req.worker_count,
			]
		else:
			workers_label.text = "%s" % [
				c_workers.workers[0].worker_count,
			]
	#workers_label.text = str(Buildings.get_max_workers(building_id))
