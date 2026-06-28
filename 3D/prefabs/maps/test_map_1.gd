extends Node3D

@onready var island_1: IslandGECS1 = $Island1
@onready var buildings: Node3D = $Buildings

# FIXME: duplicated
var production_building_ids: Array[int] = [
	Buildings.Ids.Fishery,
	Buildings.Ids.Lumberjack,
	Buildings.Ids.HunterTent,
]
var housing_building_ids: Array[int] = [
	Buildings.Ids.Tent,
	Buildings.Ids.House,
	Buildings.Ids.StoneHouse,
]

func _ready() -> void:
	Loggie.msg("TestMap1:_ready").info()

func add_buildings_to_ecs(city: Entity):
	# TODO: maybe we should have a better system
	var building_list = SceneUtils.find_all_child_of_type_depth_first(
		self,
		Entity,
	)
	for building in building_list:
		
		if building is Entity:
			ECS.world.add_entity(building)
			
			var c_building: C_Building = building.get_component(C_Building)
			
			if c_building:
				if building.has_method("finalize_construction"):
					building.finalize_construction()
				else:
					printerr("building %s does not have finalize_construction" % [
						building.name
					])
					push_error("building %s does not have finalize_construction" % [
						building.name
					])
				
				building.add_relationship(Rels.create_belongs_to(city))
			
			#var c_building: C_Building = building.get_component(C_Building)
			#if c_building:
				if c_building.building_type in production_building_ids:
					ECS.world.emit_event(
						ECSEvents.PRODUCTION_BUILDING_ADDED, 
						building,
						{
							"island": island_1,
						}
					)
				elif c_building.building_type in housing_building_ids:
					ECS.world.emit_event(
						ECSEvents.HOUSING_BUILDING_ADDED, 
						building,
						{
							"island": island_1,
						}
					)
				else:
					pass
			#else:
				#push_error("building %s does not have C_Building" % [
					#building.name,
				#])

		if building is Dock_ECS:
			print("adding buoy of dock")
			building.buoy.add_relationship(
				# FIXME: part_of component?
				Rels.create_belongs_to(building)
			)
			# FIXME: id is 0, how do we handle more ids
			building.id
			var c_dock_buoy: C_DockBuoy = C_DockBuoy.new(0)
			building.buoy.add_component(c_dock_buoy)
			# WARN: it's already added by the statement before
			#ECS.world.add_entity(building.buoy)
		
		if building is IslandGECS1:
			building.add_to_ecs_world()
	
	if buildings.get_child_count() <= 1:
		push_error("child count is 1 or 0")
	for child in buildings.get_children():
		if child is Entity:
			print("emitting assing building for %s %s" % [
				child.name,
				child.get_path(),
			])
			ECS.world.emit_event(
				ECSEvents.ASSIGN_BUILDING_TO_ISLAND_REQUESTED, 
				child,
				{
					"island": island_1,
				}
			)
