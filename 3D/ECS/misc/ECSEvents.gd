extends Node
class_name ECSEvents

# FIXME: string could be shorter and random?
# Maybe could even be an int

static var PRODUCTION_BUILDING_ADDED: StringName = &"production_building_added"
static var HOUSING_BUILDING_ADDED: StringName = &"housing_building_added"
static var GENERIC_BUILDING_ADDED: StringName = &"generic_building_added"
#static var BUILDING_REMOVED: StringName = &"building_removed"
static var BUILDING_IS_BEING_REMOVED: StringName = &"building_is_being_removed"
static var ADD_COMPONENT_TO_ENTITY_REQUESTED: StringName = &"add_component_to_entity_requested"
static var ASSIGN_BUILDING_TO_ISLAND_REQUESTED: StringName = &"assign_building_to_island_requested"


static var POP_UNIT_JOINED: StringName = &"pop_unit_joined"
static var POP_UNIT_LEFT_HOUSING: StringName = &"pop_unit_left_housing"
static var POP_UNIT_LEFT_PRODUCTION_BUILDING: StringName = &"pop_unit_left_production_building"
static var POP_UNIT_REACHED_MOVE_TARGET = &"pop_unit_reached_move_target"
static var POP_UNIT_LEAVE_WORKPLACE_REQUESTED = &"pop_unit_leave_workplace_requested"
static var POP_UNIT_LEAVE_HOUSING_REQUESTED = &"pop_unit_leave_housing_requested"
## Used by [O_PopulationObserver]
static var PRODUCTION_BUILDING_REASSIGN_POP_UNITS_REQUESTED = &"production_building_reassign_pop_units_requested"
## Used by [O_PopulationObserver]
static var HOUSING_BUILDING_REASSIGN_POP_UNITS_REQUESTED = &"housing_building_reassign_pop_units_requested"

static var SHIP_UNLOAD_REQUESTED: StringName = &"ship_unload_requested"
