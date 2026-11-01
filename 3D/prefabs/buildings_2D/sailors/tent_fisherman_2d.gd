@tool
extends Entity
class_name TentFisherman2D_ECS

# TODO: we are duplicating all of those
func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.Fishery),
		C_Name.new("Fisherman tent"),
		C_Transform2D.new(),
		C_Health.new(100),
		C_Production.new(
			Resources.Types.Fish,
			3,
			3.0
		),
		C_CollectionBuilding.new(),
		C_WorkerRequirement.new(
			[
				Worker_Requirement.new(
					Populations.Types.Sailor,
					2,
					1
				)
			]
		),
		C_Workers.new({
			Populations.Types.Sailor: WorkerQuantity.new(Populations.Types.Sailor, 0)
		}),
		C_CircularVision.new(250),
	]


func on_ready():
	ECSBuilding2DUtils.setup_trans_and_vision(
		self
	)

var visual_node: Node
func set_visual_node(node: Node):
	visual_node = node

func get_visual_node() -> Node:
	return visual_node

func show_production_stoppped_indicator():
	visual_node.show_production_stoppped_indicator()

func hide_production_stoppped_indicator():
	visual_node.hide_production_stoppped_indicator()
