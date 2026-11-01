extends Node
class_name ECSEvents

# FIXME: string could be shorter and random?
# Maybe could even be an int

# Used by [O_BuildingAddedObserver]
# Emitted by [Game3D], [Game2D]
static var PRODUCTION_BUILDING_ADDED: StringName = &"production_building_added"
# Used by [O_BuildingAddedObserver]
# Emitted by [Game3D], [Game2D]
static var HOUSING_BUILDING_ADDED: StringName = &"housing_building_added"
# Used by [O_BuildingAddedObserver]
# Emitted by [Game3D], [Game2D]
static var GENERIC_BUILDING_ADDED: StringName = &"generic_building_added"
#static var BUILDING_REMOVED: StringName = &"building_removed"
## Used by [O_BuildingRemovedObserver]
static var BUILDING_IS_BEING_REMOVED: StringName = &"building_is_being_removed"
## Used by [O_MiscObserver]
static var ADD_COMPONENT_TO_ENTITY_REQUESTED: StringName = &"add_component_to_entity_requested"
## Used by [O_MiscObserver]
static var ADD_COMPONENTS_TO_ENTITY_REQUESTED: StringName = &"add_components_to_entity_requested"
# Used by [O_BuildingAddedObserver]
# Emitted by [TestMap3D]
static var ASSIGN_BUILDING_TO_ISLAND_REQUESTED: StringName = &"assign_building_to_island_requested"

static var ASSIGN_FACTION_TO_ENTITIES_REQUESTED: StringName = &"assign_faction_to_entities_requested"

## Used by [O_PopulationObserver]
## Emitted by [Game2D]
## Trigger the appriopriate signal
static var SPAWN_POP_UNITS_REQIESTED: StringName = &"spawn_pop_units_requested"
## Used by [O_BuildingRemovedObserver]
## Emitted by [O_ShipMiscObserver]
## Trigger the appriopriate signal
static var POP_UNIT_JOINED: StringName = &"pop_unit_joined"
# FIXME: unused?
## Emitted by [O_BuildingRemovedObserver]
static var POP_UNIT_LEFT_HOUSING: StringName = &"pop_unit_left_housing"
# FIXME: unused
## Unused
static var POP_UNIT_LEFT_PRODUCTION_BUILDING: StringName = &"pop_unit_left_production_building"
## Used by [O_PopulationMovementObserver]
## Emitted by [NavigationSystem]
static var POP_UNIT_REACHED_MOVE_TARGET = &"pop_unit_reached_move_target"
## Used by [O_PopulationObserver]
## Will trigger the appropriate signal
static var POP_UNIT_LEAVE_WORKPLACE_REQUESTED = &"pop_unit_leave_workplace_requested"
## Used by [O_PopulationObserver]
## Emitted by [O_ShipMiscObserver]
static var POP_UNIT_LEAVE_HOUSING_REQUESTED = &"pop_unit_leave_housing_requested"
## Used by [O_PopulationObserver]
static var PRODUCTION_BUILDING_REASSIGN_POP_UNITS_REQUESTED = &"production_building_reassign_pop_units_requested"
## Used by [O_PopulationObserver]
static var HOUSING_BUILDING_REASSIGN_POP_UNITS_REQUESTED = &"housing_building_reassign_pop_units_requested"

## Used by [O_ShipMiscObserver]
## Emitted by [NavigationSystem]
static var SHIP_UNLOAD_REQUESTED: StringName = &"ship_unload_requested"
static var SHIP_UNLOAD_AT_SEA_REQUESTED: StringName = &"ship_unload_at_sea_requested"
## Used by [O_ShipTradingObserver]
## Emitted by [O_ShipMiscObserver]
static var SHIP_TRADING_REQUESTED: StringName = &"ship_trading_requested"

## Used by [O_SpawnObserver]
## Emitted by [Game3D]
static var SPAWN_ENTITIES_REQUESTED: StringName = &"spawn_entities_requested"

static func emit_event(event: String, data: Variant):
	var entity: Entity = Entity.new()
	entity.add_component(
		C_ForECSEvents.new(),
	)
	ECS.world.add_entity(entity)
	ECS.world.emit_event(
		event,
		entity,
		data,
	)
	ECS.world.remove_entity(entity)
