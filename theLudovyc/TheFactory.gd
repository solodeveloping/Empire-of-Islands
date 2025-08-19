extends Node
class_name TheFactory

@onready var game: Game2D = get_parent()
@onready var storage = $"../TheStorage"
@onready var the_population = $"../ThePopulation"
@onready var event_bus = $"../EventBus"

enum Production_Line {
	current_workers,
	input_resource_type,
	input_consumption_rate,
	production_rate,
	current_ticks
}

var production_lines_per_level = [{}, {}, {}]

var workers: Array[int] = [0, 0]:
	set(value):
		workers = value
		notify_workers_updated()

enum Waiting_Lines {
	resource_type,
	needed_workers
}
var waiting_lines := []

# FIXME : we have to add the resource there regardless of the state of the game
# Maybe the code can be fixed so that we don't have to initialize all of these
var resources_consumption = {
	Resources.Types.Wood: {},
	Resources.Types.Textile: {},
	Resources.Types.Plank: {},
	Resources.Types.Potato: {},
	Resources.Types.Pig: {},
	Resources.Types.Meat: {},
}

func _add_workers(population_type: Populations.Types, amount: int):
	workers[population_type] += amount
	notify_workers_updated()
	
func _remove_workers(population_type: Populations.Types, amount: int):
	workers[population_type] -= amount
	notify_workers_updated()
	
func notify_workers_updated():
	var arr = the_population.populations.duplicate()
	Helper.sub_each(arr, workers)
	event_bus.available_workers_updated.emit(arr)

func get_production_rate_per_tick(resource_type: Resources.Types) -> int:
	var level = Resources.get_resource_level(resource_type)
	var positive_prod = 0
	if production_lines_per_level[level].has(resource_type):
		positive_prod = production_lines_per_level[level][resource_type][Production_Line.production_rate]
	
	var negative_prod = 0
	for consumer_resource_type in resources_consumption[resource_type]:
		negative_prod += resources_consumption[resource_type][consumer_resource_type]
	
	return positive_prod - negative_prod


func create_or_update_line(resource_type: Resources.Types, workers_amount: int):
	var needed_workers = Recipes.get_recipe_needed_workers(resource_type)
	var level = Resources.get_resource_level(resource_type)

	if production_lines_per_level[level].has(resource_type):
		var line = production_lines_per_level[level][resource_type]
		
		line[Production_Line.current_workers] += workers_amount
		
		var production_rate = int(
			line[Production_Line.current_workers] / needed_workers
		)
		
		var input_count = Recipes.get_recipe_input_amount(resource_type)
		var input_consumption_rate = production_rate * input_count

		line[Production_Line.production_rate] = production_rate
		line[Production_Line.input_consumption_rate] = input_consumption_rate
		if line[Production_Line.input_resource_type] != -1:
			resources_consumption[line[Production_Line.input_resource_type]][resource_type] = input_consumption_rate
	else:
		var production_rate: int = 0
		var input_count = Recipes.get_recipe_input_amount(resource_type)
		var input_type = Recipes.get_recipe_input_type(resource_type)
		var input_consumption_rate = 0

		if workers_amount >= needed_workers:
			production_rate = workers_amount / needed_workers
			input_consumption_rate = production_rate * input_count

		# QUESTION : maybe be this should be an object {} ? idk
		production_lines_per_level[level][resource_type] = [
			workers_amount,
			input_type,
			input_consumption_rate,
			production_rate,
			0
		]
		if input_type != -1:
			resources_consumption[input_type][resource_type] = input_consumption_rate

	storage.update_global_production_rate(resource_type)
	if production_lines_per_level[level][resource_type][Production_Line.input_resource_type] != -1:
		storage.update_global_production_rate(production_lines_per_level[level][resource_type][Production_Line.input_resource_type])


func add_workers(
	building_pop_type: Populations.Types,
	resource_type: Resources.Types,
	workers_amount: int
):
	if workers_amount == 0:
		return
	elif workers_amount < 0:
		rem_workers(building_pop_type, resource_type, -workers_amount)
		return
		
	if resource_type == -1:
		_add_workers(building_pop_type, workers_amount)
		return

	var population_type = Recipes.get_recipe_population_type(resource_type)
	_add_workers(population_type, workers_amount)

	if (the_population.populations[population_type] - workers[population_type]) < 0:
		waiting_lines.push_back([resource_type, workers_amount])
	else:
		create_or_update_line(resource_type, workers_amount)


func rem_workers(
	building_pop_type: Populations.Types,
	resource_type: Resources.Types,
	workers_amount: int
):
	if workers_amount == 0:
		return
	elif workers_amount < 0:
		add_workers(building_pop_type, resource_type, -workers_amount)
		return

	if resource_type == -1:
		_remove_workers(building_pop_type, workers_amount)
		return

	var population_type = Recipes.get_recipe_population_type(resource_type)
	_remove_workers(population_type, workers_amount)

	if not waiting_lines.is_empty():
		var i := waiting_lines.rfind([resource_type, workers_amount])

		if i != -1:
			waiting_lines.remove_at(i)
			return

	var level = Resources.get_resource_level(resource_type)

	if production_lines_per_level[population_type].has(resource_type):
		var line = production_lines_per_level[level][resource_type]

		line[Production_Line.current_workers] -= workers_amount

		if line[Production_Line.current_workers] == 0:
			production_lines_per_level[level].erase(resource_type)
			resources_consumption[line[Production_Line.input_resource_type]].erase(resource_type)
			return

		var production_rate = int(
			line[Production_Line.current_workers] / Recipes.get_recipe_needed_workers(resource_type)
		)
		var input_count = Recipes.get_recipe_input_amount(resource_type)
		
		line[Production_Line.production_rate] = production_rate
		line[Production_Line.input_consumption_rate] = input_count * production_rate
		resources_consumption[line[Production_Line.input_resource_type]][resource_type] = line[Production_Line.input_consumption_rate]

		storage.update_global_production_rate(resource_type)
		if line[Production_Line.input_resource_type] != -1:
			storage.update_global_production_rate(line[Production_Line.input_resource_type])


