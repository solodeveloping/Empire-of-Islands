extends Node
class_name ThePopulation

@onready var game: Game2D = get_parent()
@onready var event_bus = $"../EventBus"
@onready var the_factory = $"../TheFactory"

var populations: Array[int] = [0, 0]:
	set(value):
		populations = value
		notify_population_updated()

func population_increase(population_type: Populations.Types, amount: int):
	populations[population_type] += amount
	notify_population_updated()
	
func population_decrease(population_type: Populations.Types, amount: int):
	populations[population_type] -= amount
	notify_population_updated()
	
func notify_population_updated():
	event_bus.population_updated.emit(populations)
	var arr = populations.duplicate()
	Helper.sub_each(arr, the_factory.workers)
	event_bus.available_workers_updated.emit(
		arr
	)

func get_population_save() -> Dictionary:
	return {"Population":[populations]}
	
func load_population_save() -> Error:
	if SaveHelper.last_loaded_data.is_empty():
		return FAILED
		
	var factory_data:Array = SaveHelper.last_loaded_data.get("Population", [])
	
	if factory_data.is_empty():
		return FAILED
		
	populations = factory_data[0]
		
	return OK
