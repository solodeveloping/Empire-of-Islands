## Analyse the evolution of the resources by sampling at regular intervals
extends Node
class_name GM_StorageEvolutionSampler

# TODO: manage constructions
# TODO: be more reactive maybe
# like for gold production
# it diminishes, but it's not replicated in the rate
# maybe

@export
var interval_s: float = 5.0

@export
var projection_factor: int = 6

@export
var storage: GM_I_StorageNode

#var faction_entities: Array[Entity] = []
var local_player_c_faction: C_Faction

var last_storage: Dictionary[int, GMStorageRef] = {}
var last_gold_count: int = 0

var event_bus: EventBus

func _ready() -> void:
	var timer: Timer = Timer.new()
	timer.wait_time = interval_s
	timer.timeout.connect(_on_timer_timeout)
	timer.autostart = true
	add_child(timer)
	
	var current_scene = get_tree().current_scene
	# TODO: make a const
	if current_scene.has_node("%EventBus"):
		event_bus = current_scene.get_node("%EventBus")

func initialize(
	gold_count: int = 0
):
	last_gold_count = gold_count
	last_storage = {}
	
	var current_storage: Array[GMStorageRef] = storage.get_storage_as_list()
	for storage_ref in current_storage:
		last_storage.set(
			storage_ref.item_id,
			GMStorageRef.new(
				storage_ref.item_id,
				storage_ref.quantity,
				storage_ref.max_quantity
			)
		)

func _on_timer_timeout():
	#print("GM_StorageEvolutionSampler:_on_timer_timeout")
	var current_storage: Array[GMStorageRef] = storage.get_storage_as_list()
	
	if current_storage.is_empty():
		push_error("current_storage.is_empty()")
	
	# TODO: would be more performant to send an array
	#var changes: Array[int, GM_ResourceEvolutionData] = []
	#for change in changes:
		#event_bus.send_resource_prodution_rate_updated.emit(
			#resource_type, amount
		#)
	
	var new_last_storage: Dictionary[int, GMStorageRef] = {}
	
	for storage_ref in current_storage:
		var last: GMStorageRef = last_storage.get(storage_ref.item_id)
		if last == null:
			#print("emit send_resource_prodution_rate_updated")
			event_bus.send_resource_prodution_rate_updated.emit(
				storage_ref.item_id, storage_ref.quantity * projection_factor
			)
		else:
			var change: int = (storage_ref.quantity - last.quantity) * projection_factor
			#print("emit send_resource_prodution_rate_updated")
			event_bus.send_resource_prodution_rate_updated.emit(
				storage_ref.item_id, change
			)
			# Gold is different for now
			#if storage_ref.item_id == Resources.Types.Gold:
				#print("gold %s" % [
					#storage_ref.quantity
				#])
		
		new_last_storage.set(
			storage_ref.item_id,
			GMStorageRef.new(
				storage_ref.item_id,
				storage_ref.quantity,
				storage_ref.max_quantity
			)
		)
	
	var gold_change = (local_player_c_faction.gold_count - last_gold_count) * projection_factor
	last_gold_count = local_player_c_faction.gold_count
	
	event_bus.money_production_rate_updated.emit(gold_change)
	
	last_storage = new_last_storage
