extends Component
class_name C_PopulationSummary

@export
var populations: Array[int] = [0, 0, 0, 0]
@export
var housing_capacities: Array[int] = [0, 0, 0, 0]
@export
var workers: Array[int] = [0, 0, 0, 0]
@export
var worker_capacities: Array[int] = [0, 0, 0, 0]


func population_increase(population_type: int, amount: int):
	populations[population_type] += amount

func population_decrease(population_type: int, amount: int):
	populations[population_type] -= amount


func housing_capacity_increase(population_type: int, amount: int):
	housing_capacities[population_type] += amount

func housing_capacity_decrease(population_type: int, amount: int):
	housing_capacities[population_type] -= amount


func workers_increase(population_type: int, amount: int):
	workers[population_type] += amount

func workers_decrease(population_type: int, amount: int):
	workers[population_type] -= amount


func worker_capacities_increase(population_type: int, amount: int):
	worker_capacities[population_type] += amount

func worker_capacities_decrease(population_type: int, amount: int):
	worker_capacities[population_type] -= amount
