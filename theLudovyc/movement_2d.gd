extends Node2D

@onready var event_bus: EventBus = %EventBus

## For now it's [Ship2D_ECS]
var selected_ship: Entity

func _ready() -> void:
	event_bus.send_natural_resource_selected.connect(
		_on_event_bus_send_natural_resource_selected
	)
	event_bus.send_building_selected.connect(
		_on_event_bus_send_building_selected
	)
	event_bus.send_ecs_ship_selected.connect(
		_on_event_bus_send_ecs_ship_selected
	)
	event_bus.send_ecs_ship_deselected.connect(
		_on_event_bus_send_ecs_ship_deselected
	)

func _process(_delta: float) -> void:
	if !selected_ship:
		return
	if Input.is_action_just_pressed("right_click"):
		#print("pressed")
		var position_ = get_global_mouse_position()
		#selected_ship.set_movement_target(position_)
		
		var c_health: C_Health = selected_ship.get_component(
			C_Health
		)
		if c_health.current <= 0:
			return
		
		# TODO: implement this for 2D
		# TODO: only possible with Raycast?
		#var collider: Node3D = raycast_result["collider"]
		#var _collider_as_entity = collider as Variant as Entity
		#if _collider_as_entity:
			#print("something is entity")
			#if _collider_as_entity.has_component(
				#C_IsLoot
			#):
				#print("clicked on loot")
				#ECS.world.emit_event(
					#ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED,
					#selected_ship,
					#{
						#"component": C_LookingForLoot.new(),
					#}
				#)
			#elif _collider_as_entity.has_component(C_PopUnit):
				#print("clicked on pop unit")
		#elif collider.get_parent() is Entity:
			#print("something is entity")
			#var entity: Entity = collider.get_parent()
			#if entity.has_component(
				#C_IsLoot
			#):
				#print("clicked on loot (2)")
				#ECS.world.emit_event(
					#ECSEvents.ADD_COMPONENT_TO_ENTITY_REQUESTED,
					#selected_ship,
					#{
						#"component": C_LookingForLoot.new(),
					#}
				#)
			#elif entity.has_component(C_PopUnit):
				#print("clicked on pop unit")
		#else:
			#print("not an entity")
			#pass
		
		# TODO : verify faction here
		var array: Array = []
		var dest: C_NavigationDestination2D = selected_ship.get_component(
			C_NavigationDestination2D
		)
		if dest:
			dest.target = position_
		else:
			var target: C_NavigationDestination2D = C_NavigationDestination2D.new(
				position_
			)
			array.push_back(target)
		
		ECS.world.emit_event(
			ECSEvents.ADD_COMPONENTS_TO_ENTITY_REQUESTED,
			selected_ship,
			{
				"components": array,
			}
		)
	# Not the right place?
	#if Input.is_action_just_pressed("left_click"):
		#_deselect_ship()

func _deselect_ship():
	# This is recursive somewhat
	event_bus.send_ecs_ship_deselected.emit(selected_ship)
	selected_ship = null

# FIXME: not a fan of having to bind multiple things
# Should have one even ideally
func _on_event_bus_send_building_selected(
	_building
):
	# Info: If something else is select, we set this to null
	selected_ship = null

func _on_event_bus_send_natural_resource_selected(
	_natural_resource
):
	selected_ship = null

func _on_event_bus_send_ecs_ship_selected(
	entity: Entity
):
	selected_ship = entity

func _on_event_bus_send_ecs_ship_deselected(
	_entity: Entity
):
	selected_ship = null