func population_increase(population_type: Populations.Types, amount: int):
	var population_pool = amount

	var i := 0

	while i < waiting_lines.size():
		if waiting_lines[i][Waiting_Lines.needed_workers] <= population_pool:
			# FIXME? : we could put population_type inside the lines
			# To save some lines / processing power (tradeoff is more RAM used)
			var resource_type = waiting_lines[i][Waiting_Lines.resource_type]
			var line_pop_type = Recipes.get_recipe_population_type(resource_type)
			
			if line_pop_type != population_type:
				continue
			
			var waiting_line = waiting_lines.pop_at(i)

			var waiting_line_needed_workers = waiting_line[Waiting_Lines.needed_workers]

			create_or_update_line(
				waiting_line[Waiting_Lines.resource_type], waiting_line_needed_workers
			)

			population_pool -= waiting_line_needed_workers

			if population_pool <= 0:
				break
		else:
			i += 1


func population_decrease(population_type: Populations.Types, amount: int):
	var population_pool = amount
	
	# Info : we need another array to hold the key to erase
	# It's not safe to erase items of an array when iterating with a 'for' loop
	var removed_lines: Array[int] = []
	
	for resource_type in production_lines_per_level[population_type]:
		# FIXME ? : we could put population_type inside the lines
		# To save some lines / processing power (tradeoff is more RAM used)
		var line_pop_type = Recipes.get_recipe_population_type(resource_type)
		
		if line_pop_type != population_type:
			continue
			
		var line = production_lines_per_level[population_type][resource_type]

		var current_workers = line[Production_Line.current_workers]

		if current_workers >= amount:
			line[Production_Line.current_workers] -= amount

			waiting_lines.push_back([resource_type, amount])

			population_pool -= amount
		else:
			line[Production_Line.current_workers] = 0

			waiting_lines.push_back([resource_type, current_workers])

			population_pool -= current_workers

		if line[Production_Line.current_workers] == 0:
			removed_lines.append(resource_type)
			if line[Production_Line.input_resource_type] != -1:
				resources_consumption[line[Production_Line.input_resource_type]].erase(resource_type)
		else:
			var production_rate = int(
				line[Production_Line.current_workers] / Recipes.get_recipe_needed_workers(resource_type)
			)
			
			line[Production_Line.production_rate] = production_rate
			
			var input_count = Recipes.get_recipe_input_amount(resource_type)
			line[Production_Line.input_consumption_rate] = input_count * production_rate
			resources_consumption[line[Production_Line.input_resource_type]][resource_type] = line[Production_Line.input_consumption_rate]
			
		if line[Production_Line.input_resource_type] != -1:
			storage.update_global_production_rate(line[Production_Line.input_resource_type])

		storage.update_global_production_rate(resource_type)

		if population_pool <= 0:
			break

	for resource_type in removed_lines:
		production_lines_per_level[population_type].erase(resource_type)

func _on_TheTicker_tick():
	for i in range(production_lines_per_level.size()):
		for resource_type in production_lines_per_level[i]:
			var line = production_lines_per_level[i][resource_type]

			line[Production_Line.current_ticks] += 1

			if line[Production_Line.current_ticks] >= Recipes.get_recipe_needed_ticks(resource_type):
				# Info : could optimize computation costs by storing input_type inside the Line
				var input_type = line[Production_Line.input_resource_type]
				var input_amount = line[Production_Line.input_consumption_rate]
				
				if input_type == -1 or input_amount == 0:
					line[Production_Line.current_ticks] = 0
					storage.add_resource(resource_type, line[Production_Line.production_rate])
				else:
					var storage_input_amount = storage.get_resource_amount(input_type)
					if storage_input_amount >= input_amount:
						line[Production_Line.current_ticks] = 0
						storage.add_resource(input_type, -input_amount)
						storage.add_resource(resource_type, line[Production_Line.production_rate])

func get_factory_save() -> Dictionary:
	return {"Factory":[workers, production_lines_per_level, waiting_lines]}
	
func load_factory_save() -> Error:
	if SaveHelper.last_loaded_data.is_empty():
		return FAILED
		
	var factory_data:Array = SaveHelper.last_loaded_data.get("Factory", [])
	
	if factory_data.is_empty():
		return FAILED
		
	workers = factory_data[0]
	production_lines_per_level = factory_data[1]
	waiting_lines = factory_data[2]
	
	for level in range(production_lines_per_level.size()):
		for resource_type in production_lines_per_level[level]:
			var line = production_lines_per_level[level][resource_type]
			storage.update_global_production_rate(resource_type)
			if line[Production_Line.input_resource_type] != -1:
				resources_consumption[line[Production_Line.input_resource_type]][resource_type] = line[Production_Line.input_consumption_rate]
				storage.update_global_production_rate(line[Production_Line.input_resource_type])
	
	# QUESTION : this should be an object since we take it from json no ?
	#for line:String in factory_data[1]:
		#var resource_type:int = line.to_int()
		#
		#if not Resources.Types.values().has(resource_type):
			#push_error("Cannot create a production line from an unknow resource type: " + line)
			#
			#continue
		#
		#production_lines[resource_type] = factory_data[1][line]
		#
		#storage.update_global_production_rate(resource_type)
		
	return OK
